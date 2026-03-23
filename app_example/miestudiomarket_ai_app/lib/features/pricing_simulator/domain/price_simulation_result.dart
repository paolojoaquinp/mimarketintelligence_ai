/// Represents the traffic light margin status for AC3.
enum MarginTrafficLight { green, yellow, red }

/// Result of a pricing simulation from the AI Backend.
class PriceSimulationResult {
  final String productName;
  final double userBaseCost;
  final double userSalePrice;
  final double marketAveragePrice;
  final double marginPercentage;
  final MarginTrafficLight trafficLight;
  final int confidenceScore;
  final String insights;

  const PriceSimulationResult({
    required this.productName,
    required this.userBaseCost,
    required this.userSalePrice,
    required this.marketAveragePrice,
    required this.marginPercentage,
    required this.trafficLight,
    required this.confidenceScore,
    required this.insights,
  });

  factory PriceSimulationResult.fromMap(Map<String, dynamic> map) {
    final tlString = map['trafficLight'] as String?;
    MarginTrafficLight light;
    switch (tlString) {
      case 'GREEN':
        light = MarginTrafficLight.green;
        break;
      case 'YELLOW':
        light = MarginTrafficLight.yellow;
        break;
      case 'RED':
      default:
        light = MarginTrafficLight.red;
        break;
    }

    return PriceSimulationResult(
      productName: map['productName'] as String? ?? 'N/A',
      userBaseCost: (map['userBaseCost'] as num?)?.toDouble() ?? 0.0,
      userSalePrice: (map['userSalePrice'] as num?)?.toDouble() ?? 0.0,
      marketAveragePrice: (map['marketAveragePrice'] as num?)?.toDouble() ?? 0.0,
      marginPercentage: (map['marginPercentage'] as num?)?.toDouble() ?? 0.0,
      trafficLight: light,
      confidenceScore: (map['confidenceScore'] as num?)?.toInt() ?? 0,
      insights: map['insights'] as String? ?? 'Información no disponible.',
    );
  }
}
