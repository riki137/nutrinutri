import 'package:drift/drift.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/services/device_id_service.dart';

class SettingsService {
  SettingsService(this._db, this._deviceId);
  final AppDatabase _db;
  final DeviceIdService _deviceId;

  static const _settingsId = 1;
  static const _profileId = 1;

  Future<({String deviceId, int now})> _audit() async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;
    return (deviceId: deviceId, now: now);
  }

  Future<void> saveApiKey(String key) async {
    await _updateSettings(
      apiKey: Value(key.trim().isEmpty ? null : key.trim()),
    );
  }

  Future<String?> getApiKey() async {
    return (await _settings())?.apiKey;
  }

  Future<void> saveAIModel(String model) async {
    await _updateSettings(aiModel: Value(model.trim()));
  }

  Future<String> getAIModel() async {
    return (await _settings())?.aiModel ?? 'google/gemini-3-flash-preview';
  }

  Future<void> saveFallbackModel(String? model) async {
    await _updateSettings(
      fallbackModel: Value(
        model?.trim().isEmpty == true ? null : model?.trim(),
      ),
    );
  }

  Future<String?> getFallbackModel() async {
    return (await _settings())?.fallbackModel;
  }

  Future<void> saveUserProfile({
    required int age,
    required double weight, // kg
    required double height, // cm
    required String gender,
    required String activityLevel,
    required int goalCalories,
    int? goalProtein,
    int? goalCarbs,
    int? goalFat,
  }) async {
    final audit = await _audit();

    await _db
        .into(_db.userProfiles)
        .insert(
          UserProfilesCompanion.insert(
            id: Value(_profileId),
            age: age,
            weightKg: weight,
            heightCm: height,
            gender: gender,
            activityLevel: activityLevel,
            goalCalories: goalCalories,
            goalProtein: Value(goalProtein),
            goalCarbs: Value(goalCarbs),
            goalFat: Value(goalFat),
            isConfigured: const Value(true),
            updatedAt: Value(audit.now),
            updatedBy: Value(audit.deviceId),
            deletedAt: Value<int?>(null),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<UserProfile?> getUserProfile() async {
    final row =
        await (_db.select(_db.userProfiles)
              ..where((t) => t.id.equals(_profileId) & t.deletedAt.isNull()))
            .getSingleOrNull();

    if (row == null || !row.isConfigured) return null;

    return UserProfile(
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
    );
  }

  Future<bool> isOnboarded() async {
    final profile = await getUserProfile();
    return profile != null && profile.isConfigured;
  }

  Future<AppSettingsRow?> _settings() async {
    return (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(_settingsId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<void> _updateSettings({
    Value<String?> apiKey = const Value.absent(),
    Value<String> aiModel = const Value.absent(),
    Value<String?> fallbackModel = const Value.absent(),
  }) async {
    final audit = await _audit();
    final existing = await _settings();

    final nextApiKey = apiKey.present ? apiKey.value : existing?.apiKey;
    final nextAiModel = aiModel.present
        ? aiModel.value
        : (existing?.aiModel ?? 'google/gemini-3-flash-preview');
    final nextFallbackModel = fallbackModel.present
        ? fallbackModel.value
        : existing?.fallbackModel;

    await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion(
            id: const Value(_settingsId),
            apiKey: Value(nextApiKey),
            aiModel: Value(nextAiModel),
            fallbackModel: Value(nextFallbackModel),
            updatedAt: Value(audit.now),
            updatedBy: Value(audit.deviceId),
            deletedAt: const Value(null),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
