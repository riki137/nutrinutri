class MetValues {
  static const Map<String, double> commonExercises = {
    'Walking (Moderate)': 3.5,
    'Running': 9.8,
    'Cycling': 7.5,
    'Swimming': 6.0,
    'Gym / Weights': 5.0,
    'Yoga': 2.5,
    'Hiking': 6.0,
    'Basketball': 8.0,
    'Soccer': 10.0,
    'Tennis': 7.3,
  };

  static double getMet(String exerciseName) {
    return commonExercises[exerciseName] ??
        commonExercises.entries
            .firstWhere(
              (e) => e.key.toLowerCase().contains(exerciseName.toLowerCase()),
              orElse: () => const MapEntry('', 0.0),
            )
            .value;
  }
}
