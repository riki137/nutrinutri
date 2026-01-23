class AIModelInfo {

  const AIModelInfo({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.tags = const [],
  });
  final String id;
  final String name;
  final String price;
  final String description;
  final List<String> tags;
}
