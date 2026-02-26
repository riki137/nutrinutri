import 'package:nutrinutri/core/domain/nutrition_metric.dart';

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.name,
    this.type = EntryType.food,
    Map<NutritionMetricType, double>? metrics,
    required this.timestamp,
    this.imagePath,
    this.icon,
    this.status = FoodEntryStatus.synced,
    this.description,
    this.durationMinutes,
  }) : metrics = Map.unmodifiable(metrics ?? const {});

  final String id;
  final String name;
  final EntryType type;
  final Map<NutritionMetricType, double> metrics;
  final DateTime timestamp;
  final String? imagePath;
  final String? icon;
  final FoodEntryStatus status;
  final String? description;
  final int? durationMinutes;

  double metricValue(NutritionMetricType type) {
    return metrics[type] ?? 0;
  }

  double get calories => metricValue(NutritionMetricType.calories);
  double get protein => metricValue(NutritionMetricType.protein);
  double get carbs => metricValue(NutritionMetricType.carbs);
  double get fats => metricValue(NutritionMetricType.fats);
}

enum EntryType { food, exercise }

enum FoodEntryStatus { synced, processing, failed, cancelled }
