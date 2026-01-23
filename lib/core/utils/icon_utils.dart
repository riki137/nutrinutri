import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, IconData> foodIcons = {
    'bakery_dining': Icons.bakery_dining,
    'brunch_dining': Icons.brunch_dining,
    'bento': Icons.bento,
    'cake': Icons.cake,
    'coffee': Icons.coffee,
    'cookie': Icons.cookie,
    'egg_alt': Icons.egg_alt,
    'fastfood': Icons.fastfood,
    'flatware': Icons.flatware,
    'liquor': Icons.liquor,
    'microwave': Icons.microwave,
    'nightlife': Icons.nightlife,
    'outdoor_grill': Icons.outdoor_grill,
    'ramen_dining': Icons.ramen_dining,
    'restaurant': Icons.restaurant,
    'rice_bowl': Icons.rice_bowl,
    'sports_bar': Icons.sports_bar,
    'tapas': Icons.tapas,
  };

  static const Map<String, IconData> exerciseIcons = {
    'directions_run': Icons.directions_run,
    'directions_walk': Icons.directions_walk,
    'directions_bike': Icons.directions_bike,
    'pool': Icons.pool,
    'fitness_center': Icons.fitness_center,
    'self_improvement': Icons.self_improvement,
    'hiking': Icons.hiking,
    'sports_basketball': Icons.sports_basketball,
    'sports_soccer': Icons.sports_soccer,
    'sports_tennis': Icons.sports_tennis,
    'sports_gymnastics': Icons.sports_gymnastics,
    'sports': Icons.sports,
  };

  static const Map<String, String> exerciseNameMap = {
    'Walking (Moderate)': 'directions_walk',
    'Running': 'directions_run',
    'Cycling': 'directions_bike',
    'Swimming': 'pool',
    'Gym / Weights': 'fitness_center',
    'Yoga': 'self_improvement',
    'Hiking': 'hiking',
    'Basketball': 'sports_basketball',
    'Soccer': 'sports_soccer',
    'Tennis': 'sports_tennis',
  };

  static const Map<String, IconData> otherIcons = {
    'warning': Icons.warning_amber_rounded,
  };

  static Map<String, IconData> get iconMap => {
    ...foodIcons,
    ...exerciseIcons,
    ...otherIcons,
  };

  static List<String> get availableIcons => iconMap.keys.toList();
  static List<String> get availableFoodIcons => foodIcons.keys.toList();
  static List<String> get availableExerciseIcons => exerciseIcons.keys.toList();

  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.fastfood;
    return iconMap[iconName] ?? Icons.fastfood;
  }
}
