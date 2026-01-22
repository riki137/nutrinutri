import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/features/settings/presentation/settings_controller.dart';

class SettingsFormManager {
  final WidgetRef ref;
  final VoidCallback onStateChanged;

  final apiKeyController = TextEditingController();
  final customModelController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final goalController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatsController = TextEditingController();

  String _initialHash = '';

  SettingsFormManager({required this.ref, required this.onStateChanged}) {
    _apiKeyControllerListener();
    _setupCalorieListeners();
  }

  void _apiKeyControllerListener() {
    apiKeyController.addListener(onStateChanged);
  }

  void _setupCalorieListeners() {
    ageController.addListener(_calculateRecommendedCalories);
    weightController.addListener(_calculateRecommendedCalories);
    heightController.addListener(_calculateRecommendedCalories);
  }

  void dispose() {
    apiKeyController.dispose();
    customModelController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    goalController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatsController.dispose();
  }

  Future<void> loadSettings() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .loadSettings(
          onKeyLoaded: (key) => apiKeyController.text = key,
          onCustomModelLoaded: (model) => customModelController.text = model,
          onProfileLoaded: (profile) {
            ageController.text = profile['age']?.toString() ?? '';
            weightController.text = profile['weight']?.toString() ?? '';
            heightController.text = profile['height']?.toString() ?? '';
            goalController.text = profile['goalCalories']?.toString() ?? '';
            proteinController.text = profile['goalProtein']?.toString() ?? '';
            carbsController.text = profile['goalCarbs']?.toString() ?? '';
            fatsController.text = profile['goalFat']?.toString() ?? '';
          },
        );
    _initialHash = _computeHash();
    onStateChanged();
  }

  void _calculateRecommendedCalories() {
    final age = int.tryParse(ageController.text);
    final weight = double.tryParse(weightController.text);
    final height = double.tryParse(heightController.text);
    final state = ref.read(settingsControllerProvider);

    if (age != null && weight != null && height != null) {
      final calories = ref
          .read(settingsControllerProvider.notifier)
          .calculateDailyCalories(
            age: age,
            weight: weight,
            height: height,
            gender: state.gender,
            activityLevel: state.activityLevel,
          );
      goalController.text = calories.toString();
    }
  }

  Future<void> save() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .save(
          apiKey: apiKeyController.text,
          customModel: customModelController.text,
          age: ageController.text,
          weight: weightController.text,
          height: heightController.text,
          goalCalories: goalController.text,
          protein: proteinController.text,
          carbs: carbsController.text,
          fats: fatsController.text,
        );
    _initialHash = _computeHash();
    onStateChanged();
  }

  bool hasChanges() {
    return _initialHash != _computeHash();
  }

  String _computeHash() {
    final state = ref.read(settingsControllerProvider);
    return Object.hash(
      apiKeyController.text,
      state.selectedModel,
      customModelController.text,
      ageController.text,
      weightController.text,
      heightController.text,
      state.gender,
      state.activityLevel,
      goalController.text,
      proteinController.text,
      carbsController.text,
      fatsController.text,
    ).toString();
  }

  // Helper method to recalculate calories when gender/activity changes from UI
  void recalculateCalories() {
    _calculateRecommendedCalories();
  }
}
