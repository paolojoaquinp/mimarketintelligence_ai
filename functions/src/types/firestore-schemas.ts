/**
 * Traceability metadata attached to every vectorized chunk and AI response.
 *
 * Why: design.md (QA-04) mandates < 2s retrieval of exact source origin
 * for every recommendation. This interface enforces structural consistency.
 */

// TODO: RESEARCH MORE ABOUT THIS ARCH, CONVENTION OF INTERFACES, ETC. IF ITS CORRECT.
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
  embedding: any; // Accept FieldValue.vector() type
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

/**
 * Firestore document schema for local competitors (US02).
 */
export interface CompetitorDocument {
  name: string;
  category: string;
  products: string[];
  location: string;
  createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Buyer persona generated per identified market niche (US02 AC3).
 */
export interface BuyerPersona {
  niche: string;
  demographics: string;
  painPoints: string[];
  buyingBehavior: string;
}

/**
 * Phase 3: Price Simulator result.
 */
export interface PricingSimulation {
  productName: string;
  userBaseCost: number;
  userSalePrice: number;
  marketAveragePrice: number;
  marginPercentage: number;
  trafficLight: "GREEN" | "YELLOW" | "RED";
  confidenceScore: number;
  insights: string;
  timestamp: FirebaseFirestore.Timestamp | Date;
}

/**
 * Firestore document schema for identified market gaps (US02).
 *
 * demandScore: 0-100 projected demand from global trends.
 * supplyScore: 0-100 current local supply from competitor catalog.
 * High demand + low supply = market opportunity.
 */
export interface MarketGapDocument {
  reportId: string;
  trend: string;
  niche: string;
  demandScore: number;
  supplyScore: number;
  opportunity: string;
  buyerPersona: BuyerPersona;
  citations: SourceRef[];
  createdAt: FirebaseFirestore.Timestamp;
}
