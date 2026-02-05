import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.initialHash,
    this.selectedModel = 'google/gemini-3-flash-preview',
    this.fallbackModel,
    this.gender = 'male',
    this.activityLevel = 'sedentary',
  });

  final bool isLoading;
  final bool isSyncing;
  final String? initialHash;
  final String selectedModel;
  final String gender;
  final String activityLevel;

  final String? fallbackModel;

  SettingsState copyWith({
    bool? isLoading,
    bool? isSyncing,
    String? initialHash,
    String? selectedModel,
    String? fallbackModel,
    String? gender,
    String? activityLevel,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      initialHash: initialHash ?? this.initialHash,
      selectedModel: selectedModel ?? this.selectedModel,
      fallbackModel: fallbackModel ?? this.fallbackModel,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
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

  Future<void> save({
    required String apiKey,
    required String customModel,
    required String age,
    required String weight,
    required String height,
    required String goalCalories,
    required String protein,
    required String carbs,
    required String fats,
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

      if (age.isNotEmpty &&
          weight.isNotEmpty &&
          height.isNotEmpty &&
          goalCalories.isNotEmpty) {
        await settings.saveUserProfile(
          age: int.parse(age),
          weight: double.parse(weight),
          height: double.parse(height),
          gender: state.gender,
          activityLevel: state.activityLevel,
          goalCalories: int.parse(goalCalories),
          goalProtein: int.tryParse(protein),
          goalCarbs: int.tryParse(carbs),
          goalFat: int.tryParse(fats),
        );
      }

      ref.invalidate(apiKeyProvider);
      ref.invalidate(aiServiceProvider);
    } finally {
      state = state.copyWith(isLoading: false);
    }
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

final unsavedSettingsChangesProvider = StateProvider<bool>((ref) => false);
