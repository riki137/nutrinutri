import 'package:nutrinutri/core/services/kv_store.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';

class FoodIndexService {
  final KVStore _kv;
  static const String _indexKey = 'local_food_index';

  // Map of normalized name -> Entry Data
  Map<String, Map<String, dynamic>> _index = {};
  bool _initialized = false;

  FoodIndexService(this._kv);

  Future<void> init() async {
    if (_initialized) return;
    final data = await _kv.get(_indexKey);
    if (data != null && data['index'] != null) {
      try {
        final Map<String, dynamic> rawIndex = data['index'];
        _index = rawIndex.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
      } catch (e) {
        // Fallback or error handling
        _index = {};
      }
    }
    _initialized = true;
  }

  Future<void> indexEntry(DiaryEntry entry) async {
    if (entry.type != EntryType.food) return;
    if (!_initialized) await init();

    final normalizedName = entry.name.trim().toLowerCase();
    if (normalizedName.isEmpty) return;

    // Store minified version to save space
    _index[normalizedName] = {
      'name': entry.name, // Keep original casing
      'calories': entry.calories,
      'protein': entry.protein,
      'carbs': entry.carbs,
      'fats': entry.fats,
      'icon': entry.icon,
    };

    // Save async
    // TODO: Consider debouncing if this becomes frequent
    await _kv.put(_indexKey, {'index': _index});
  }

  Future<List<DiaryEntry>> search(String query) async {
    if (!_initialized) await init();
    if (query.isEmpty) return [];

    final normalizedQuery = query.trim().toLowerCase();

    // Simple substring match
    // Filter values where key contains query
    // Limit to 20 results for performance
    final matches = _index.entries
        .where((e) => e.key.contains(normalizedQuery))
        .take(20)
        .map((e) {
          final data = e.value;
          return DiaryEntry(
            id: '', // Dummy ID
            name: data['name'],
            calories: (data['calories'] as num).toInt(),
            protein: (data['protein'] as num).toDouble(),
            carbs: (data['carbs'] as num).toDouble(),
            fats: (data['fats'] as num).toDouble(),
            timestamp: DateTime.now(), // Dummy timestamp
            type: EntryType.food,
            icon: data['icon'],
          );
        })
        .toList();

    return matches;
  }
}
