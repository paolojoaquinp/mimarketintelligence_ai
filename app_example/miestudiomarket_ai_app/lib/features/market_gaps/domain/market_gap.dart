/// Domain model for an identified market gap.
library;
import '../../report_ingestion/domain/analysis_result.dart';

class MarketGap {
  final String trend;
  final String niche;
  final double demandScore;
  final double supplyScore;
  final String opportunity;
  final BuyerPersona buyerPersona;
  final List<SourceRef> citations;

  const MarketGap({
    required this.trend,
    required this.niche,
    required this.demandScore,
    required this.supplyScore,
    required this.opportunity,
    required this.buyerPersona,
    required this.citations,
  });

  /// A gap is a strong opportunity when demand is high and supply is low.
  bool get isHighOpportunity => demandScore >= 60 && supplyScore <= 40;

  factory MarketGap.fromMap(Map<String, dynamic> data) {
    final personaRaw = data['buyerPersona'] as Map?;
    final personaData = personaRaw != null ? Map<String, dynamic>.from(personaRaw) : <String, dynamic>{};
    
    final citationsRaw = data['citations'] as List?;
    final citationsList = citationsRaw
            ?.map((c) => SourceRef.fromMap(Map<String, dynamic>.from(c as Map)))
            .toList() ??
        [];

    return MarketGap(
      trend: data['trend'] as String? ?? '',
      niche: data['niche'] as String? ?? '',
      demandScore: (data['demandScore'] as num?)?.toDouble() ?? 0,
      supplyScore: (data['supplyScore'] as num?)?.toDouble() ?? 0,
      opportunity: data['opportunity'] as String? ?? '',
      buyerPersona: BuyerPersona.fromMap(personaData),
      citations: citationsList,
    );
  }
}

/// Detailed buyer persona per niche (US02 AC3).
class BuyerPersona {
  final String niche;
  final String demographics;
  final List<String> painPoints;
  final String buyingBehavior;

  const BuyerPersona({
    required this.niche,
    required this.demographics,
    required this.painPoints,
    required this.buyingBehavior,
  });

  factory BuyerPersona.fromMap(Map<String, dynamic> data) {
    return BuyerPersona(
      niche: data['niche'] as String? ?? 'Nicho General',
      demographics: data['demographics'] as String? ?? 'Datos demográficos no disponibles',
      painPoints: List<String>.from(data['painPoints'] as List? ?? []),
      buyingBehavior: data['buyingBehavior'] as String? ?? 'Comportamiento no especificado',
    );
  }
}
