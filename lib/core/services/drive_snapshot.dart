import 'dart:convert';

import 'package:nutrinutri/core/db/app_database.dart';

class DriveSnapshot {
  DriveSnapshot({
    required this.diaryEntries,
    required this.userProfile,
    required this.appSettings,
  });

  final Map<String, SyncDiaryEntry> diaryEntries; // id -> row
  final SyncUserProfile? userProfile; // id==1
  final SyncAppSettings? appSettings; // id==1

  static DriveSnapshot empty() =>
      DriveSnapshot(diaryEntries: {}, userProfile: null, appSettings: null);

  String encode() {
    final map = <String, dynamic>{
      'diaryEntries': diaryEntries.values.map((e) => e.toJson()).toList(),
      'userProfile': userProfile?.toJson(),
      'appSettings': appSettings?.toJson(),
    };
    return jsonEncode(map);
  }

  static DriveSnapshot decode(String raw) {
    if (raw.trim().isEmpty) return DriveSnapshot.empty();

    final root = jsonDecode(raw);
    if (root is! Map<String, dynamic>) return DriveSnapshot.empty();

    final diaryEntries = <String, SyncDiaryEntry>{};
    final diaryList = root['diaryEntries'];
    if (diaryList is List) {
      for (final item in diaryList) {
        final entry = SyncDiaryEntry.fromJson(item);
        if (entry != null) diaryEntries[entry.id] = entry;
      }
    }

    return DriveSnapshot(
      diaryEntries: diaryEntries,
      userProfile: SyncUserProfile.fromJson(root['userProfile']),
      appSettings: SyncAppSettings.fromJson(root['appSettings']),
    );
  }
}

class SyncDiaryEntry {
  SyncDiaryEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.timestamp,
    required this.normalizedName,
    required this.imagePath,
    required this.icon,
    required this.status,
    required this.description,
    required this.durationMinutes,
    required this.updatedAt,
    required this.updatedBy,
    required this.deletedAt,
  });

  factory SyncDiaryEntry.fromRow(DiaryEntryRow row) {
    return SyncDiaryEntry(
      id: row.id,
      name: row.name,
      type: row.type,
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fats: row.fats,
      timestamp: row.timestamp,
      normalizedName: row.normalizedName,
      imagePath: row.imagePath,
      icon: row.icon,
      status: row.status,
      description: row.description,
      durationMinutes: row.durationMinutes,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
    );
  }

  final String id;
  final String name;
  final int type;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final int timestamp;
  final String normalizedName;
  final String? imagePath;
  final String? icon;
  final int status;
  final String? description;
  final int? durationMinutes;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'timestamp': timestamp,
    'normalizedName': normalizedName,
    'imagePath': imagePath,
    'icon': icon,
    'status': status,
    'description': description,
    'durationMinutes': durationMinutes,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
    'deletedAt': deletedAt,
  };

  static SyncDiaryEntry? fromJson(Object? json) {
    if (json is! Map) return null;

    String? s(Object? v) => v is String ? v : null;
    int? i(Object? v) => v is int ? v : (v is num ? v.toInt() : null);
    double? d(Object? v) => v is double ? v : (v is num ? v.toDouble() : null);

    final id = s(json['id']);
    final name = s(json['name']);
    final type = i(json['type']);
    final calories = i(json['calories']);
    final protein = d(json['protein']);
    final carbs = d(json['carbs']);
    final fats = d(json['fats']);
    final timestamp = i(json['timestamp']);
    final normalizedName = s(json['normalizedName']);
    final status = i(json['status']);
    final updatedAt = i(json['updatedAt']);
    final updatedBy = s(json['updatedBy']);

    if (id == null ||
        name == null ||
        type == null ||
        calories == null ||
        protein == null ||
        carbs == null ||
        fats == null ||
        timestamp == null ||
        normalizedName == null ||
        status == null ||
        updatedAt == null ||
        updatedBy == null ||
        updatedBy.isEmpty) {
      return null;
    }

    return SyncDiaryEntry(
      id: id,
      name: name,
      type: type,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      timestamp: timestamp,
      normalizedName: normalizedName,
      imagePath: s(json['imagePath']),
      icon: s(json['icon']),
      status: status,
      description: s(json['description']),
      durationMinutes: i(json['durationMinutes']),
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      deletedAt: i(json['deletedAt']),
    );
  }
}

class SyncUserProfile {
  const SyncUserProfile({
    required this.id,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.goalCalories,
    required this.goalProtein,
    required this.goalCarbs,
    required this.goalFat,
    required this.isConfigured,
    required this.updatedAt,
    required this.updatedBy,
    required this.deletedAt,
  });

  factory SyncUserProfile.fromRow(UserProfileRow row) {
    return SyncUserProfile(
      id: row.id,
      age: row.age,
      weightKg: row.weightKg,
      heightCm: row.heightCm,
      gender: row.gender,
      activityLevel: row.activityLevel,
      goalCalories: row.goalCalories,
      goalProtein: row.goalProtein,
      goalCarbs: row.goalCarbs,
      goalFat: row.goalFat,
      isConfigured: row.isConfigured,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
    );
  }

  final int id;
  final int age;
  final double weightKg;
  final double heightCm;
  final String gender;
  final String activityLevel;
  final int goalCalories;
  final int? goalProtein;
  final int? goalCarbs;
  final int? goalFat;
  final bool isConfigured;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'gender': gender,
    'activityLevel': activityLevel,
    'goalCalories': goalCalories,
    'goalProtein': goalProtein,
    'goalCarbs': goalCarbs,
    'goalFat': goalFat,
    'isConfigured': isConfigured,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
    'deletedAt': deletedAt,
  };

  static SyncUserProfile? fromJson(Object? json) {
    if (json is! Map) return null;

    String? s(Object? v) => v is String ? v : null;
    int? i(Object? v) => v is int ? v : (v is num ? v.toInt() : null);
    double? d(Object? v) => v is double ? v : (v is num ? v.toDouble() : null);
    bool? b(Object? v) => v is bool ? v : null;

    final id = i(json['id']);
    final age = i(json['age']);
    final weightKg = d(json['weightKg']);
    final heightCm = d(json['heightCm']);
    final gender = s(json['gender']);
    final activityLevel = s(json['activityLevel']);
    final goalCalories = i(json['goalCalories']);
    final isConfigured = b(json['isConfigured']);
    final updatedAt = i(json['updatedAt']);
    final updatedBy = s(json['updatedBy']);

    if (id == null ||
        age == null ||
        weightKg == null ||
        heightCm == null ||
        gender == null ||
        activityLevel == null ||
        goalCalories == null ||
        isConfigured == null ||
        updatedAt == null ||
        updatedBy == null ||
        updatedBy.isEmpty) {
      return null;
    }

    return SyncUserProfile(
      id: id,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
      activityLevel: activityLevel,
      goalCalories: goalCalories,
      goalProtein: i(json['goalProtein']),
      goalCarbs: i(json['goalCarbs']),
      goalFat: i(json['goalFat']),
      isConfigured: isConfigured,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      deletedAt: i(json['deletedAt']),
    );
  }
}

class SyncAppSettings {
  const SyncAppSettings({
    required this.id,
    required this.apiKey,
    required this.aiModel,
    required this.fallbackModel,
    required this.updatedAt,
    required this.updatedBy,
    required this.deletedAt,
  });

  factory SyncAppSettings.fromRow(AppSettingsRow row) {
    return SyncAppSettings(
      id: row.id,
      apiKey: row.apiKey,
      aiModel: row.aiModel,
      fallbackModel: row.fallbackModel,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
    );
  }

  final int id;
  final String? apiKey;
  final String aiModel;
  final String? fallbackModel;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'apiKey': apiKey,
    'aiModel': aiModel,
    'fallbackModel': fallbackModel,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
    'deletedAt': deletedAt,
  };

  static SyncAppSettings? fromJson(Object? json) {
    if (json is! Map) return null;

    String? s(Object? v) => v is String ? v : null;
    int? i(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

    final id = i(json['id']);
    final aiModel = s(json['aiModel']);
    final updatedAt = i(json['updatedAt']);
    final updatedBy = s(json['updatedBy']);

    if (id == null ||
        aiModel == null ||
        updatedAt == null ||
        updatedBy == null ||
        updatedBy.isEmpty) {
      return null;
    }

    return SyncAppSettings(
      id: id,
      apiKey: s(json['apiKey']),
      aiModel: aiModel,
      fallbackModel: s(json['fallbackModel']),
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      deletedAt: i(json['deletedAt']),
    );
  }
}
