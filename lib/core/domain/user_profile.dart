class UserProfile {
  const UserProfile({
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.goalCalories,
    this.goalProtein,
    this.goalCarbs,
    this.goalFat,
    required this.isConfigured,
  });

  final int age;
  final double weightKg;
  final double heightCm;
  final String gender;
  final String activityLevel;
  final int goalCalories;
  final int? goalProtein;
  final int? goalCarbs;
  final int? goalFat;
  final bool isConfigured;
}
