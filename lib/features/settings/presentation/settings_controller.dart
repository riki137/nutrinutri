import 'package:flutter/material.dart';

import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/calorie_calculator.dart';
import 'package:nutrinutri/features/settings/domain/ai_model_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

class SettingsState {
  SettingsState({
    this.isLoading = false,
    this.isSyncing = false,
    this.selectedModel = 'google/gemini-3-flash-preview',
    this.fallbackModel,
    this.gender = 'male',
    this.activityLevel = 'sedentary',
    this.homeMetricTypes = defaultHomeMetricTypes,
  });

  final bool isLoading;
  final bool isSyncing;
  final String selectedModel;
  final String gender;
  final String activityLevel;
  final List<NutritionMetricType> homeMetricTypes;

  final String? fallbackModel;

  SettingsState copyWith({
    bool? isLoading,
    bool? isSyncing,
    String? selectedModel,
    String? fallbackModel,
    String? gender,
    String? activityLevel,
    List<NutritionMetricType>? homeMetricTypes,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      selectedModel: selectedModel ?? this.selectedModel,
      fallbackModel: fallbackModel ?? this.fallbackModel,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      homeMetricTypes: homeMetricTypes ?? this.homeMetricTypes,
    );
  }
}

@riverpod
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() {
    return SettingsState();
  }

  Future<void> loadSettings({
    required void Function(String key) onKeyLoaded,
    required void Function(String modelId) onCustomModelLoaded,
    required void Function(UserProfile profile) onProfileLoaded,
  }) async {
    final settings = ref.read(settingsServiceProvider);

    final key = await ref.read(apiKeyProvider.future);
    if (key != null) {
      onKeyLoaded(key);
    }

    final model = await settings.getAIModel();
    final isKnownModel = availableModels.any((m) => m.id == model);

    if (isKnownModel) {
      state = state.copyWith(selectedModel: model);
    } else {
      state = state.copyWith(selectedModel: 'custom');
      onCustomModelLoaded(model);
    }

    final fallback = await settings.getFallbackModel();
    if (fallback != null) {
      state = state.copyWith(fallbackModel: fallback);
    }

    final profile = await settings.getUserProfile();
    if (profile != null) {
      state = state.copyWith(
        gender: profile.gender,
        activityLevel: profile.activityLevel,
        homeMetricTypes: profile.dashboardMetricTypes,
      );
      onProfileLoaded(profile);
    }
  }

  void updateModel(String modelId) {
    state = state.copyWith(selectedModel: modelId);
  }

  void updateFallbackModel(String? modelId) {
    state = state.copyWith(fallbackModel: modelId);
  }

  void updateGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void updateActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
  }

  void updateHomeMetric(int slot, NutritionMetricType metricType) {
    final next = normalizeHomeMetricTypes(state.homeMetricTypes).toList();

    if (slot < 0 || slot >= next.length) return;
    next[slot] = metricType;
    state = state.copyWith(homeMetricTypes: normalizeHomeMetricTypes(next));
  }

  Future<void> save({
    required String apiKey,
    required String customModel,
    required String age,
    required String weight,
    required String height,
    required String calorieGoal,
    required Map<NutritionMetricType, String> metricGoalInputs,
    required List<NutritionMetricType> homeMetricTypes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = ref.read(settingsServiceProvider);
      await settings.saveApiKey(apiKey.trim());

      final modelToSave = state.selectedModel == 'custom'
          ? customModel.trim()
          : state.selectedModel;
      if (modelToSave.isNotEmpty) {
        await settings.saveAIModel(modelToSave);
      }

      await settings.saveFallbackModel(state.fallbackModel);

      final parsedAge = int.tryParse(age.trim());
      final parsedWeight = _parseGoal(weight);
      final parsedHeight = _parseGoal(height);
      final parsedCalorieGoal = _parseGoal(calorieGoal);

      if (parsedAge != null &&
          parsedWeight != null &&
          parsedHeight != null &&
          parsedCalorieGoal != null &&
          parsedCalorieGoal > 0) {
        final metricGoals = <NutritionMetricType, double>{};
        for (final entry in metricGoalInputs.entries) {
          final parsed = _parseGoal(entry.value);
          if (parsed != null && parsed > 0) {
            metricGoals[entry.key] = parsed;
          }
        }

        await settings.saveUserProfile(
          age: parsedAge,
          weight: parsedWeight,
          height: parsedHeight,
          gender: state.gender,
          activityLevel: state.activityLevel,
          calorieGoal: parsedCalorieGoal,
          metricGoals: metricGoals,
          homeMetricTypes: normalizeHomeMetricTypes(homeMetricTypes),
        );
      }

      ref.invalidate(apiKeyProvider);
      ref.invalidate(aiServiceProvider);
      ref.invalidate(userProfileProvider);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  double? _parseGoal(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<int> sync() async {
    state = state.copyWith(isSyncing: true);
    try {
      return await ref.read(syncServiceProvider).sync();
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> signIn() async {
    await ref.read(syncServiceProvider).signIn();
  }

  Widget? get webSignInButton => ref.read(syncServiceProvider).webSignInButton;

  Future<void> signOut() async {
    await ref.read(syncServiceProvider).signOut();
  }

  final List<AIModelInfo> availableModels = const [
    AIModelInfo(
      id: 'google/gemini-3-flash-preview',
      name: 'Gemini 3 Flash',
      price: r'~$0.0008',
      description: 'Recommended, Default, Fast, Accurate',
    ),
    AIModelInfo(
      id: 'google/gemini-3-pro-preview',
      name: 'Gemini 3 Pro',
      price: r'~$0.04',
      description: 'Best, expensive',
    ),
    AIModelInfo(
      id: 'openai/gpt-5.2',
      name: 'GPT-5.2',
      price: r'~$0.008',
      description: 'Reliable, Accurate',
    ),
    AIModelInfo(
      id: 'openai/gpt-5-mini',
      name: 'GPT-5 Mini',
      price: r'~$0.003',
      description: 'Cheaper, less knowledge',
    ),
    AIModelInfo(
      id: 'anthropic/claude-sonnet-4.5',
      name: 'Claude Sonnet 4.5',
      price: r'~$0.007',
      description: 'Not very accurate',
    ),
    AIModelInfo(
      id: 'anthropic/claude-opus-4.5',
      name: 'Claude Opus 4.5',
      price: r'~$0.01',
      description: 'Not very accurate',
    ),
    AIModelInfo(
      id: 'x-ai/grok-4',
      name: 'Grok 4',
      price: '?',
      description: 'Latest model from xAI',
    ),
    AIModelInfo(
      id: 'custom',
      name: 'Custom OpenRouter model',
      price: 'Varies',
      description: 'Advanced, not recommended',
    ),
  ];

  int calculateDailyCalories({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
  }) {
    return CalorieCalculator.calculateDailyCalories(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
    );
  }
}

@riverpod
class UnsavedSettingsChanges extends _$UnsavedSettingsChanges {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
