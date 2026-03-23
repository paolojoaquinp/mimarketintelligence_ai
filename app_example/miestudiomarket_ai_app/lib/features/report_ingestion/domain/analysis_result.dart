/// Domain model for a generated analysis result (summary).
// TODO: Refactor, what is this? entity? model?
class AnalysisResult {
  final String summary;
  final String localImpact;
  final List<SourceRef> citations;
  final String reportId;

  const AnalysisResult({
    required this.summary,
    required this.localImpact,
    required this.citations,
    required this.reportId,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> data) {
    final citationsList = (data['citations'] as List<dynamic>?)
            ?.map((c) => SourceRef.fromMap(Map<String, dynamic>.from(c as Map)))
            .toList() ??
        [];

    return AnalysisResult(
      summary: data['summary'] as String? ?? '',
      localImpact: data['localImpact'] as String? ?? '',
      citations: citationsList,
      reportId: data['reportId'] as String? ?? '',
    );
  }
}

/// Traceability metadata for a source citation.
/// Mirrors the SourceRef TypeScript interface.
class SourceRef {
  final int page;
  final int paragraph;
  final String fileHash;
  final String fileName;

  const SourceRef({
    required this.page,
    required this.paragraph,
    required this.fileHash,
    required this.fileName,
  });

  factory SourceRef.fromMap(Map<String, dynamic> data) {
    return SourceRef(
      page: data['page'] as int? ?? 0,
      paragraph: data['paragraph'] as int? ?? 0,
      fileHash: data['fileHash'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
    );
  }
}
