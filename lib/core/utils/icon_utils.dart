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
    'local_pizza': Icons.local_pizza,
    'icecream': Icons.icecream,
    'breakfast_dining': Icons.breakfast_dining,
    'lunch_dining': Icons.lunch_dining,
    'dinner_dining': Icons.dinner_dining,
    'set_meal': Icons.set_meal,
    'kebab_dining': Icons.kebab_dining,
    'soup_kitchen': Icons.soup_kitchen,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'wine_bar': Icons.wine_bar,
    'water_drop': Icons.water_drop,
    'emoji_food_beverage': Icons.emoji_food_beverage,
    'kitchen': Icons.kitchen,
    'local_grocery_store': Icons.local_grocery_store,
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
    'sports_baseball': Icons.sports_baseball,
    'sports_cricket': Icons.sports_cricket,
    'sports_football': Icons.sports_football,
    'sports_golf': Icons.sports_golf,
    'sports_hockey': Icons.sports_hockey,
    'sports_volleyball': Icons.sports_volleyball,
    'sports_mma': Icons.sports_mma,
    'sports_motorsports': Icons.sports_motorsports,
    'sports_rugby': Icons.sports_rugby,
    'surfing': Icons.surfing,
    'snowboarding': Icons.snowboarding,
    'skateboarding': Icons.skateboarding,
    'downhill_skiing': Icons.downhill_skiing,
    'kayaking': Icons.kayaking,
    'rowing': Icons.rowing,
    'scuba_diving': Icons.scuba_diving,
    'roller_skating': Icons.roller_skating,
    'kitesurfing': Icons.kitesurfing,
    'paragliding': Icons.paragliding,
  };

  static const Map<String, String> exerciseNameMap = {
    'Walking (Moderate)': 'directions_walk',
    'Running': 'directions_run',
    'Gym / Weights': 'fitness_center',
    'Calisthenics': 'sports_gymnastics',
    'Cycling': 'directions_bike',
    'Swimming': 'pool',
    'Yoga': 'self_improvement',
    'Elliptical': 'fitness_center',
    'Pilates': 'self_improvement',
    'Hiking': 'hiking',
    'Boxing / MMA': 'sports_mma',
    'Soccer': 'sports_soccer',
    'Basketball': 'sports_basketball',
    'Tennis': 'sports_tennis',
    'Football': 'sports_football',
    'Volleyball': 'sports_volleyball',
    'Golf': 'sports_golf',
    'Skiing': 'downhill_skiing',
    'Rowing': 'rowing',
    'Kayaking': 'kayaking',
    'Surfing': 'surfing',
    'Skating': 'roller_skating',
    'Baseball': 'sports_baseball',
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
