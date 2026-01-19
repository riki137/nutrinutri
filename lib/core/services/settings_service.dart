import 'package:nutrinutri/core/services/kv_store.dart';

class SettingsService {
  final KVStore _kv;

  static const String _profileKey = 'user_profile';
  static const String _apiKeyKey = 'api_key';

  SettingsService(this._kv);

  Future<void> saveApiKey(String key) async {
    await _kv.put(_apiKeyKey, {'key': key});
  }

  Future<String?> getApiKey() async {
    final data = await _kv.get(_apiKeyKey);
    return data?['key'] as String?;
  }

  Future<void> saveUserProfile({
    required int age,
    required double weight, // in kg
    required double height, // in cm
    required String gender, // 'male' or 'female'
    required String activityLevel, // 'sedentary', 'active', etc.
    required int goalCalories,
  }) async {
    await _kv.put(_profileKey, {
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activityLevel': activityLevel,
      'goalCalories': goalCalories,
      'isConfigured': true,
    });
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    return await _kv.get(_profileKey);
  }

  Future<bool> isOnboarded() async {
    final profile = await getUserProfile();
    return profile != null && profile['isConfigured'] == true;
  }

  Future<void> saveAIModel(String model) async {
    await _kv.put('ai_model', {'model': model});
  }

  Future<String> getAIModel() async {
    final data = await _kv.get('ai_model');
    return data?['model'] as String? ?? 'openai/gpt-4o-mini';
  }
}
