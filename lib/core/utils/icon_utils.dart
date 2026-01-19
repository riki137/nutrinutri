import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, IconData> iconMap = {
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

  static List<String> get availableIcons => iconMap.keys.toList();

  static IconData getIcon(String? iconName) {
    return iconMap[iconName] ?? Icons.fastfood;
  }
}
