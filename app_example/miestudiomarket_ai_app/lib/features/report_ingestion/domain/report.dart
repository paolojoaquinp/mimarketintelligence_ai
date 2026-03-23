/// Domain model representing an uploaded report.
class Report {
  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final ReportStatus status;
  final String storageRef;

  const Report({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.status,
    required this.storageRef,
  });

  factory Report.fromFirestore(String id, Map<String, dynamic> data) {
    return Report(
      id: id,
      fileName: data['fileName'] as String? ?? '',
      uploadedAt: (data['uploadedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      status: ReportStatus.fromString(data['status'] as String? ?? 'uploading'),
      storageRef: data['storageRef'] as String? ?? '',
    );
  }
}

/// Processing status of a report in the ingestion pipeline.
enum ReportStatus {
  uploading,
  processing,
  completed,
  failed;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReportStatus.uploading,
    );
  }
}
