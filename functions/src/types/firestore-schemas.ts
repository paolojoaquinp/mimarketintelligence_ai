/**
 * Traceability metadata attached to every vectorized chunk and AI response.
 *
 * Why: design.md (QA-04) mandates < 2s retrieval of exact source origin
 * for every recommendation. This interface enforces structural consistency.
 */
export interface SourceRef {
  page: number;
  paragraph: number;
  fileHash: string;
  fileName: string;
}

/**
 * Status of a report during the ingestion pipeline.
 */
export type ReportStatus = "uploading" | "processing" | "completed" | "failed";

/**
 * Firestore document schema for uploaded reports.
 */
export interface ReportDocument {
  userId: string;
  fileName: string;
  uploadedAt: FirebaseFirestore.Timestamp;
  status: ReportStatus;
  storageRef: string;
}

/**
 * Firestore document schema for vectorized report chunks.
 */
export interface ReportChunkDocument {
  reportId: string;
  content: string;
  embedding: number[];
  sourceRef: SourceRef;
}

/**
 * Firestore document schema for generated analyses.
 */
export interface AnalysisDocument {
  reportId: string;
  type: "summary" | "market_gaps" | "buyer_persona";
  content: string;
  citations: SourceRef[];
  createdAt: FirebaseFirestore.Timestamp;
}
