import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';

/// Builds an in-memory database seeded with a configured profile and a full,
/// realistic day of entries, so the dashboard rings and entry list render
/// populated for the screenshots. Because a configured profile exists, the
/// router treats onboarding as complete and stays on the dashboard.
Future<AppDatabase> buildSeededDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final now = DateTime.now();
  DateTime at(int hour, int minute) =>
      DateTime(now.year, now.month, now.day, hour, minute);

  await db
      .into(db.userProfiles)
      .insert(
        UserProfilesCompanion.insert(
          id: const Value(1),
          age: 29,
          weightKg: 74,
          heightCm: 178,
          gender: 'male',
          activityLevel: 'moderate',
          isConfigured: const Value(true),
          updatedBy: const Value('screenshots'),
        ),
      );

  const goals = <NutritionMetricType, double>{
    NutritionMetricType.calories: 2200,
    NutritionMetricType.carbs: 250,
    NutritionMetricType.fats: 70,
    NutritionMetricType.protein: 140,
    NutritionMetricType.fiber: 30,
    NutritionMetricType.caffeine: 400,
    NutritionMetricType.water: 2500,
  };
  await db.batch((batch) {
    batch.insertAll(db.metricGoals, [
      for (final goal in goals.entries)
        MetricGoalsCompanion.insert(
          profileId: 1,
          type: goal.key.index,
          value: goal.value,
        ),
    ]);
  });

  await _addEntry(
    db,
    at(7, 15),
    'Morning Run',
    'directions_run',
    type: EntryType.exercise,
    durationMinutes: 35,
    metrics: {NutritionMetricType.calories: 340},
  );
  await _addEntry(
    db,
    at(8, 10),
    'Greek Yogurt, Berries & Granola',
    'breakfast_dining',
    metrics: {
      NutritionMetricType.calories: 320,
      NutritionMetricType.carbs: 42,
      NutritionMetricType.sugars: 22,
      NutritionMetricType.fats: 9,
      NutritionMetricType.saturatedFats: 4,
      NutritionMetricType.protein: 18,
      NutritionMetricType.fiber: 5,
      NutritionMetricType.sodium: 90,
    },
  );
  await _addEntry(
    db,
    at(8, 20),
    'Flat White',
    'local_cafe',
    metrics: {
      NutritionMetricType.calories: 120,
      NutritionMetricType.carbs: 10,
      NutritionMetricType.sugars: 9,
      NutritionMetricType.fats: 6,
      NutritionMetricType.saturatedFats: 4,
      NutritionMetricType.protein: 7,
      NutritionMetricType.caffeine: 130,
      NutritionMetricType.sodium: 80,
    },
  );
  await _addEntry(
    db,
    at(10, 30),
    'Water',
    'water_drop',
    metrics: {NutritionMetricType.water: 1800},
  );
  await _addEntry(
    db,
    at(12, 45),
    'Grilled Chicken & Quinoa Bowl',
    'rice_bowl',
    metrics: {
      NutritionMetricType.calories: 560,
      NutritionMetricType.carbs: 55,
      NutritionMetricType.fats: 18,
      NutritionMetricType.saturatedFats: 4,
      NutritionMetricType.protein: 42,
      NutritionMetricType.fiber: 8,
      NutritionMetricType.sodium: 520,
    },
  );
  await _addEntry(
    db,
    at(15, 30),
    'Apple & Almonds',
    'cookie',
    metrics: {
      NutritionMetricType.calories: 210,
      NutritionMetricType.carbs: 24,
      NutritionMetricType.sugars: 15,
      NutritionMetricType.fats: 12,
      NutritionMetricType.saturatedFats: 1,
      NutritionMetricType.protein: 5,
      NutritionMetricType.fiber: 5,
      NutritionMetricType.sodium: 5,
    },
  );
  await _addEntry(
    db,
    at(19, 20),
    'Salmon, Sweet Potato & Broccoli',
    'dinner_dining',
    metrics: {
      NutritionMetricType.calories: 620,
      NutritionMetricType.carbs: 45,
      NutritionMetricType.fats: 20,
      NutritionMetricType.saturatedFats: 5,
      NutritionMetricType.protein: 46,
      NutritionMetricType.fiber: 9,
      NutritionMetricType.sodium: 640,
    },
  );

  return db;
}

Future<void> _addEntry(
  AppDatabase db,
  DateTime timestamp,
  String name,
  String icon, {
  EntryType type = EntryType.food,
  int? durationMinutes,
  required Map<NutritionMetricType, double> metrics,
}) async {
  final id = 'seed-${timestamp.millisecondsSinceEpoch}';
  await db
      .into(db.diaryEntries)
      .insert(
        DiaryEntriesCompanion.insert(
          id: id,
          name: name,
          type: type.index,
          timestamp: timestamp.millisecondsSinceEpoch,
          normalizedName: name.trim().toLowerCase(),
          icon: Value(icon),
          durationMinutes: Value(durationMinutes),
          updatedBy: const Value('screenshots'),
        ),
      );
  await db.batch((batch) {
    batch.insertAll(db.entryMetrics, [
      for (final metric in metrics.entries)
        EntryMetricsCompanion.insert(
          entryId: id,
          type: metric.key.index,
          value: metric.value,
        ),
    ]);
  });
}
