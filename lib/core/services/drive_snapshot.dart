import 'dart:convert';

import 'package:nutrinutri/core/db/app_database.dart';

class DriveSnapshot {
  const DriveSnapshot({
    required this.diaryEntries,
    required this.userProfile,
    required this.appSettings,
  });

  /// Bump whenever the on-disk JSON shape changes.
  static const int version = 2;

  final Map<String, DiaryEntryRow> diaryEntries; // id -> row
  final UserProfileRow? userProfile; // id == 1
  final AppSettingsRow? appSettings; // id == 1

  static const DriveSnapshot empty = DriveSnapshot(
    diaryEntries: {},
    userProfile: null,
    appSettings: null,
  );

  String encode() {
    return jsonEncode(<String, Object?>{
      'version': version,
      // Encode as list to keep the JSON easy to inspect and edit by hand.
      'diaryEntries': diaryEntries.values.map((e) => e.toJson()).toList(),
      'userProfile': userProfile?.toJson(),
      'appSettings': appSettings?.toJson(),
    });
  }

  static DriveSnapshot decode(String raw) {
    if (raw.trim().isEmpty) return DriveSnapshot.empty;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return DriveSnapshot.empty;

    Map<String, dynamic> asMap(Object? value) =>
        Map<String, dynamic>.from(value as Map);

    DiaryEntryRow? parseDiary(Object? value) {
      if (value is! Map) return null;
      try {
        final row = DiaryEntryRow.fromJson(asMap(value));
        return row;
      } catch (_) {
        return null;
      }
    }

    UserProfileRow? parseProfile(Object? value) {
      if (value is! Map) return null;
      try {
        return UserProfileRow.fromJson(asMap(value));
      } catch (_) {
        return null;
      }
    }

    AppSettingsRow? parseSettings(Object? value) {
      if (value is! Map) return null;
      try {
        return AppSettingsRow.fromJson(asMap(value));
      } catch (_) {
        return null;
      }
    }

    final diaryEntries = <String, DiaryEntryRow>{};
    final diaryRaw = decoded['diaryEntries'];

    // Accept both our current list format and a future map format.
    if (diaryRaw is List) {
      for (final item in diaryRaw) {
        final row = parseDiary(item);
        if (row != null) diaryEntries[row.id] = row;
      }
    } else if (diaryRaw is Map) {
      for (final entry in diaryRaw.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final row = parseDiary(entry.value);
        if (row == null) continue;
        diaryEntries[key] = row.id == key ? row : row.copyWith(id: key);
      }
    }

    return DriveSnapshot(
      diaryEntries: diaryEntries,
      userProfile: parseProfile(decoded['userProfile']),
      appSettings: parseSettings(decoded['appSettings']),
    );
  }
}
