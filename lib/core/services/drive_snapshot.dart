import 'dart:convert';

import 'package:nutrinutri/core/db/app_database.dart';

const _defaultHomeMetricTypes = 'carbs,fats,protein,fiber,caffeine,water';

class SyncedDiaryEntry {
  const SyncedDiaryEntry({required this.row, required this.metrics});

  final DiaryEntryRow row;
  final List<EntryMetricRow> metrics;

  Map<String, Object?> toJson() {
    return {
      'row': row.toJson(),
      'metrics': metrics
          .map((metric) => metric.toJson())
          .toList(growable: false),
    };
  }
}

class SyncedUserProfile {
  const SyncedUserProfile({required this.row, required this.goals});

  final UserProfileRow row;
  final List<MetricGoalRow> goals;

  Map<String, Object?> toJson() {
    return {
      'row': row.toJson(),
      'goals': goals.map((goal) => goal.toJson()).toList(growable: false),
    };
  }
}

class DriveSnapshot {
  const DriveSnapshot({
    required this.diaryEntries,
    required this.userProfile,
    required this.appSettings,
  });

  /// Bump whenever the on-disk JSON shape changes.
  static const int version = 3;

  final Map<String, SyncedDiaryEntry> diaryEntries; // id -> row + metrics
  final SyncedUserProfile? userProfile; // id == 1
  final AppSettingsRow? appSettings; // id == 1

  static const DriveSnapshot empty = DriveSnapshot(
    diaryEntries: {},
    userProfile: null,
    appSettings: null,
  );

  String encode() {
    return jsonEncode(<String, Object?>{
      'version': version,
      'diaryEntries': diaryEntries.values.map((e) => e.toJson()).toList(),
      'userProfile': userProfile?.toJson(),
      'appSettings': appSettings?.toJson(),
    });
  }

  static DriveSnapshot decode(String raw) {
    if (raw.trim().isEmpty) return DriveSnapshot.empty;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return DriveSnapshot.empty;

    final diaryEntries = _parseDiaryEntries(decoded['diaryEntries']);
    final profile = _parseUserProfile(decoded['userProfile']);
    final settings = _parseSettings(decoded['appSettings']);

    return DriveSnapshot(
      diaryEntries: diaryEntries,
      userProfile: profile,
      appSettings: settings,
    );
  }

  static Map<String, SyncedDiaryEntry> _parseDiaryEntries(Object? raw) {
    final result = <String, SyncedDiaryEntry>{};

    if (raw is List) {
      for (final item in raw) {
        final entry = _parseDiaryEntry(item);
        if (entry == null) continue;
        result[entry.row.id] = entry;
      }
      return result;
    }

    if (raw is Map) {
      for (final mapEntry in raw.entries) {
        final id = mapEntry.key;
        if (id is! String) continue;
        final parsed = _parseDiaryEntry(mapEntry.value, forcedId: id);
        if (parsed == null) continue;
        result[id] = parsed;
      }
    }

    return result;
  }

  static SyncedDiaryEntry? _parseDiaryEntry(Object? raw, {String? forcedId}) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final rowMap = map['row'];
    final rowSource = rowMap is Map<String, dynamic>
        ? rowMap
        : rowMap is Map
        ? Map<String, dynamic>.from(rowMap)
        : map;

    final row = _parseDiaryRow(rowSource, forcedId: forcedId);
    if (row == null) return null;

    final metrics = _parseMetrics(map['metrics'], row.id);
    if (metrics.isNotEmpty) {
      return SyncedDiaryEntry(row: row, metrics: metrics);
    }

    return SyncedDiaryEntry(
      row: row,
      metrics: _legacyDiaryMetrics(map, row.id),
    );
  }

  static DiaryEntryRow? _parseDiaryRow(
    Map<String, dynamic> map, {
    String? forcedId,
  }) {
    try {
      final row = DiaryEntryRow.fromJson(map);
      if (forcedId == null || row.id == forcedId) {
        return row;
      }
      return row.copyWith(id: forcedId);
    } catch (_) {
      return null;
    }
  }

  static List<EntryMetricRow> _parseMetrics(Object? raw, String entryId) {
    if (raw is! List) return const [];

    final metrics = <EntryMetricRow>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final type = _asInt(map['type']);
      final value = _asDouble(map['value']);
      if (type == null || value == null) continue;
      if (type < 0 || type >= 10) continue;

      metrics.add(
        EntryMetricRow(
          entryId: entryId,
          type: type,
          value: _roundMetric(value),
        ),
      );
    }
    return metrics;
  }

  static List<EntryMetricRow> _legacyDiaryMetrics(
    Map<String, dynamic> map,
    String entryId,
  ) {
    final metrics = <EntryMetricRow>[];

    final calories = _asDouble(map['calories']);
    metrics.add(
      EntryMetricRow(
        entryId: entryId,
        type: 0,
        value: _roundMetric(calories ?? 0),
      ),
    );

    final entryType = _asInt(map['type']) ?? 0;
    if (entryType == 0) {
      final carbs = _asDouble(map['carbs']);
      final fats = _asDouble(map['fats']);
      final protein = _asDouble(map['protein']);

      if (carbs != null) {
        metrics.add(
          EntryMetricRow(entryId: entryId, type: 1, value: _roundMetric(carbs)),
        );
      }

      if (fats != null) {
        metrics.add(
          EntryMetricRow(entryId: entryId, type: 3, value: _roundMetric(fats)),
        );
      }

      if (protein != null) {
        metrics.add(
          EntryMetricRow(
            entryId: entryId,
            type: 5,
            value: _roundMetric(protein),
          ),
        );
      }
    }

    return metrics;
  }

  static SyncedUserProfile? _parseUserProfile(Object? raw) {
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final rowMap = map['row'];
    final rowSource = rowMap is Map<String, dynamic>
        ? rowMap
        : rowMap is Map
        ? Map<String, dynamic>.from(rowMap)
        : map;

    final row = _parseUserProfileRow(rowSource);
    if (row == null) return null;

    final goals = _parseGoals(map['goals'], row.id);
    if (goals.isNotEmpty) {
      return SyncedUserProfile(row: row, goals: goals);
    }

    return SyncedUserProfile(row: row, goals: _legacyGoals(map, row.id));
  }

  static UserProfileRow? _parseUserProfileRow(Map<String, dynamic> map) {
    try {
      return UserProfileRow.fromJson(map);
    } catch (_) {
      final id = _asInt(map['id']);
      final age = _asInt(map['age']);
      final weightKg = _asDouble(map['weightKg']);
      final heightCm = _asDouble(map['heightCm']);
      final gender = map['gender'];
      final activityLevel = map['activityLevel'];
      final isConfigured = map['isConfigured'];
      final updatedAt = _asInt(map['updatedAt']);
      final updatedBy = map['updatedBy'];
      final deletedAt = _asInt(map['deletedAt']);

      if (id == null ||
          age == null ||
          weightKg == null ||
          heightCm == null ||
          gender is! String ||
          activityLevel is! String ||
          isConfigured is! bool ||
          updatedAt == null ||
          updatedBy is! String) {
        return null;
      }

      return UserProfileRow(
        id: id,
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        gender: gender,
        activityLevel: activityLevel,
        homeMetricTypes: _defaultHomeMetricTypes,
        isConfigured: isConfigured,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        deletedAt: deletedAt,
      );
    }
  }

  static List<MetricGoalRow> _parseGoals(Object? raw, int profileId) {
    if (raw is! List) return const [];

    final goals = <MetricGoalRow>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final type = _asInt(map['type']);
      final value = _asDouble(map['value']);
      if (type == null || value == null) continue;
      if (type < 0 || type >= 10) continue;
      goals.add(
        MetricGoalRow(
          profileId: profileId,
          type: type,
          value: _roundMetric(value),
        ),
      );
    }

    return goals;
  }

  static List<MetricGoalRow> _legacyGoals(
    Map<String, dynamic> map,
    int profileId,
  ) {
    final goals = <MetricGoalRow>[];

    final calories = _asDouble(map['goalCalories']);
    if (calories != null) {
      goals.add(
        MetricGoalRow(
          profileId: profileId,
          type: 0,
          value: _roundMetric(calories),
        ),
      );
    }

    final carbs = _asDouble(map['goalCarbs']);
    if (carbs != null) {
      goals.add(
        MetricGoalRow(
          profileId: profileId,
          type: 1,
          value: _roundMetric(carbs),
        ),
      );
    }

    final fats = _asDouble(map['goalFat']);
    if (fats != null) {
      goals.add(
        MetricGoalRow(profileId: profileId, type: 3, value: _roundMetric(fats)),
      );
    }

    final protein = _asDouble(map['goalProtein']);
    if (protein != null) {
      goals.add(
        MetricGoalRow(
          profileId: profileId,
          type: 5,
          value: _roundMetric(protein),
        ),
      );
    }

    return goals;
  }

  static AppSettingsRow? _parseSettings(Object? value) {
    if (value is! Map) return null;
    try {
      return AppSettingsRow.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double _roundMetric(double value) {
    return (value * 10).roundToDouble() / 10;
  }
}
