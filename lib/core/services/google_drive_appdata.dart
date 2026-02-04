import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveAppData {
  const GoogleDriveAppData();

  Future<String?> findFileId(drive.DriveApi api, {required String name}) async {
    final q =
        "name = '$name' and 'appDataFolder' in parents and trashed = false";
    final fileList = await api.files.list(q: q, spaces: 'appDataFolder');
    return fileList.files?.isNotEmpty == true ? fileList.files!.first.id : null;
  }

  Future<String> downloadText(
    drive.DriveApi api, {
    required String fileId,
  }) async {
    final media =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    return utf8.decodeStream(media.stream);
  }

  Future<void> uploadText(
    drive.DriveApi api, {
    required String name,
    required String content,
    String? fileId,
  }) async {
    final bytes = utf8.encode(content);
    final media = drive.Media(Stream.value(bytes), bytes.length);

    if (fileId != null) {
      await api.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      await api.files.create(
        drive.File(name: name, parents: const ['appDataFolder']),
        uploadMedia: media,
      );
    }
  }
}
