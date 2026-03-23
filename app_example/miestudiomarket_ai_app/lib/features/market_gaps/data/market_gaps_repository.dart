/// Repository for market gaps operations.
///
/// Handles competitor CRUD, market gap analysis requests,
/// and reading gap results from Firestore.
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/competitor.dart';
import '../domain/market_gap.dart';

// TODO: Refactor to use with extensions(firebase)
class MarketGapsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MarketGapsRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Adds a local competitor to the catalog.
  Future<String> addCompetitor({
    required String name,
    required String category,
    required List<String> products,
    String location = '',
  }) async {
    final callable = _functions.httpsCallable('addCompetitor');
    final result = await callable.call({
      'name': name,
      'category': category,
      'products': products,
      'location': location,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['id'] as String;
  }

  /// Streams all competitors from the catalog.
  Stream<List<Competitor>> watchCompetitors() {
    return _firestore
        .collection('competitors')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Competitor.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Triggers market gap analysis for a given report.
  Future<List<MarketGap>> analyzeGaps({required String reportId}) async {
    final callable = _functions.httpsCallable(
      'analyzeGaps',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    final result = await callable.call({
      'reportId': reportId,
    });

    final dataList = List<dynamic>.from(result.data as List);
    return dataList
        .map((item) => MarketGap.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  /// Streams stored market gaps for a given report.
  Stream<List<MarketGap>> watchMarketGaps(String reportId) {
    return _firestore
        .collection('market_gaps')
        .where('reportId', isEqualTo: reportId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketGap.fromMap(doc.data()))
            .toList());
  }

  /// Deletes a competitor from the catalog.
  Future<void> deleteCompetitor(String competitorId) async {
    await _firestore.collection('competitors').doc(competitorId).delete();
  }
}
