import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/services/device_id_service.dart';
import 'package:nutrinutri/core/services/sync_service.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';

void main() {
  late AppDatabase db;
  late DiaryService diaryService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    diaryService = DiaryService(
      db,
      DeviceIdService(db),
      SyncService(db: db),
    );
  });

  tearDown(() => db.close());

  test('buckets totals by local day, zeroes empty days, routes exercise '
      'calories to caloriesBurned, matches getSummary', () async {
    final day1 = DateTime(2026, 3, 10);
    final day2 = DateTime(2026, 3, 11);
    final day3 = DateTime(2026, 3, 12); // left empty

    await diaryService.addEntry(
      DiaryEntry(
        id: 'food-1',
        name: 'Oats',
        type: EntryType.food,
        timestamp: day1.add(const Duration(hours: 8)),
        metrics: const {
          NutritionMetricType.calories: 300,
          NutritionMetricType.carbs: 50,
        },
      ),
    );
    await diaryService.addEntry(
      DiaryEntry(
        id: 'exercise-1',
        name: 'Run',
        type: EntryType.exercise,
        timestamp: day2.add(const Duration(hours: 18)),
        metrics: const {NutritionMetricType.calories: 400},
      ),
    );

    final totals = await diaryService.getDailyTotals(day1, day3);

    expect(totals.keys.toSet(), {day1, day2, day3});
    expect(totals[day1]![NutritionMetricType.calories.key], 300);
    expect(totals[day1]![NutritionMetricType.carbs.key], 50);
    expect(totals[day2]![NutritionMetricType.calories.key], 0);
    expect(totals[day2]!['caloriesBurned'], 400);
    expect(
      totals[day3]!.values.every((v) => v == 0),
      isTrue,
      reason: 'day with no entries should be zeroed, not missing',
    );

    final summary1 = await diaryService.getSummary(day1);
    expect(summary1, totals[day1]);
  });
}
