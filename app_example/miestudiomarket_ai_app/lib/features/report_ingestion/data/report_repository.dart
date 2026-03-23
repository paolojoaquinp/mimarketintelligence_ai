/// Repository for report-related Firebase operations.
///
/// Handles PDF upload to Cloud Storage, report metadata in Firestore,
/// and calling the summary generation Cloud Function.
library;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

import '../domain/analysis_result.dart';
import '../domain/report.dart';

// TODO: Refactor to use with extensions(firebase)
class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  ReportRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Uploads a PDF file and creates a report document in Firestore.
  ///
  /// Returns the report ID for tracking status.
  /// The Cloud Function trigger handles the rest of the pipeline.
  Future<String> uploadReport(File pdfFile) async {
    final fileName = pdfFile.path.split('/').last;

    // Step 1: Create report document in Firestore to get the ID.
    final reportRef = await _firestore.collection('reports').add({
      'fileName': fileName,
      'uploadedAt': FieldValue.serverTimestamp(),
      'status': 'uploading',
      'storageRef': '',
    });

    final reportId = reportRef.id;
    final storagePath = 'reports/$reportId/$fileName';

    // Step 2: Upload PDF to Cloud Storage.
    final storageRef = _storage.ref().child(storagePath);
    await storageRef.putFile(
      pdfFile,
      SettableMetadata(contentType: 'application/pdf'),
    );

    // Step 3: Update report with storage reference.
    await reportRef.update({'storageRef': storagePath});

    return reportId;
  }

  /// Gets the total number of uploaded reports efficiently using an aggregation query.
  /// 
  /// This avoids downloading all documents just to count them, saving reads and improving performance.
  Future<int> getReportsCount() async {
    final countSnap = await _firestore.collection('reports').count().get();
    return countSnap.count ?? 0;
  }

  /// Streams real-time updates for a specific report's status.
  Stream<Report> watchReport(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        throw Exception('Report not found: $reportId');
      }
      return Report.fromFirestore(snapshot.id, data);
    });
  }

  /// Calls the generateSummary Cloud Function.
  Future<AnalysisResult> generateSummary({
    required String reportId,
    required String query,
  }) async {
    final countSnap = await _firestore.collection('report_chunks').count().get();
    debugPrint('=== DEBUG RAG === Total chunks in DB: ${countSnap.count ?? 0}');

    final callable = _functions.httpsCallable(
      'generateSummary',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({
      'reportId': reportId,
      'query': query,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    return AnalysisResult.fromMap(data);
  }

  /// Streams all reports ordered by upload date.
  Stream<List<Report>> watchAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
