import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/utils/calorie_calculator.dart';

class UserProfile {
  const UserProfile({
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.metricGoals,
    required this.homeMetricTypes,
    required this.isConfigured,
  });

  final int age;
  final double weightKg;
  final double heightCm;
  final String gender;
  final String activityLevel;
  final Map<NutritionMetricType, double> metricGoals;
  final List<NutritionMetricType> homeMetricTypes;
  final bool isConfigured;

  double get calorieGoal => metricGoals[NutritionMetricType.calories] ?? 0;

  double goalFor(NutritionMetricType type) {
    final explicit = metricGoals[type];
    if (explicit != null && explicit > 0) {
      return explicit;
    }

    final defaults = CalorieCalculator.calculateMacroGoals(calorieGoal.round());
    switch (type) {
      case NutritionMetricType.calories:
        return calorieGoal;
      case NutritionMetricType.carbs:
        return defaults.carbs;
      case NutritionMetricType.fats:
        return defaults.fats;
      case NutritionMetricType.protein:
        return defaults.protein;
      case NutritionMetricType.fiber:
        return 30;
      case NutritionMetricType.sodium:
        return 2300;
      case NutritionMetricType.sugars:
        return 50;
      case NutritionMetricType.saturatedFats:
        return 20;
      case NutritionMetricType.caffeine:
        return 400;
      case NutritionMetricType.water:
        return 2000;
    }
  }

  List<NutritionMetricType> get dashboardMetricTypes {
    final result = <NutritionMetricType>[];
    for (final type in homeMetricTypes) {
      if (type == NutritionMetricType.calories || result.contains(type)) {
        continue;
      }
      result.add(type);
    }

    for (final type in defaultHomeMetricTypes) {
      if (!result.contains(type)) {
        result.add(type);
      }
    }

    return result.take(6).toList(growable: false);
  }
}
