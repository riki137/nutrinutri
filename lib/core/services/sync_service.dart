import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:http/http.dart' as http;
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/services/drive_snapshot.dart';
import 'package:nutrinutri/core/services/google_drive_appdata.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';

class SyncResult {
  const SyncResult({required this.downloaded, required this.uploaded});
  final int downloaded;
  final int uploaded;
}

class SyncService {
  SyncService({required AppDatabase db}) : _db = db;

  static const _snapshotFileName = 'nutrinutri.json';
  static const _pendingSyncKey = 'pending_sync';

  final AppDatabase _db;
  final _drive = const GoogleDriveAppData();

  Timer? _syncTimer;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: _clientId,
      clientSecret: _clientSecret,
      scopes: _scopes,
    ),
  );

  static const String _clientId =
      '650205047998-i0plaeno2mrp8e1kf6l52cth4076548p.apps.googleusercontent.com';

  // This is not actually a secret, Google just calls it that.
  // The app must have this to use Google Sign In, so there's no way to hide it.
  static const String _clientSecret = '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';

  /// The scopes requested for Google Drive sync.
  static const _scopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    drive.DriveApi.driveAppdataScope,
  ];

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
  Future<void>? _restoreSessionFuture;

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

  Future<void> restoreSession() {
    final pending = _restoreSessionFuture;
    if (pending != null) return pending;

    if (_currentCredentials != null) {
      return Future.value();
    }

    final future = _restoreSessionInternal();
    _restoreSessionFuture = future;
    return future.whenComplete(() {
      if (identical(_restoreSessionFuture, future)) {
        _restoreSessionFuture = null;
      }
    });
  }

  Future<void> _restoreSessionInternal() async {
    _listenToAuthState();

    // Read stored credentials from SharedPreferences.  This never
    // contacts Google Play Services and never shows any UI.  The
    // access token may be stale, but the user info (email, name,
    // photo) is still valid for displaying in the UI.  When a sync
    // is actually attempted, _syncInternal() will handle token expiry
    // gracefully by building the HTTP client itself and recovering
    // on 401.
    try {
      final credentials = await _googleSignIn.silentSignIn();
      _setCredentials(credentials);
    } catch (e) {
      debugPrint('Silent restore failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _setCredentials(null);
  }

  Future<void> syncIfNeeded() async {
    if (currentUser == null) return;

    final pendingPref = await (_db.select(
      _db.localPrefs,
    )..where((t) => t.key.equals(_pendingSyncKey))).getSingleOrNull();
    final isPending = pendingPref?.value == 'true';

    if (isPending) {
      try {
        await sync();
      } catch (e) {
        debugPrint('Pending sync failed: $e');
      }
    } else {
      // Also sync if it's been more than 1 hour since the last sync to fetch remote changes
      final lastSyncPref = await (_db.select(
        _db.localPrefs,
      )..where((t) => t.key.equals('last_sync_time'))).getSingleOrNull();
      final lastSync = int.tryParse(lastSyncPref?.value ?? '0') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastSync > const Duration(hours: 1).inMilliseconds) {
        try {
          await sync();
        } catch (e) {
          debugPrint('Periodic sync failed: $e');
        }
      }
    }
  }

  Future<void> requestSync() async {
    if (currentUser == null) return;

    await _db
        .into(_db.localPrefs)
        .insert(
          const LocalPrefRow(key: _pendingSyncKey, value: 'true'),
          mode: InsertMode.insertOrReplace,
        );

    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(minutes: 1), () {
      sync();
    });
  }

  Widget? get webSignInButton {
    if (kIsWeb) {
      return _googleSignIn.signInButton();
    }
    return null;
  }

  Future<SyncResult>? _syncFuture;

  Future<SyncResult> sync() {
    final pending = _syncFuture;
    if (pending != null) return pending;

    final future = _syncInternal();
    _syncFuture = future;
    return future.whenComplete(() {
      if (identical(_syncFuture, future)) {
        _syncFuture = null;
      }
    });
  }

  /// Builds an authenticated HTTP client directly from stored credentials.
  ///
  /// This bypasses the wrapper library's [authenticatedClient] getter which
  /// has a destructive design flaw: on mobile (where there is no refresh
  /// token) it calls [signOut()] when the access token has expired, silently
  /// logging the user out.  By building the client ourselves with a
  /// far-future local expiry, we avoid that code path entirely.  If the
  /// token IS actually expired, the Google Drive API will return a 401
  /// which we catch and handle in [_syncInternal].
  ///
  /// On desktop (where a refresh token IS present), we still go through the
  /// wrapper's [authenticatedClient] because the base-class correctly uses
  /// [autoRefreshingClient] for that case.
  Future<http.Client?> _buildAuthenticatedClient() async {
    final creds = _currentCredentials;
    if (creds == null) return null;

    // Desktop path: the wrapper handles refresh-token based auto-refresh.
    if (creds.refreshToken != null) {
      return await _googleSignIn.authenticatedClient;
    }

    // Mobile path: build the client manually.
    return gapis.authenticatedClient(
      http.Client(),
      gapis.AccessCredentials(
        gapis.AccessToken(
          creds.tokenType ?? 'Bearer',
          creds.accessToken,
          // Far-future local expiry so googleapis_auth never rejects the
          // token locally.  The real expiry is enforced server-side.
          DateTime.now().toUtc().add(const Duration(days: 365)),
        ),
        null, // no refresh token on mobile
        creds.scopes.isEmpty ? _scopes : creds.scopes,
      ),
    );
  }

  Future<SyncResult> _syncInternal() async {
    if (_currentCredentials == null) {
      return const SyncResult(downloaded: 0, uploaded: 0);
    }

    var client = await _buildAuthenticatedClient();
    if (client == null) {
      return const SyncResult(downloaded: 0, uploaded: 0);
    }

    try {
      return await _performSync(client);
    } catch (e) {
      final message = e.toString();
      if (message.contains('invalid_token') ||
          message.contains('Access was denied') ||
          message.contains('401')) {
        // The stored access token is expired.  Attempt ONE recovery via
        // lightweightSignIn which obtains a fresh token from Google Play
        // Services.  On most single-account Android devices this is
        // completely silent (auto-select). On multi-account devices it
        // may show a brief account picker — but this only happens when
        // the token has actually expired, NOT on every app resume.
        try {
          final credentials = await _googleSignIn.lightweightSignIn();
          _setCredentials(credentials);
          if (_currentCredentials != null) {
            client = await _buildAuthenticatedClient();
            if (client != null) {
              return await _performSync(client);
            }
          }
        } catch (retryError) {
          debugPrint('Token refresh after 401 failed: $retryError');
        }

        // Recovery failed.  Do NOT sign the user out — their profile
        // info is still valid and they should not lose their signed-in
        // state.  The next sync attempt (e.g. on next resume) will
        // retry, or the user can manually re-authenticate from settings.
        debugPrint('Sync skipped: access token expired and silent '
            'refresh was not possible.');
        return const SyncResult(downloaded: 0, uploaded: 0);
      }
      rethrow;
    }
  }

  Future<SyncResult> _performSync(dynamic client) async {
    final driveApi = drive.DriveApi(client);
    final fileId = await _drive.findFileId(driveApi, name: _snapshotFileName);

    final remoteRaw = fileId == null
        ? ''
        : await _drive.downloadText(driveApi, fileId: fileId);
    final remote = DriveSnapshot.decode(remoteRaw);

    final localDiaryRows = await _db.select(_db.diaryEntries).get();
    final localMetricRows = await _db.select(_db.entryMetrics).get();

    final localMetricsByEntryId = <String, List<EntryMetricRow>>{};
    for (final metric in localMetricRows) {
      localMetricsByEntryId
          .putIfAbsent(metric.entryId, () => <EntryMetricRow>[])
          .add(metric);
    }

    final localDiary = <String, SyncedDiaryEntry>{
      for (final row in localDiaryRows)
        row.id: SyncedDiaryEntry(
          row: row,
          metrics: localMetricsByEntryId[row.id] ?? const <EntryMetricRow>[],
        ),
    };

    final localProfileRow = await (_db.select(
      _db.userProfiles,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    final localGoals = await (_db.select(
      _db.metricGoals,
    )..where((t) => t.profileId.equals(1))).get();

    final localProfile = localProfileRow == null
        ? null
        : SyncedUserProfile(row: localProfileRow, goals: localGoals);

    final localSettings = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    final nextDiary = Map<String, SyncedDiaryEntry>.from(remote.diaryEntries);
    SyncedUserProfile? nextProfile = remote.userProfile;
    AppSettingsRow? nextSettings = remote.appSettings;

    var remoteNeedsUpdate = false;
    var localUpdates = 0;
    var uploadedUpdates = 0;

    await _db.transaction(() async {
      final allIds = {...localDiary.keys, ...remote.diaryEntries.keys};

      for (final id in allIds) {
        final local = localDiary[id];
        final remoteEntry = remote.diaryEntries[id];

        if (remoteEntry == null && local != null) {
          nextDiary[id] = local;
          remoteNeedsUpdate = true;
          uploadedUpdates++;
          continue;
        }

        if (local == null && remoteEntry != null) {
          await _applyRemoteDiaryEntry(remoteEntry);
          localUpdates++;
          continue;
        }

        if (local == null || remoteEntry == null) continue;

        final cmp = _compareRevision(
          local.row.updatedAt,
          local.row.updatedBy,
          remoteEntry.row.updatedAt,
          remoteEntry.row.updatedBy,
        );
        if (cmp > 0) {
          nextDiary[id] = local;
          remoteNeedsUpdate = true;
          uploadedUpdates++;
        } else if (cmp < 0) {
          await _applyRemoteDiaryEntry(remoteEntry);
          localUpdates++;
        }
      }

      final profileResult = await _mergeSingleton(
        local: localProfile,
        remote: remote.userProfile,
        revisionOf: (p) =>
            _Revision(updatedAt: p.row.updatedAt, updatedBy: p.row.updatedBy),
        applyRemote: (remote) => _applyRemoteUserProfile(remote),
      );
      localUpdates += profileResult.localUpdates;
      remoteNeedsUpdate = remoteNeedsUpdate || profileResult.remoteNeedsUpdate;
      if (profileResult.remoteNeedsUpdate) uploadedUpdates++;
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
      if (settingsResult.remoteNeedsUpdate) uploadedUpdates++;
      nextSettings = settingsResult.nextRemote;
    });

    if (fileId == null &&
        (localDiary.isNotEmpty ||
            localProfile != null ||
            localSettings != null)) {
      remoteNeedsUpdate = true;
      // In this case, we're uploading everything for the first time
      // But uploadedUpdates is already correctly counting the non-null local items
      // because remote was null.
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

    await (_db.delete(
      _db.localPrefs,
    )..where((t) => t.key.equals(_pendingSyncKey))).go();
    await _db
        .into(_db.localPrefs)
        .insert(
          LocalPrefRow(
            key: 'last_sync_time',
            value: DateTime.now().millisecondsSinceEpoch.toString(),
          ),
          mode: InsertMode.insertOrReplace,
        );
    _syncTimer?.cancel();
    _syncTimer = null;

    return SyncResult(downloaded: localUpdates, uploaded: uploadedUpdates);
  }

  Future<void> _applyRemoteDiaryEntry(SyncedDiaryEntry remote) async {
    await _db.transaction(() async {
      await _db
          .into(_db.diaryEntries)
          .insert(
            remote.row.toCompanion(false),
            mode: InsertMode.insertOrReplace,
          );

      await (_db.delete(
        _db.entryMetrics,
      )..where((t) => t.entryId.equals(remote.row.id))).go();

      if (remote.metrics.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.entryMetrics,
          remote.metrics.map((row) => row.toCompanion(false)).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> _applyRemoteUserProfile(SyncedUserProfile remote) async {
    await _db.transaction(() async {
      await _db
          .into(_db.userProfiles)
          .insert(
            remote.row.toCompanion(false),
            mode: InsertMode.insertOrReplace,
          );

      await (_db.delete(
        _db.metricGoals,
      )..where((t) => t.profileId.equals(remote.row.id))).go();

      if (remote.goals.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.metricGoals,
          remote.goals.map((row) => row.toCompanion(false)).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
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
