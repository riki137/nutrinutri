import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nutrinutri/core/services/kv_store.dart';

class SyncService {
  SyncService(this._kv);
  static const String _isGoogleLoggedInKey = 'is_google_logged_in';
  final KVStore _kv;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _getClientId(),
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static String? _getClientId() {
    if (kIsWeb) {
      return '650205047998-i0plaeno2mrp8e1kf6l52cth4076548p.apps.googleusercontent.com';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '650205047998-rh3ipe08mjo6fdcaio48ei6bta4qkg2k.apps.googleusercontent.com';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '650205047998-3k536pv09s3v2lbbkbk0v1t7gvdv6njq.apps.googleusercontent.com';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return '650205047998-hmrqpdenuqil56l2p6vladdja8imr02o.apps.googleusercontent.com';
      default:
        return null;
    }
  }

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompleteController.stream;

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
      await _kv.put(_isGoogleLoggedInKey, {'value': true});
    } catch (e) {
      debugPrint('Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> restoreSession() async {
    final loggedInState = await _kv.get(_isGoogleLoggedInKey);
    final shouldRestore = loggedInState?['value'] == true;

    if (!shouldRestore) return;

    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Restore session failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _kv.delete(_isGoogleLoggedInKey);
  }

  Future<void> syncIfNeeded() async {
    if (currentUser == null) return;
    await sync();
  }

  Future<int> sync() async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      debugPrint('Cannot sync: Not signed in');
      return 0;
    }

    int localUpdatesCount = 0;
    try {
      final client = await _googleSignIn.authenticatedClient();
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
      final allKeys = {...localSnapshot.keys, ...remoteSnapshot.keys};
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
}
