class AIModelInfo {
  const AIModelInfo({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.tags = const [],
    this.accuracy,
  });
  final String id;
  final String name;
  final String price;
  final String description;
  final List<String> tags;

  /// Measured accuracy for calorie estimation, e.g. "96%". Derived from
  /// 100% minus the median calorie error % in test/benchmark_report. Null
  /// when the model hasn't been benchmarked.
  final int? accuracy;
}
