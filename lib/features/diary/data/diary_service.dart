import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/services/device_id_service.dart';
import 'package:nutrinutri/core/services/sync_service.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';

class DiaryService {
  DiaryService(this._db, this._deviceId, this._syncService);
  final AppDatabase _db;
  final DeviceIdService _deviceId;
  final SyncService _syncService;

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

  Future<Map<String, Map<NutritionMetricType, double>>> _loadMetricsByEntryId(
    List<String> entryIds,
  ) async {
    if (entryIds.isEmpty) return const {};

    final rows = await (_db.select(
      _db.entryMetrics,
    )..where((t) => t.entryId.isIn(entryIds))).get();

    final metricsByEntryId = <String, Map<NutritionMetricType, double>>{};
    for (final row in rows) {
      if (row.type < 0 || row.type >= NutritionMetricType.values.length) {
        continue;
      }

      final metricType = NutritionMetricType.values[row.type];
      metricsByEntryId.putIfAbsent(
        row.entryId,
        () => <NutritionMetricType, double>{},
      )[metricType] = _roundMetricValue(
        row.value,
      );
    }
    return metricsByEntryId;
  }

  Future<void> _replaceMetrics(
    String entryId,
    Map<NutritionMetricType, double> metrics,
  ) async {
    final nextMetrics = <NutritionMetricType, double>{};
    for (final metric in NutritionMetricType.values) {
      final raw = metrics[metric] ?? 0;
      final value = _roundMetricValue(raw);
      if (!value.isFinite) continue;
      if (metric != NutritionMetricType.calories && value == 0) {
        continue;
      }
      nextMetrics[metric] = value;
    }
    nextMetrics.putIfAbsent(NutritionMetricType.calories, () => 0);

    await (_db.delete(
      _db.entryMetrics,
    )..where((t) => t.entryId.equals(entryId))).go();

    if (nextMetrics.isEmpty) return;

    final companions = nextMetrics.entries
        .map(
          (entry) => EntryMetricsCompanion.insert(
            entryId: entryId,
            type: entry.key.index,
            value: entry.value,
          ),
        )
        .toList(growable: false);

    await _db.batch((batch) {
      batch.insertAll(_db.entryMetrics, companions);
    });
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

    final metricsByEntryId = await _loadMetricsByEntryId(
      rows.map((row) => row.id).toList(growable: false),
    );

    return rows
        .map(
          (row) => _toDomain(
            row,
            metricsByEntryId[row.id] ?? const <NutritionMetricType, double>{},
          ),
        )
        .toList(growable: false);
  }

  Future<void> addEntry(DiaryEntry entry) async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db
          .into(_db.diaryEntries)
          .insert(
            _entryCompanion(
              entry,
              deviceId: deviceId,
              now: now,
              includeId: true,
            ),
            mode: InsertMode.insertOrReplace,
          );
      await _replaceMetrics(entry.id, entry.metrics);
    });
    unawaited(_syncService.requestSync());
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.update(
        _db.diaryEntries,
      )..where((t) => t.id.equals(entry.id))).write(
        _entryCompanion(entry, deviceId: deviceId, now: now, includeId: false),
      );
      await _replaceMetrics(entry.id, entry.metrics);
    });
    unawaited(_syncService.requestSync());
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    final deviceId = await _deviceId.getOrCreate();
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.diaryEntries)..where((t) => t.id.equals(entry.id)))
        .write(_entryDeleteCompanion(deviceId: deviceId, now: now));
    unawaited(_syncService.requestSync());
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

    final metricsByEntryId = await _loadMetricsByEntryId(
      rows.map((row) => row.id).toList(growable: false),
    );

    final summary = <String, double>{
      for (final metric in NutritionMetricType.values) metric.key: 0,
      'caloriesBurned': 0,
    };

    for (final row in rows) {
      final metrics =
          metricsByEntryId[row.id] ?? const <NutritionMetricType, double>{};

      if (row.type == EntryType.exercise.index) {
        summary['caloriesBurned'] =
            (summary['caloriesBurned'] ?? 0) +
            (metrics[NutritionMetricType.calories] ?? 0);
        continue;
      }

      for (final metric in NutritionMetricType.values) {
        summary[metric.key] =
            (summary[metric.key] ?? 0) + (metrics[metric] ?? 0);
      }
    }

    return summary;
  }

  Future<List<DiaryEntry>> searchEntrySuggestions(
    String query, {
    required EntryType type,
  }) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final t = _db.diaryEntries;
    final table = t.actualTableName;
    final idCol = t.id.$name;
    final nameCol = t.name.$name;
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
  $idCol AS id,
  $nameCol AS name,
  $descriptionCol AS description,
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

    final entryIds = rows
        .map((row) => row.read<String>('id'))
        .toList(growable: false);
    final metricsByEntryId = await _loadMetricsByEntryId(entryIds);

    final seen = <String>{};
    final results = <DiaryEntry>[];
    for (final row in rows) {
      final id = row.read<String>('id');
      final name = row.read<String>('name');
      final description = row.readNullable<String>('description');

      final suggestionText = (description?.trim().isNotEmpty == true)
          ? description!.trim()
          : name;
      final suggestionKey = _normalize(suggestionText);

      if (seen.add(suggestionKey)) {
        results.add(
          DiaryEntry(
            id: '',
            name: name,
            metrics:
                metricsByEntryId[id] ?? const {NutritionMetricType.calories: 0},
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

  DiaryEntry _toDomain(
    DiaryEntryRow row,
    Map<NutritionMetricType, double> metrics,
  ) {
    return DiaryEntry(
      id: row.id,
      name: row.name,
      type: EntryType.values[row.type],
      metrics: metrics,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestamp),
      imagePath: row.imagePath,
      icon: row.icon,
      status: FoodEntryStatus.values[row.status],
      description: row.description,
      durationMinutes: row.durationMinutes,
    );
  }

  double _roundMetricValue(double value) {
    return (value * 10).roundToDouble() / 10;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
