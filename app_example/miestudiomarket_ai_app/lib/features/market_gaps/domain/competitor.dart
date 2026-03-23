/// Domain model for a local competitor in the catalog.
// TODO: Refactor, what is this? entity? model?
class Competitor {
  final String id;
  final String name;
  final String category;
  final List<String> products;
  final String location;

  const Competitor({
    required this.id,
    required this.name,
    required this.category,
    required this.products,
    required this.location,
  });

  factory Competitor.fromFirestore(String id, Map<String, dynamic> data) {
    return Competitor(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      products: List<String>.from(data['products'] as List? ?? []),
      location: data['location'] as String? ?? '',
    );
  }
}
