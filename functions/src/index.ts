/**
 * Cloud Functions entry point for MiEstudioMarket AI.
 *
 * Initializes Firebase Admin SDK and Genkit with Vertex AI plugin.
 * Registers Cloud Function triggers for the RAG pipeline.
 */
import { genkit } from "genkit";
import { vertexAI } from "@genkit-ai/google-genai";
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
// Using us-east1 to ensure availability of newer Gemini 2.5/Pro models.
const ai = genkit({
  plugins: [vertexAI({ location: 'us-east1' })],
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

/**
 * Callable function for US03 AC1: Commodity Feed (Mock).
 * Returns static base costs for raw materials.
 */
export const getCommodityPrices = onCall(
  { region: "us-central1" },
  async () => {
    // In a real app, this would hit a live pricing API.
    return {
      commodities: [
        { id: "pollo_entero", name: "Pollo Entero", price: 2.10, unit: "kg" },
        { id: "pechuga_pollo", name: "Pechuga de Pollo", price: 3.50, unit: "kg" },
        { id: "cerdo_pierna", name: "Pierna de Cerdo", price: 4.20, unit: "kg" },
        { id: "res_molida", name: "Res Molida", price: 5.80, unit: "kg" },
      ],
      lastUpdated: new Date().toISOString(),
    };
  }
);

/**
 * Callable function for US03 AC2/AC3: Price Simulator.
 * Uses Genkit to find market average and calculates Margin Traffic Light.
 */
export const simulatePrices = onCall(
  {
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const { productName, userBaseCost, userSalePrice } = request.data;

    if (!productName || typeof productName !== "string") {
      throw new Error("productName is required");
    }
    if (typeof userBaseCost !== "number" || typeof userSalePrice !== "number") {
      throw new Error("userBaseCost and userSalePrice must be numbers");
    }

    // 1. Run Genkit flow to find Market Average Price
    const { simulatePricesFlow } = await import("./genkit/price-simulator-flow");
    const aiResult = await simulatePricesFlow({ productName, userBaseCost, userSalePrice });

    // 2. Calculate Margin (US03 AC3)
    // Margin formula: (Sale Price - Cost) / Sale Price
    const marginPercentage = ((userSalePrice - userBaseCost) / userSalePrice) * 100;

    let trafficLight: "GREEN" | "YELLOW" | "RED" = "RED";
    if (marginPercentage > 30) {
      trafficLight = "GREEN";
    } else if (marginPercentage >= 15) {
      trafficLight = "YELLOW";
    }

    // 3. Save to Firestore history (optional but good for tracking)
    const db = admin.firestore();
    const simData = {
      productName,
      userBaseCost,
      userSalePrice,
      marketAveragePrice: aiResult.marketAveragePrice,
      marginPercentage: Math.round(marginPercentage * 10) / 10,
      trafficLight,
      confidenceScore: aiResult.confidenceScore,
      insights: aiResult.insights,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await db.collection("pricing_simulations").add(simData);

    return simData;
  }
);
