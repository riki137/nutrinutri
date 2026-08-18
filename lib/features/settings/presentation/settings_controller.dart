import 'package:flutter/material.dart';

import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/services/sync_service.dart';
import 'package:nutrinutri/core/utils/calorie_calculator.dart';
import 'package:nutrinutri/features/settings/domain/ai_model_info.dart';
import 'package:nutrinutri/features/settings/domain/ai_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// Sentinel used by [SettingsState.copyWith] to distinguish "argument omitted"
/// from "explicitly set to null" for nullable fields like [fallbackModel].
const Object _kUnset = Object();

class SettingsState {
  SettingsState({
    this.isLoading = false,
    this.isSyncing = false,
    this.selectedProvider = kDefaultProviderId,
    this.selectedModel = 'google/gemini-3.5-flash',
    this.fallbackModel = 'anthropic/claude-sonnet-5',
    this.gender = 'male',
    this.activityLevel = 'sedentary',
    this.homeMetricTypes = defaultHomeMetricTypes,
  });

  final bool isLoading;
  final bool isSyncing;
  final String selectedProvider;
  final String selectedModel;
  final String gender;
  final String activityLevel;
  final List<NutritionMetricType> homeMetricTypes;

  final String? fallbackModel;

  /// Whether the currently selected provider uses OpenRouter's rich preset
  /// model list (true) versus a free-text model id field (false).
  bool get usesModelPresets => selectedProvider == kDefaultProviderId;

  SettingsState copyWith({
    bool? isLoading,
    bool? isSyncing,
    String? selectedProvider,
    String? selectedModel,
    Object? fallbackModel = _kUnset,
    String? gender,
    String? activityLevel,
    List<NutritionMetricType>? homeMetricTypes,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: selectedModel ?? this.selectedModel,
      fallbackModel: identical(fallbackModel, _kUnset)
          ? this.fallbackModel
          : fallbackModel as String?,
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
    required void Function(String modelId) onCustomFallbackLoaded,
    required void Function(String url) onCustomBaseUrlLoaded,
    required void Function(String instructions) onNutritionistInstructionsLoaded,
    required void Function(String instructions) onTrainerInstructionsLoaded,
  }) async {
    final settings = ref.read(settingsServiceProvider);

    final key = await ref.read(apiKeyProvider.future);
    if (key != null) {
      onKeyLoaded(key);
    }

    final provider = await settings.getProvider();
    state = state.copyWith(selectedProvider: provider);

    final customBaseUrl = await settings.getCustomBaseUrl();
    if (customBaseUrl != null) {
      onCustomBaseUrlLoaded(customBaseUrl);
    }

    // Only OpenRouter uses the preset dropdown; every other provider stores a
    // free-text model id which is surfaced through the custom model field.
    final usesPresets = provider == kDefaultProviderId;

    final nutritionistInstructions = await settings
        .getNutritionistInstructions();
    if (nutritionistInstructions != null &&
        nutritionistInstructions.isNotEmpty) {
      onNutritionistInstructionsLoaded(nutritionistInstructions);
    }

    final trainerInstructions = await settings.getTrainerInstructions();
    if (trainerInstructions != null && trainerInstructions.isNotEmpty) {
      onTrainerInstructionsLoaded(trainerInstructions);
    }

    final model = await settings.getAIModel();
    final isKnownModel = usesPresets && availableModels.any((m) => m.id == model);

    if (isKnownModel) {
      state = state.copyWith(selectedModel: model);
    } else {
      state = state.copyWith(selectedModel: 'custom');
      onCustomModelLoaded(model);
    }

    final fallback = await settings.getFallbackModel();
    if (fallback != null) {
      final isKnownFallback =
          usesPresets &&
          availableModels.any((m) => m.id == fallback && m.id != 'custom');
      if (isKnownFallback) {
        state = state.copyWith(fallbackModel: fallback);
      } else {
        state = state.copyWith(fallbackModel: 'custom');
        onCustomFallbackLoaded(fallback);
      }
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

  void updateProvider(String providerId) {
    state = state.copyWith(selectedProvider: providerId);
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
    required String customFallbackModel,
    required String customBaseUrl,
    required String nutritionistInstructions,
    required String trainerInstructions,
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
      await settings.saveProvider(state.selectedProvider);
      await settings.saveCustomBaseUrl(customBaseUrl.trim());
      await settings.saveNutritionistInstructions(nutritionistInstructions);
      await settings.saveTrainerInstructions(trainerInstructions);

      final usesPresets = state.usesModelPresets;

      String modelToSave;
      if (usesPresets) {
        modelToSave = state.selectedModel == 'custom'
            ? customModel.trim()
            : state.selectedModel;
      } else {
        // Free-text providers store whatever the user typed, defaulting to the
        // provider's suggested model when left blank.
        modelToSave = customModel.trim();
        if (modelToSave.isEmpty) {
          modelToSave = providerById(state.selectedProvider).suggestedModel;
        }
      }
      if (modelToSave.isNotEmpty) {
        await settings.saveAIModel(modelToSave);
      }

      final String? fallbackToSave;
      if (usesPresets) {
        fallbackToSave = state.fallbackModel == 'custom'
            ? customFallbackModel.trim()
            : state.fallbackModel;
      } else {
        final trimmed = customFallbackModel.trim();
        fallbackToSave = trimmed.isEmpty ? null : trimmed;
      }
      await settings.saveFallbackModel(fallbackToSave);

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

  Future<SyncResult> sync() async {
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

  // Only vision-capable models are listed — food logging supports photos, and
  // text-only models (e.g. DeepSeek, Nemotron) fail on image input.
  // Prices are shown per 100 logs (≈ a month of typical use) so they are easy
  // to picture; they come from the real average cost-per-call in the
  // OpenRouter activity log (2026-07-09, extended 2026-08-18 for the newer
  // entries) × 100. Accuracy is 100% minus the median calorie error %, from
  // test/benchmark_report/index.md of the food-benchmark run
  // (test/benchmark_ai.dart). Both are measured, not estimated.
  //
  // Ordered best-first by value — balancing accuracy, price, and speed —
  // so the top of the list is the smart default. 'custom' stays last.
  final List<AIModelInfo> availableModels = const [
    AIModelInfo(
      id: 'google/gemini-3.5-flash',
      name: 'Gemini 3.5 Flash',
      price: r'~$0.22 / 100 logs',
      accuracy: 96,
      description: 'Recommended default — fast, cheap, multilingual, and among the most accurate',
    ),
    AIModelInfo(
      id: 'google/gemini-3.7-flash',
      name: 'Gemini 3.7 Flash',
      price: r'~$0.14 / 100 logs',
      accuracy: 95,
      description: 'Good accuracy for the price, but ~3x slower than 3.5 Flash with no accuracy gain',
    ),
    AIModelInfo(
      id: 'google/gemini-3-flash-preview',
      name: 'Gemini 3 Flash',
      price: r'~$0.07 / 100 logs',
      accuracy: 93,
      description: 'Cheapest and fast, but 3.5 Flash is more accurate for a bit more',
    ),
    AIModelInfo(
      id: 'x-ai/grok-4.3',
      name: 'Grok 4.3',
      price: r'~$0.25 / 100 logs',
      accuracy: 95,
      description: 'Good accuracy at low cost, but slower than the Flash models',
    ),
    AIModelInfo(
      id: 'anthropic/claude-opus-4.8',
      name: 'Claude Opus 4.8',
      price: r'~$0.69 / 100 logs',
      accuracy: 95,
      description: 'Fast and accurate, but 3.5 Flash matches it for a third the price',
    ),
    AIModelInfo(
      id: 'anthropic/claude-sonnet-5',
      name: 'Claude Sonnet 5',
      price: r'~$0.41 / 100 logs',
      accuracy: 94,
      description: 'Solid all-rounder: mid cost, mid speed, good accuracy',
    ),
    AIModelInfo(
      id: 'openai/gpt-5.6-luna-pro',
      name: 'GPT-5.6 Luna Pro',
      price: r'~$0.23 / 100 logs',
      accuracy: 94,
      description: 'Matches Claude Sonnet 5\'s accuracy for near half the price, but the 2nd-slowest model here',
    ),
    AIModelInfo(
      id: 'openai/gpt-5.5',
      name: 'GPT-5.5',
      price: r'~$1.17 / 100 logs',
      accuracy: 96,
      description: 'Most accurate overall, but slow and expensive',
    ),
    AIModelInfo(
      id: 'google/gemini-3.1-pro-preview',
      name: 'Gemini 3.1 Pro',
      price: r'~$1.37 / 100 logs',
      accuracy: 95,
      description: 'Slow and pricey, with no accuracy gain over 3.5 Flash',
    ),
    AIModelInfo(
      id: 'openai/gpt-5.6-terra-pro',
      name: 'GPT-5.6 Terra Pro',
      price: r'~$1.70 / 100 logs',
      accuracy: 95,
      description: 'Same accuracy as much cheaper options — the priciest and among the slowest models here',
    ),
    AIModelInfo(
      id: 'minimax/minimax-m3',
      name: 'MiniMax M3',
      price: r'~$0.07 / 100 logs',
      accuracy: 93,
      description: 'Cheap, but slower and only middling accuracy with occasional large errors',
    ),
    AIModelInfo(
      id: 'openai/gpt-5.4-mini',
      name: 'GPT-5.4 Mini',
      price: r'~$0.09 / 100 logs',
      accuracy: 88,
      description: 'Very fast and cheap, but clearly the least accurate',
    ),
    AIModelInfo(
      id: 'google/gemma-4-31b-it',
      name: 'Gemma 4 31B',
      price: r'~$0.01 / 100 logs',
      accuracy: 89,
      description: 'Cheapest of all, but the least accurate — expect big misses on some foods',
    ),
    AIModelInfo(
      id: 'xiaomi/mimo-v2.5',
      name: 'MiMo V2.5',
      price: r'~$0.02 / 100 logs',
      accuracy: 88,
      description: 'Very cheap, but painfully slow (~30s/log) and among the least accurate',
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
