import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/features/settings/presentation/settings_controller.dart';

class SettingsFormManager {
  SettingsFormManager({required this.ref, required this.onStateChanged}) {
    apiKeyController.addListener(onStateChanged);
    ageController.addListener(_calculateRecommendedCalories);
    weightController.addListener(_calculateRecommendedCalories);
    heightController.addListener(_calculateRecommendedCalories);
  }
  final WidgetRef ref;
  final VoidCallback onStateChanged;

  final apiKeyController = TextEditingController();
  final customModelController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final Map<NutritionMetricType, TextEditingController> _metricGoalControllers =
      {
        for (final metric in NutritionMetricType.values)
          metric: TextEditingController(),
      };

  TextEditingController get goalController =>
      _metricGoalControllers[NutritionMetricType.calories]!;

  Map<NutritionMetricType, TextEditingController> get metricGoalControllers =>
      _metricGoalControllers;

  String _initialHash = '';

  void dispose() {
    apiKeyController.dispose();
    customModelController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    for (final controller in _metricGoalControllers.values) {
      controller.dispose();
    }
  }

  Future<void> loadSettings() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .loadSettings(
          onKeyLoaded: (key) => apiKeyController.text = key,
          onCustomModelLoaded: (model) => customModelController.text = model,
          onProfileLoaded: (UserProfile profile) {
            ageController.text = profile.age.toString();
            weightController.text = profile.weightKg.toString();
            heightController.text = profile.heightCm.toString();
            goalController.text = _formatGoal(
              profile.goalFor(NutritionMetricType.calories),
            );

            for (final metric in NutritionMetricType.values) {
              if (metric == NutritionMetricType.calories) continue;
              final value = profile.metricGoals[metric];
              _metricGoalControllers[metric]!.text = value == null
                  ? ''
                  : _formatGoal(value);
            }
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
          calorieGoal: goalController.text,
          metricGoalInputs: {
            for (final entry in _metricGoalControllers.entries)
              if (entry.key != NutritionMetricType.calories)
                entry.key: entry.value.text,
          },
          homeMetricTypes: ref.read(settingsControllerProvider).homeMetricTypes,
        );
    _initialHash = _computeHash();
    onStateChanged();
  }

  bool hasChanges() {
    return _initialHash != _computeHash();
  }

  String _computeHash() {
    final state = ref.read(settingsControllerProvider);
    return Object.hashAll([
      apiKeyController.text,
      state.selectedModel,
      customModelController.text,
      ageController.text,
      weightController.text,
      heightController.text,
      state.gender,
      state.activityLevel,
      ...NutritionMetricType.values.map(
        (metric) => _metricGoalControllers[metric]!.text,
      ),
      ...state.homeMetricTypes,
    ]).toString();
  }

  // Helper method to recalculate calories when gender/activity changes from UI
  void recalculateCalories() {
    _calculateRecommendedCalories();
  }

  String _formatGoal(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}
