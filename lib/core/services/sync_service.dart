import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nutrinutri/core/services/food_index_service.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';
import 'package:nutrinutri/core/services/kv_store.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';

class SyncService {
  SyncService(this._kv, this._foodIndex);
  static const String _isGoogleLoggedInKey = 'is_google_logged_in';
  final KVStore _kv;
  final FoodIndexService _foodIndex;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: _getClientId(),
      clientSecret: _getClientSecret(),
      scopes: [
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
        drive.DriveApi.driveAppdataScope,
      ],
    ),
  );

  static String _getClientId() {
    // Use same client ID for all platforms as google_sign_in_all_platforms uses web secret everywhere
    return '650205047998-i0plaeno2mrp8e1kf6l52cth4076548p.apps.googleusercontent.com';
  }

  // Client secret is used for all platforms with google_sign_in_all_platforms
  static String? _getClientSecret() {
    return "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";
  }

  GoogleSignInCredentials? _currentCredentials;
  GoogleSignInCredentials? get currentCredentials => _currentCredentials;

  GoogleUserInfo? _currentUserInfo;

  /// Returns the cached user info.
  GoogleUserInfo? get currentUser => _currentUserInfo;

  /// Stream controller for user info changes.
  final _userInfoController = StreamController<GoogleUserInfo?>.broadcast();

  /// Stream of user info changes.
  Stream<GoogleUserInfo?> get onCurrentUserChanged =>
      _userInfoController.stream;

  /// Flag to ensure we only set up the auth state listener once.
  bool _isListeningToAuthState = false;

  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompleteController.stream;

  void _listenToAuthState() {
    if (_isListeningToAuthState) return;
    _isListeningToAuthState = true;

    // Emit initial value
    _userInfoController.add(_currentUserInfo);

    _googleSignIn.authenticationState.listen((credentials) async {
      _currentCredentials = credentials;
      if (credentials != null) {
        await _fetchAndCacheUserInfo(credentials.accessToken);
      } else {
        _currentUserInfo = null;
        _userInfoController.add(null);
      }
    });
  }

  Future<void> _fetchAndCacheUserInfo(String accessToken,
      {bool isRetry = false}) async {
    final userInfo = await GoogleUserInfo.fromAccessToken(accessToken);
    if (userInfo == null) {
      if (!isRetry) {
        debugPrint('Failed to fetch user info - trying to refresh token...');
        try {
          final newCredentials = await _googleSignIn.silentSignIn();
          if (newCredentials != null) {
            _currentCredentials = newCredentials;
            return _fetchAndCacheUserInfo(
              newCredentials.accessToken,
              isRetry: true,
            );
          }
        } catch (e) {
          debugPrint('Failed to refresh token: $e');
        }
      }

      debugPrint('Failed to fetch user info - token may be invalid');
      // Clear invalid credentials
      await clearAccessToken();
      return;
    }
    _currentUserInfo = userInfo;
    _userInfoController.add(userInfo);
    debugPrint('User info fetched: ${userInfo.name ?? userInfo.email}');
  }

  Future<void> signIn() async {
    try {
      debugPrint('SyncService.signIn() called');
      // Set up listener first to ensure stream subscribers are ready
      _listenToAuthState();
      debugPrint('About to call _googleSignIn.signIn()');
      final credentials = await _googleSignIn.signIn();
      debugPrint('Sign in completed, credentials: ${credentials != null}');
      _currentCredentials = credentials;
      if (credentials != null) {
        debugPrint(
          'Access Token present: ${credentials.accessToken.isNotEmpty}',
        );
        // The auth state listener will also fetch user info, but we do it
        // explicitly here to ensure it's available immediately
        await _fetchAndCacheUserInfo(credentials.accessToken);
        await _kv.put(_isGoogleLoggedInKey, {'value': true});
      }
    } catch (e, stackTrace) {
      debugPrint('Sign in failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> restoreSession() async {
    final loggedInState = await _kv.get(_isGoogleLoggedInKey);
    final shouldRestore = loggedInState?['value'] == true;

    if (!shouldRestore) return;

    try {
      _listenToAuthState();
      final credentials = await _googleSignIn.silentSignIn();
      _currentCredentials = credentials;
      if (credentials != null) {
        await _fetchAndCacheUserInfo(credentials.accessToken);
      }
    } catch (e) {
      debugPrint('Restore session failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentCredentials = null;
    _currentUserInfo = null;
    _userInfoController.add(null);
    await _kv.delete(_isGoogleLoggedInKey);
  }

  /// Clears the cached credentials and forces a fresh sign-in.
  /// Use this when the access token has expired or is invalid.
  Future<void> clearAccessToken() async {
    debugPrint('Clearing access token and credentials');
    await signOut();
  }

  Future<void> syncIfNeeded() async {
    if (currentUser == null) return;
    await sync();
  }

  Future<int> sync() async {
    final credentials = _currentCredentials;
    if (credentials == null) {
      debugPrint('Cannot sync: Not signed in');
      return 0;
    }

    int localUpdatesCount = 0;
    try {
      final client = await _googleSignIn.authenticatedClient;
      if (client == null) throw Exception('Authenticated client is null');

      final driveApi = drive.DriveApi(client);

      // 1. Get or Create Snapshot File
      final fileId = await _getSnapshotFileId(driveApi);
      Map<String, dynamic> remoteSnapshot = {};

      if (fileId != null) {
        remoteSnapshot = await _downloadSnapshot(driveApi, fileId);
      }

      // 2. Get Local Data
      final localRows = await _kv.getAllSync();

      // Convert local rows to Map for easier lookup
      // Local row: {key, value, updated_at, deleted_at}
      final localSnapshot = <String, Map<String, dynamic>>{};
      for (final row in localRows) {
        localSnapshot[row['key']] = row;
      }

      // 3. Merge Logic
      // Filter out local-only keys (starting with 'local_')
      final allKeys = {
        ...localSnapshot.keys,
        ...remoteSnapshot.keys,
      }.where((k) => !k.startsWith('local_'));

      bool remoteNeedsUpdate = false;

      final nextRemoteSnapshot = Map<String, dynamic>.from(remoteSnapshot);

      for (final key in allKeys) {
        final local = localSnapshot[key];
        final remote =
            remoteSnapshot[key] as Map<String, dynamic>?; // {v, u, d}

        // Case 1: Exists locally only -> push to remote
        if (remote == null) {
          // Push local to remote
          nextRemoteSnapshot[key] = {
            'v': local!['value'],
            'u': local['updated_at'],
            'd': local['deleted_at'],
          };
          remoteNeedsUpdate = true;
          continue;
        }

        // Case 2: Exists remotely only -> pull to local
        if (local == null) {
          // Pull remote to local (even if deleted, we sync the deletion state)
          await _kv.putSync(key, remote['v'], remote['u'], remote['d']);
          await _updateIndexFromRemote(key, remote['v']);
          localUpdatesCount++;
          continue;
        }

        // Case 3: Exists in both -> compare timestamps
        final localTs = local['updated_at'] as int? ?? 0;
        final remoteTs = remote['u'] as int? ?? 0;

        if (localTs > remoteTs) {
          // Local is newer -> update remote
          nextRemoteSnapshot[key] = {
            'v': local['value'],
            'u': localTs,
            'd': local['deleted_at'],
          };
          remoteNeedsUpdate = true;
        } else if (remoteTs > localTs) {
          // Remote is newer -> update local
          await _kv.putSync(key, remote['v'], remoteTs, remote['d']);
          await _updateIndexFromRemote(key, remote['v']);
          localUpdatesCount++;
        }
        // Else: equal, do nothing
      }

      // 4. Upload if needed
      if (remoteNeedsUpdate) {
        await _uploadSnapshot(driveApi, fileId, nextRemoteSnapshot);
      }

      if (localUpdatesCount > 0) {
        _syncCompleteController.add(null);
      }

      return localUpdatesCount;
    } catch (e) {
      debugPrint('Sync Error: $e');
      rethrow;
    }
  }

  Future<String?> _getSnapshotFileId(drive.DriveApi driveApi) async {
    final fileName = 'nutrinutri_v1.json';
    final q =
        "name = '$fileName' and 'appDataFolder' in parents and trashed = false";
    final fileList = await driveApi.files.list(q: q, spaces: 'appDataFolder');

    if (fileList.files?.isNotEmpty == true) {
      return fileList.files!.first.id;
    }
    return null;
  }

  Future<Map<String, dynamic>> _downloadSnapshot(
    drive.DriveApi driveApi,
    String fileId,
  ) async {
    final media =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final jsonString = await utf8.decodeStream(media.stream);
    if (jsonString.isEmpty) return {};
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to decode snapshot: $e');
      return {};
    }
  }

  Future<void> _uploadSnapshot(
    drive.DriveApi driveApi,
    String? fileId,
    Map<String, dynamic> data,
  ) async {
    final fileName = 'nutrinutri_v1.json';
    final jsonContent = jsonEncode(data);
    final media = drive.Media(
      Stream.value(utf8.encode(jsonContent)),
      utf8.encode(jsonContent).length,
    );

    if (fileId != null) {
      await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      await driveApi.files.create(
        drive.File(name: fileName, parents: ['appDataFolder']),
        uploadMedia: media,
      );
    }
  }

  Future<void> _updateIndexFromRemote(String key, dynamic value) async {
    if (!key.startsWith('diary_') || value == null) return;

    try {
      final entriesJson = (value['entries'] as List?) ?? [];
      for (final entryJson in entriesJson) {
        final entry = DiaryEntry.fromJson(entryJson);
        if (entry.type == EntryType.food) {
          await _foodIndex.indexEntry(entry);
        }
      }
    } catch (e) {
      debugPrint('Error indexing synced entry ($key): $e');
    }
  }
}
