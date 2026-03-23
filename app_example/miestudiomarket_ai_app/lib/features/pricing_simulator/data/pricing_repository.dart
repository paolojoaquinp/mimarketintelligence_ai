import 'package:cloud_functions/cloud_functions.dart';

import '../domain/commodity_feed.dart';
import '../domain/price_simulation_result.dart';

/// Repository for handling pricing simulations and fetching base commodity costs.
class PricingRepository {
  final FirebaseFunctions _functions;

  PricingRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Fetches the mock commodity feed from the backend.
  Future<CommodityFeed> getCommodityPrices() async {
    final callable = _functions.httpsCallable('getCommodityPrices');
    final result = await callable.call();
    return CommodityFeed.fromMap(Map<String, dynamic>.from(result.data as Map));
  }

  /// Triggers the RAG AI flow to simulate and calculate margins compared to the market.
  Future<PriceSimulationResult> simulatePrices({
    required String productName,
    required double userBaseCost,
    required double userSalePrice,
  }) async {
    final callable = _functions.httpsCallable(
      'simulatePrices',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({
      'productName': productName,
      'userBaseCost': userBaseCost,
      'userSalePrice': userSalePrice,
    });

    return PriceSimulationResult.fromMap(Map<String, dynamic>.from(result.data as Map));
  }
}
