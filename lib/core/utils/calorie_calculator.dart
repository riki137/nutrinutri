class CalorieCalculator {
  static const int _defaultDeficit = 250;

  /// Calculates Basal Metabolic Rate using Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  /// Calculates Total Daily Energy Expenditure
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'very_active':
        multiplier = 1.725;
        break;
      case 'super_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    return bmr * multiplier;
  }

  /// Calculates recommended daily calories for maintenance - deficit
  static int calculateDailyCalories({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    int deficit = _defaultDeficit,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    final tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel);
    return (tdee - deficit).round();
  }

  /// Default macro split: 30% Protein, 40% Carbs, 30% Fat
  static MacroGoals calculateMacroGoals(int totalCalories) {
    return MacroGoals(
      protein: (totalCalories * 0.30) / 4,
      carbs: (totalCalories * 0.40) / 4,
      fats: (totalCalories * 0.30) / 9,
    );
  }
}

class MacroGoals {
  final double protein;
  final double carbs;
  final double fats;

  const MacroGoals({
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}
