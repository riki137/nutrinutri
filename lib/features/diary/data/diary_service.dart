import 'package:drift/drift.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/services/device_id_service.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';

class DiaryService {
  DiaryService(this._db, this._deviceId);
  final AppDatabase _db;
  final DeviceIdService _deviceId;

  ({int startMs, int endMsInclusive}) _dayBounds(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final endExclusive = start.add(const Duration(days: 1));
    return (
      startMs: start.millisecondsSinceEpoch,
      endMsInclusive: endExclusive.millisecondsSinceEpoch - 1,
    );
  }

  DiaryEntriesCompanion _entryCompanion(
    DiaryEntry entry, {
    required String deviceId,
    required int now,
    required bool includeId,
  }) {
    final normalizedName = _normalize(entry.name);
    return DiaryEntriesCompanion(
      id: includeId ? Value(entry.id) : const Value.absent(),
      name: Value(entry.name),
      type: Value(entry.type.index),
      calories: Value(entry.calories),
      protein: Value(entry.protein),
      carbs: Value(entry.carbs),
      fats: Value(entry.fats),
      timestamp: Value(entry.timestamp.millisecondsSinceEpoch),
      normalizedName: Value(normalizedName),
      imagePath: Value(entry.imagePath),
      icon: Value(entry.icon),
      status: Value(entry.status.index),
      description: Value(entry.description),
      durationMinutes: Value(entry.durationMinutes),
      updatedAt: Value(now),
      updatedBy: Value(deviceId),
      deletedAt: const Value(null),
    );
  }

  DiaryEntriesCompanion _entryDeleteCompanion({
    required String deviceId,
    required int now,
  }) {
    return DiaryEntriesCompanion(
      updatedAt: Value(now),
      updatedBy: Value(deviceId),
      deletedAt: Value(now),
    );
  }

  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) async {
    final bounds = _dayBounds(date);

    final rows =
        await (_db.select(_db.diaryEntries)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.timestamp.isBetweenValues(
                      bounds.startMs,
                      bounds.endMsInclusive,
                    ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  Future<void> addEntry(DiaryEntry entry) async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db
        .into(_db.diaryEntries)
        .insert(
          _entryCompanion(entry, deviceId: deviceId, now: now, includeId: true),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(
      _db.diaryEntries,
    )..where((t) => t.id.equals(entry.id))).write(
      _entryCompanion(entry, deviceId: deviceId, now: now, includeId: false),
    );
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.diaryEntries)..where((t) => t.id.equals(entry.id)))
        .write(_entryDeleteCompanion(deviceId: deviceId, now: now));
  }

  Future<Map<String, double>> getSummary(DateTime date) async {
    final bounds = _dayBounds(date);

    final rows =
        await (_db.select(_db.diaryEntries)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.timestamp.isBetweenValues(
                    bounds.startMs,
                    bounds.endMsInclusive,
                  ),
            ))
            .get();

    double caloriesConsumed = 0;
    double caloriesBurned = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    for (final row in rows) {
      if (row.type == EntryType.exercise.index) {
        caloriesBurned += row.calories.toDouble();
      } else {
        caloriesConsumed += row.calories.toDouble();
        protein += row.protein;
        carbs += row.carbs;
        fats += row.fats;
      }
    }

    return {
      'calories': caloriesConsumed,
      'caloriesBurned': caloriesBurned,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  Future<List<DiaryEntry>> searchEntrySuggestions(
    String query, {
    required EntryType type,
  }) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final t = _db.diaryEntries;
    final table = t.actualTableName;
    final nameCol = t.name.$name;
    final caloriesCol = t.calories.$name;
    final proteinCol = t.protein.$name;
    final carbsCol = t.carbs.$name;
    final fatsCol = t.fats.$name;
    final iconCol = t.icon.$name;
    final descriptionCol = t.description.$name;
    final normalizedNameCol = t.normalizedName.$name;
    final deletedAtCol = t.deletedAt.$name;
    final typeCol = t.type.$name;
    final statusCol = t.status.$name;
    final updatedAtCol = t.updatedAt.$name;

    final rows = await _db
        .customSelect(
          '''
SELECT
  $nameCol AS name,
  $descriptionCol AS description,
  $caloriesCol AS calories,
  $proteinCol AS protein,
  $carbsCol AS carbs,
  $fatsCol AS fats,
  $iconCol AS icon,
  $normalizedNameCol AS normalizedName
FROM $table
WHERE $deletedAtCol IS NULL
  AND $typeCol = ?
  AND $statusCol = ?
  AND (
    $normalizedNameCol LIKE ?
    OR LOWER(COALESCE($descriptionCol, '')) LIKE ?
  )
ORDER BY $updatedAtCol DESC
LIMIT 200
''',
          variables: [
            Variable.withInt(type.index),
            Variable.withInt(FoodEntryStatus.synced.index),
            Variable.withString('%$normalizedQuery%'),
            Variable.withString('%$normalizedQuery%'),
          ],
          readsFrom: {t},
        )
        .get();

    final seen = <String>{};
    final results = <DiaryEntry>[];
    for (final row in rows) {
      final name = row.read<String>('name');
      final description = row.readNullable<String>('description');

      final suggestionText =
          (description?.trim().isNotEmpty == true) ? description!.trim() : name;
      final suggestionKey = _normalize(suggestionText);

      if (seen.add(suggestionKey)) {
        results.add(
          DiaryEntry(
            id: '',
            name: name,
            calories: row.read<int>('calories'),
            protein: row.read<double>('protein'),
            carbs: row.read<double>('carbs'),
            fats: row.read<double>('fats'),
            timestamp: DateTime.now(),
            type: type,
            icon: row.readNullable<String>('icon'),
            description: description,
          ),
        );
      }

      if (results.length >= 20) break;
    }

    return results;
  }

  DiaryEntry _toDomain(DiaryEntryRow row) {
    return DiaryEntry(
      id: row.id,
      name: row.name,
      type: EntryType.values[row.type],
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fats: row.fats,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestamp),
      imagePath: row.imagePath,
      icon: row.icon,
      status: FoodEntryStatus.values[row.status],
      description: row.description,
      durationMinutes: row.durationMinutes,
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
