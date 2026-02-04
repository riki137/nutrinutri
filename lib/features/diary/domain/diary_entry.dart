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

  final String id;
  final String name;
  final EntryType type;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime timestamp;
  final String? imagePath;
  final String? icon;
  final FoodEntryStatus status;
  final String? description;
  final int? durationMinutes;
}

enum EntryType { food, exercise }

enum FoodEntryStatus { synced, processing, failed, cancelled }
