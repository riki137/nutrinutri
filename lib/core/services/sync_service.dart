import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/services/drive_snapshot.dart';
import 'package:nutrinutri/core/services/google_drive_appdata.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';

class SyncService {
  SyncService({required AppDatabase db}) : _db = db;

  static const _snapshotFileName = 'nutrinutri.json';

  final AppDatabase _db;
  final _drive = const GoogleDriveAppData();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: _clientId,
      clientSecret: _clientSecret,
      scopes: const [
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
        drive.DriveApi.driveAppdataScope,
      ],
    ),
  );

  static const String _clientId =
      '650205047998-i0plaeno2mrp8e1kf6l52cth4076548p.apps.googleusercontent.com';

  // This is not actually a secret, Google just calls it that.
  // The app must have this to use Google Sign In, so there's no way to hide it.
  static const String _clientSecret = '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';

  GoogleSignInCredentials? _currentCredentials;
  GoogleSignInCredentials? get currentCredentials => _currentCredentials;

  GoogleUserInfo? _currentUserInfo;
  GoogleUserInfo? get currentUser => _currentUserInfo;

  final _userInfoController = StreamController<GoogleUserInfo?>.broadcast();
  Stream<GoogleUserInfo?> get onCurrentUserChanged =>
      _userInfoController.stream;

  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompleteController.stream;

  bool _isListeningToAuthState = false;

  void _setCredentials(GoogleSignInCredentials? credentials) {
    _currentCredentials = credentials;
    if (credentials == null) {
      _currentUserInfo = null;
      _userInfoController.add(null);
      return;
    }

    final userInfo = GoogleUserInfo.fromIdToken(credentials.idToken);
    _currentUserInfo = userInfo;
    _userInfoController.add(userInfo);
  }

  void _listenToAuthState() {
    if (_isListeningToAuthState) return;
    _isListeningToAuthState = true;

    _userInfoController.add(_currentUserInfo);

    _googleSignIn.authenticationState.listen(_setCredentials);
  }

  Future<void> signIn() async {
    _listenToAuthState();
    final credentials = await _googleSignIn.signIn();
    _setCredentials(credentials);
  }

  Future<void> restoreSession() async {
    try {
      _listenToAuthState();
      final credentials = await _googleSignIn.silentSignIn();
      _setCredentials(credentials);
    } catch (e) {
      debugPrint('Restore session failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _setCredentials(null);
  }

  Future<void> syncIfNeeded() async {
    if (currentUser == null) return;
    await sync();
  }

  Widget? get webSignInButton {
    if (kIsWeb) {
      return _googleSignIn.signInButton();
    }
    return null;
  }

  Future<int> sync() async {
    if (_currentCredentials == null) return 0;

    final client = await _googleSignIn.authenticatedClient;
    if (client == null) return 0;

    final driveApi = drive.DriveApi(client);
    final fileId = await _drive.findFileId(driveApi, name: _snapshotFileName);

    final remoteRaw = fileId == null
        ? ''
        : await _drive.downloadText(driveApi, fileId: fileId);
    final remote = DriveSnapshot.decode(remoteRaw);

    final localDiaryRows = await _db.select(_db.diaryEntries).get();
    final localDiary = <String, DiaryEntryRow>{
      for (final row in localDiaryRows) row.id: row,
    };

    final localProfile = await (_db.select(
      _db.userProfiles,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final localSettings = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    final nextDiary = Map<String, DiaryEntryRow>.from(remote.diaryEntries);
    UserProfileRow? nextProfile = remote.userProfile;
    AppSettingsRow? nextSettings = remote.appSettings;

    var remoteNeedsUpdate = false;
    var localUpdates = 0;

    await _db.transaction(() async {
      final allIds = {...localDiary.keys, ...remote.diaryEntries.keys};

      for (final id in allIds) {
        final local = localDiary[id];
        final remoteEntry = remote.diaryEntries[id];

        if (remoteEntry == null && local != null) {
          nextDiary[id] = local;
          remoteNeedsUpdate = true;
          continue;
        }

        if (local == null && remoteEntry != null) {
          await _applyRemoteDiaryEntry(remoteEntry);
          localUpdates++;
          continue;
        }

        if (local == null || remoteEntry == null) continue;

        final cmp = _compareRevision(
          local.updatedAt,
          local.updatedBy,
          remoteEntry.updatedAt,
          remoteEntry.updatedBy,
        );
        if (cmp > 0) {
          nextDiary[id] = local;
          remoteNeedsUpdate = true;
        } else if (cmp < 0) {
          await _applyRemoteDiaryEntry(remoteEntry);
          localUpdates++;
        }
      }

      final profileResult = await _mergeSingleton(
        local: localProfile,
        remote: remote.userProfile,
        revisionOf: (p) =>
            _Revision(updatedAt: p.updatedAt, updatedBy: p.updatedBy),
        applyRemote: (remote) => _applyRemoteUserProfile(remote),
      );
      localUpdates += profileResult.localUpdates;
      remoteNeedsUpdate = remoteNeedsUpdate || profileResult.remoteNeedsUpdate;
      nextProfile = profileResult.nextRemote;

      final settingsResult = await _mergeSingleton(
        local: localSettings,
        remote: remote.appSettings,
        revisionOf: (s) =>
            _Revision(updatedAt: s.updatedAt, updatedBy: s.updatedBy),
        applyRemote: (remote) => _applyRemoteAppSettings(remote),
      );
      localUpdates += settingsResult.localUpdates;
      remoteNeedsUpdate = remoteNeedsUpdate || settingsResult.remoteNeedsUpdate;
      nextSettings = settingsResult.nextRemote;
    });

    if (fileId == null &&
        (localDiary.isNotEmpty ||
            localProfile != null ||
            localSettings != null)) {
      remoteNeedsUpdate = true;
    }

    if (remoteNeedsUpdate) {
      final nextSnapshot = DriveSnapshot(
        diaryEntries: nextDiary,
        userProfile: nextProfile,
        appSettings: nextSettings,
      );
      await _drive.uploadText(
        driveApi,
        name: _snapshotFileName,
        content: nextSnapshot.encode(),
        fileId: fileId,
      );
    }

    if (localUpdates > 0) {
      _syncCompleteController.add(null);
    }

    return localUpdates;
  }

  Future<void> _applyRemoteDiaryEntry(DiaryEntryRow remote) async {
    await _db
        .into(_db.diaryEntries)
        .insert(remote.toCompanion(false), mode: InsertMode.insertOrReplace);
  }

  Future<void> _applyRemoteUserProfile(UserProfileRow remote) async {
    await _db
        .into(_db.userProfiles)
        .insert(remote.toCompanion(false), mode: InsertMode.insertOrReplace);
  }

  Future<void> _applyRemoteAppSettings(AppSettingsRow remote) async {
    await _db
        .into(_db.appSettings)
        .insert(remote.toCompanion(false), mode: InsertMode.insertOrReplace);
  }

  static int _compareRevision(int aAt, String aBy, int bAt, String bBy) {
    final ts = aAt.compareTo(bAt);
    if (ts != 0) return ts;
    return aBy.compareTo(bBy);
  }

  Future<_MergeSingletonResult<T>> _mergeSingleton<T extends Object>({
    required T? local,
    required T? remote,
    required _Revision Function(T value) revisionOf,
    required Future<void> Function(T remote) applyRemote,
  }) async {
    if (remote == null && local == null) {
      return _MergeSingletonResult(nextRemote: null);
    }

    if (remote == null && local != null) {
      return _MergeSingletonResult(nextRemote: local, remoteNeedsUpdate: true);
    }

    if (local == null && remote != null) {
      await applyRemote(remote);
      return _MergeSingletonResult(nextRemote: remote, localUpdates: 1);
    }

    if (local == null || remote == null) {
      return _MergeSingletonResult(nextRemote: remote);
    }

    final localRev = revisionOf(local);
    final remoteRev = revisionOf(remote);
    final cmp = _compareRevision(
      localRev.updatedAt,
      localRev.updatedBy,
      remoteRev.updatedAt,
      remoteRev.updatedBy,
    );

    if (cmp > 0) {
      return _MergeSingletonResult(nextRemote: local, remoteNeedsUpdate: true);
    } else if (cmp < 0) {
      await applyRemote(remote);
      return _MergeSingletonResult(nextRemote: remote, localUpdates: 1);
    }

    return _MergeSingletonResult(nextRemote: remote);
  }
}

class _MergeSingletonResult<T extends Object> {
  const _MergeSingletonResult({
    required this.nextRemote,
    this.localUpdates = 0,
    this.remoteNeedsUpdate = false,
  });

  final T? nextRemote;
  final int localUpdates;
  final bool remoteNeedsUpdate;
}

class _Revision {
  const _Revision({required this.updatedAt, required this.updatedBy});
  final int updatedAt;
  final String updatedBy;
}
