class MetValues {
  static const Map<String, double> commonExercises = {
    'Walking (Moderate)': 3.5,
    'Running': 9.8,
    'Gym / Weights': 5.0,
    'Cycling': 7.5,
    'Swimming': 6.0,
    'Yoga': 2.5,
    'Elliptical': 5.0,
    'Pilates': 3.0,
    'Hiking': 6.0,
    'Calisthenics': 4.5,
    'Boxing / MMA': 9.0, // General sparring/bag work
    'Soccer': 10.0,
    'Basketball': 8.0,
    'Tennis': 7.3,
    'Football': 8.0, // Competitive
    'Volleyball': 4.0, // Recreational
    'Golf': 4.8, // Walking, carrying clubs
    'Skiing': 7.0, // Downhill moderate
    'Rowing': 7.0, // Moderate effort
    'Kayaking': 5.0,
    'Surfing': 4.0, // Body or board
    'Skating': 5.5, // Roller skating moderate
    'Baseball': 5.0,
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
