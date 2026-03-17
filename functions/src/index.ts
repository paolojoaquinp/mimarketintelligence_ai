/**
 * Cloud Functions entry point for MiEstudioMarket AI.
 *
 * Initializes Firebase Admin SDK and Genkit with Vertex AI plugin.
 * All Genkit flows are registered here and exported as Cloud Functions.
 */
import { genkit } from "genkit";
import { vertexAI } from "@genkit-ai/vertexai";
import { enableFirebaseTelemetry } from "@genkit-ai/firebase";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

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
 * Returns a simple status JSON to confirm the backend is operational.
 */
export const healthCheck = onRequest(async (_req, res) => {
  logger.info("Health check requested");
  res.json({
    status: "ok",
    service: "miestudiomarket-ai",
    timestamp: new Date().toISOString(),
  });
});
