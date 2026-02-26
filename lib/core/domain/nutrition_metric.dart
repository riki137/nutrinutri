enum NutritionMetricType {
  calories,
  carbs,
  sugars,
  fats,
  saturatedFats,
  protein,
  fiber,
  sodium,
  caffeine,
  water,
}

const defaultHomeMetricTypes = <NutritionMetricType>[
  NutritionMetricType.carbs,
  NutritionMetricType.fats,
  NutritionMetricType.protein,
  NutritionMetricType.fiber,
  NutritionMetricType.caffeine,
  NutritionMetricType.water,
];

extension NutritionMetricTypeX on NutritionMetricType {
  String get key {
    switch (this) {
      case NutritionMetricType.calories:
        return 'calories';
      case NutritionMetricType.carbs:
        return 'carbs';
      case NutritionMetricType.sugars:
        return 'sugars';
      case NutritionMetricType.fats:
        return 'fats';
      case NutritionMetricType.saturatedFats:
        return 'saturated_fats';
      case NutritionMetricType.protein:
        return 'protein';
      case NutritionMetricType.fiber:
        return 'fiber';
      case NutritionMetricType.sodium:
        return 'sodium';
      case NutritionMetricType.caffeine:
        return 'caffeine';
      case NutritionMetricType.water:
        return 'water';
    }
  }

  String get label {
    switch (this) {
      case NutritionMetricType.calories:
        return 'Calories';
      case NutritionMetricType.carbs:
        return 'Carbs';
      case NutritionMetricType.sugars:
        return 'Sugars';
      case NutritionMetricType.fats:
        return 'Fats';
      case NutritionMetricType.saturatedFats:
        return 'Saturated Fats';
      case NutritionMetricType.protein:
        return 'Protein';
      case NutritionMetricType.fiber:
        return 'Fiber';
      case NutritionMetricType.sodium:
        return 'Sodium';
      case NutritionMetricType.caffeine:
        return 'Caffeine';
      case NutritionMetricType.water:
        return 'Water';
    }
  }

  String get unit {
    switch (this) {
      case NutritionMetricType.calories:
        return 'kcal';
      case NutritionMetricType.sodium:
      case NutritionMetricType.caffeine:
        return 'mg';
      case NutritionMetricType.water:
        return 'ml';
      default:
        return 'g';
    }
  }

  static NutritionMetricType? fromKey(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'calories':
      case 'kcal':
        return NutritionMetricType.calories;
      case 'carbs':
      case 'carb':
        return NutritionMetricType.carbs;
      case 'sugars':
      case 'sugar':
        return NutritionMetricType.sugars;
      case 'fats':
      case 'fat':
        return NutritionMetricType.fats;
      case 'saturated_fats':
      case 'saturatedfat':
      case 'saturated_fat':
      case 'saturatedfats':
        return NutritionMetricType.saturatedFats;
      case 'protein':
        return NutritionMetricType.protein;
      case 'fiber':
      case 'fibre':
        return NutritionMetricType.fiber;
      case 'sodium':
        return NutritionMetricType.sodium;
      case 'caffeine':
        return NutritionMetricType.caffeine;
      case 'water':
        return NutritionMetricType.water;
      default:
        return null;
    }
  }
}
