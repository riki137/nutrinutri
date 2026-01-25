import 'package:intl/intl.dart';
import 'package:nutrinutri/core/services/kv_store.dart';
import 'package:nutrinutri/core/services/food_index_service.dart';

enum EntryType { food, exercise }

enum FoodEntryStatus { synced, processing, failed, cancelled }

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.name,
    this.type = EntryType.food,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    required this.timestamp,
    this.imagePath,
    this.icon,
    this.status = FoodEntryStatus.synced,
    this.description,
    this.durationMinutes,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'],
    name: json['name'],
    type: json['type'] != null
        ? EntryType.values[json['type']]
        : EntryType.food,
    calories: json['calories'],
    protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
    carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
    fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(json['timestamp']),
    imagePath: json['imagePath'],
    icon: json['icon'],
    status: json['status'] != null
        ? FoodEntryStatus.values[json['status']]
        : FoodEntryStatus.synced,
    description: json['description'],
    durationMinutes: json['durationMinutes'],
  );
  final String id;
  final String name;
  final EntryType type;
  final int
  calories; // Consumed (positive) or Burned (positive value, treated as credit)
  final double protein;
  final double carbs;
  final double fats;
  final DateTime timestamp;
  final String? imagePath; // Base64 or local path
  final String? icon;
  final FoodEntryStatus status;
  final String? description;
  final int? durationMinutes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
    'icon': icon,
    'status': status.index,
    'description': description,
    'durationMinutes': durationMinutes,
  };
}

class DiaryService {
  DiaryService(this._kv, this._foodIndex);
  final KVStore _kv;
  final FoodIndexService _foodIndex;
  static const String _collectionPrefix = 'diary_';

  String _getDateKey(DateTime date) {
    return '$_collectionPrefix${DateFormat("yyyy-MM-dd").format(date)}';
  }

  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) async {
    final key = _getDateKey(date);
    final data = await _kv.get(key);
    if (data == null) return [];

    final List<dynamic> entriesJson = data['entries'];
    final entries = entriesJson.map((e) => DiaryEntry.fromJson(e)).toList();
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return entries;
  }

  Future<void> addEntry(DiaryEntry entry) async {
    final key = _getDateKey(entry.timestamp);
    final currentEntries = await getEntriesForDate(entry.timestamp);

    currentEntries.add(entry);

    await _kv.put(key, {
      'entries': currentEntries.map((e) => e.toJson()).toList(),
    });

    if (entry.type == EntryType.food) {
      await _foodIndex.indexEntry(entry);
    }
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    final key = _getDateKey(entry.timestamp);
    final currentEntries = await getEntriesForDate(entry.timestamp);

    currentEntries.removeWhere((e) => e.id == entry.id);

    await _kv.put(key, {
      'entries': currentEntries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    final key = _getDateKey(entry.timestamp);
    final currentEntries = await getEntriesForDate(entry.timestamp);

    final index = currentEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      currentEntries[index] = entry;
      await _kv.put(key, {
        'entries': currentEntries.map((e) => e.toJson()).toList(),
      });
    }
  }

  /// Get summary for a date
  Future<Map<String, double>> getSummary(DateTime date) async {
    final entries = await getEntriesForDate(date);
    double caloriesConsumed = 0;
    double caloriesBurned = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    for (var e in entries) {
      if (e.type == EntryType.exercise) {
        caloriesBurned += e.calories;
      } else {
        caloriesConsumed += e.calories;
        protein += e.protein;
        carbs += e.carbs;
        fats += e.fats;
      }
    }

    return {
      'calories': caloriesConsumed, // Consumed
      'caloriesBurned': caloriesBurned, // Burned
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}
