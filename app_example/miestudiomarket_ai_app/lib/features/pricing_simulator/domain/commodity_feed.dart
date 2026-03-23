/// Represents a raw material/commodity with its base market price.
class Commodity {
  final String id;
  final String name;
  final double price;
  final String unit;

  const Commodity({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
  });

  factory Commodity.fromMap(Map<String, dynamic> map) {
    return Commodity(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }
}

/// Represents the mock feed data returned by the backend.
class CommodityFeed {
  final List<Commodity> commodities;
  final DateTime lastUpdated;

  const CommodityFeed({
    required this.commodities,
    required this.lastUpdated,
  });

  factory CommodityFeed.fromMap(Map<String, dynamic> map) {
    return CommodityFeed(
      commodities: (map['commodities'] as List<dynamic>)
          .map((e) => Commodity.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}
