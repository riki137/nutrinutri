import 'package:intl/intl.dart';
import 'package:nutrinutri/core/services/kv_store.dart';
import 'package:uuid/uuid.dart';

class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime timestamp;
  final String? imagePath; // Base64 or local path

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
    id: json['id'],
    name: json['name'],
    calories: json['calories'],
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fats: (json['fats'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    imagePath: json['imagePath'],
  );
}

class DiaryService {
  final KVStore _kv;
  static const String _collectionPrefix = 'diary_';

  DiaryService(this._kv);

  String _getDateKey(DateTime date) {
    return '$_collectionPrefix${DateFormat("yyyy-MM-dd").format(date)}';
  }

  Future<List<FoodEntry>> getEntriesForDate(DateTime date) async {
    final key = _getDateKey(date);
    final data = await _kv.get(key);
    if (data == null) return [];

    final List<dynamic> entriesJson = data['entries'];
    return entriesJson.map((e) => FoodEntry.fromJson(e)).toList();
  }

  Future<void> addEntry(FoodEntry entry) async {
    final key = _getDateKey(entry.timestamp);
    final currentEntries = await getEntriesForDate(entry.timestamp);

    currentEntries.add(entry);

    await _kv.put(key, {
      'entries': currentEntries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> deleteEntry(FoodEntry entry) async {
    final key = _getDateKey(entry.timestamp);
    final currentEntries = await getEntriesForDate(entry.timestamp);

    await _kv.put(key, {
      'entries': currentEntries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> updateEntry(FoodEntry entry) async {
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
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    for (var e in entries) {
      calories += e.calories;
      protein += e.protein;
      carbs += e.carbs;
      fats += e.fats;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}
