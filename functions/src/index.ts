/**
 * Cloud Functions entry point for MiEstudioMarket AI.
 *
 * Initializes Firebase Admin SDK and Genkit with Vertex AI plugin.
 * Registers Cloud Function triggers for the RAG pipeline.
 */
import { genkit } from "genkit";
import { vertexAI } from "@genkit-ai/vertexai";
import { enableFirebaseTelemetry } from "@genkit-ai/firebase";
import { onRequest, onCall } from "firebase-functions/v2/https";
import { onObjectFinalized } from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { processReportUpload } from "./genkit/report-ingestion-flow";
import { generateReportSummary } from "./genkit/summary-flow";
import { analyzeMarketGaps } from "./genkit/market-gaps-flow";

// Initialize Firebase Admin SDK.
admin.initializeApp();

// Enable Firebase telemetry for Genkit observability.
// Why: design.md rule #3 mandates structured logs across the RAG pipeline.
enableFirebaseTelemetry();

// Initialize Genkit with Vertex AI plugin.
// Why Gemini 2.0 Flash as default: design.md prescribes it for
// fast summarization flows (US01), with Pro reserved for deep analysis (US02).
export const ai = genkit({
  plugins: [vertexAI()],
});

/**
 * Health check endpoint to verify the Cloud Functions + Genkit setup.
 */
export const healthCheck = onRequest(async (_req, res) => {
  logger.info("Health check requested");
  res.json({
    status: "ok",
    service: "miestudiomarket-ai",
    timestamp: new Date().toISOString(),
  });
});

/**
 * Triggered when a PDF is uploaded to Cloud Storage.
 *
 * Expects files in the path: reports/{reportId}/{fileName}.pdf
 * The reportId must correspond to an existing document in the 'reports' collection.
 *
 * Why onObjectFinalized: ADR-002 prescribes async serverless ingestion
 * to avoid blocking the main thread. Storage triggers provide this natively.
 */
export const onReportUploaded = onObjectFinalized(
  { 
    region: "us-central1",
    // Only process large files — give Cloud Functions enough memory and time.
    memory: "1GiB",
    timeoutSeconds: 540,
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // Only process PDF files in the reports/ directory.
    if (!filePath.startsWith("reports/") || contentType !== "application/pdf") {
      logger.info("Skipping non-PDF or non-report file", { filePath });
      return;
    }

    // Extract reportId from path: reports/{reportId}/{fileName}.pdf
    const pathParts = filePath.split("/");
    if (pathParts.length < 3) {
      logger.error("Invalid report path structure", { filePath });
      return;
    }
    const reportId = pathParts[1];

    await processReportUpload(ai, filePath, reportId);
  }
);

/**
 * Callable function for generating report summaries (US01).
 *
 * Expects: { reportId: string, query: string }
 * Returns: SummaryResponse with summary, localImpact, citations
 */
export const generateSummary = onCall(
  {
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const { reportId, query } = request.data;

    if (!reportId || typeof reportId !== "string") {
      throw new Error("reportId is required and must be a string");
    }
    if (!query || typeof query !== "string") {
      throw new Error("query is required and must be a string");
    }

    return generateReportSummary(ai, reportId, query);
  }
);

/**
 * Callable function for market gap analysis (US02).
 *
 * Expects: { reportId: string }
 * Returns: MarketGapDocument[] with gaps, scores, and buyer personas
 *
 * Why 1GiB memory: Gemini 1.5 Pro responses can be large (deep analysis).
 */
export const analyzeGaps = onCall(
  {
    region: "us-central1",
    memory: "1GiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    const { reportId } = request.data;

    if (!reportId || typeof reportId !== "string") {
      throw new Error("reportId is required and must be a string");
    }

    return analyzeMarketGaps(ai, reportId);
  }
);

/**
 * Callable function to add a local competitor to the catalog (US02).
 *
 * Expects: { name: string, category: string, products: string[], location: string }
 * Returns: { id: string }
 */
export const addCompetitor = onCall(
  { region: "us-central1" },
  async (request) => {
    const { name, category, products, location } = request.data;

    if (!name || typeof name !== "string") {
      throw new Error("name is required and must be a string");
    }
    if (!category || typeof category !== "string") {
      throw new Error("category is required and must be a string");
    }
    if (!Array.isArray(products) || products.length === 0) {
      throw new Error("products is required and must be a non-empty array");
    }

    const db = admin.firestore();
    const docRef = await db.collection("competitors").add({
      name,
      category,
      products,
      location: location || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("Competitor added", { id: docRef.id, name });
    return { id: docRef.id };
  }
);
