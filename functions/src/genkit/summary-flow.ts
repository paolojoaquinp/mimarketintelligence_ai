/**
 * Summary generation Genkit flow.
 *
 * Uses Firestore vector retriever to find relevant chunks,
 * then generates an executive summary with "Impacto Local" section
 * using Gemini 2.0 Flash.
 *
 * Design constraints applied:
 * - temperature: 0.1 (ADR-003: data over creativity)
 * - Negative Constraints: "If info not in corpus → 'Información no disponible'"
 * - Mandatory "Impacto Local" section (US01 AC2)
 * - Source citations with SourceRef (US01 AC3, QA-04)
 */
import { Genkit } from "genkit";
import { vertexAI } from "@genkit-ai/google-genai";
import { defineFirestoreRetriever } from "@genkit-ai/firebase";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { SourceRef } from "../types/firestore-schemas";

/** Structured summary response returned to the client. */
export interface SummaryResponse {
  summary: string;
  localImpact: string;
  citations: SourceRef[];
  reportId: string;
}

/**
 * System prompt for summary generation.
 *
 * Why temperature 0.1: ADR-003 mandates controlled temperature
 * to ensure factual grounding over creative interpretation.
 *
 * Why Negative Constraint: QA-02 requires 100% grounded citations.
 * The model must refuse to fabricate data not present in the corpus.
 */
const SUMMARY_SYSTEM_PROMPT = `Eres un analista de mercado experto que genera resúmenes ejecutivos 
a partir de reportes de mercado. Tus respuestas deben estar ESTRICTAMENTE basadas en la 
información proporcionada en el contexto.

REGLAS ABSOLUTAS:
1. Si la información NO está en el contexto proporcionado, responde "Información no disponible".
2. NUNCA inventes datos, cifras o tendencias que no estén explícitamente en el contexto.
3. Cada afirmación DEBE poder rastrearse a una fuente específica del contexto.
4. Tu respuesta DEBE incluir una sección obligatoria de "Impacto Local" que traduzca 
   los datos macroeconómicos a oportunidades para microempresarios locales.

FORMATO DE RESPUESTA:
Debes responder ÚNICAMENTE con un objeto JSON válido, sin delimitadores de código (markdown), con esta estructura exacta:
{
  "summary": "Resumen ejecutivo detallado de los hallazgos clave...",
  "localImpact": "Traducción de tendencias globales a impacto para microempresarios locales...",
  "citedPages": [1, 3, 5]
}

Si la información del contexto es muy limitada, haz el mejor resumen posible con lo que tengas en lugar de decir "Información no disponible".`;

/**
 * Creates and configures the Firestore vector retriever for report chunks.
 */
export function createReportRetriever(ai: Genkit) {
  const firestore = admin.firestore();

  return defineFirestoreRetriever(ai, {
    name: "reportChunksRetriever",
    label: "Report Chunks Retriever",
    firestore,
    collection: "report_chunks",
    embedder: vertexAI.embedder("text-embedding-004", {outputDimensionality: 768}),
    vectorField: "embedding",
    contentField: "content",
    distanceMeasure: "COSINE",
    metadataFields: ["sourceRef", "reportId"],
  });
}

/**
 * Generates an executive summary for a given report.
 *
 * Pipeline: Query → Vector Retrieval → Prompt Augmentation → Generation
 */
export async function generateReportSummary(
  ai: Genkit,
  reportId: string,
  query: string
): Promise<SummaryResponse> {
  logger.info("Starting summary generation", { reportId, query });

  const retriever = createReportRetriever(ai);

  // Step 1: Retrieve relevant chunks using vector similarity.
  // We use a semantic keyword query instead of the user's meta-instruction to get better vector matches.
  const semanticQuery = "resumen ejecutivo, hallazgos principales, conclusiones, mercado, tendencias, ingresos, proyección";
  
  const retrievalResult = await ai.retrieve({
    retriever,
    query: semanticQuery,
    options: { 
      limit: 15
    },
  });

  logger.info("Retrieved relevant chunks", {
    reportId,
    chunksRetrieved: retrievalResult.length,
  });

  // Step 2: Build context from retrieved chunks.
  const contextParts = retrievalResult.map((doc, index) => {
    const metadata = doc.metadata || {};
    const sourceRef = metadata.sourceRef as SourceRef | undefined;
    const pageInfo = sourceRef
      ? `[Página ${sourceRef.page}, Párrafo ${sourceRef.paragraph}]`
      : `[Fuente ${index + 1}]`;
    return `${pageInfo}: ${doc.text}`;
  });

  const context = contextParts.join("\n\n---\n\n");

  // Step 3: Generate summary with Gemini 1.5 Flash.
  // Why Flash: design.md prescribes Flash for summarization (fast, cost-effective).
  const response = await ai.generate({
    model: vertexAI.model('gemini-2.5-flash'),
    system: SUMMARY_SYSTEM_PROMPT,
    prompt: `Basándote EXCLUSIVAMENTE en el siguiente contexto extraído de reportes de mercado, 
genera un resumen ejecutivo para el reporte con ID: ${reportId}.

CONTEXTO:
${context}

PREGUNTA DEL USUARIO:
${query}

Responde en formato JSON.`,
    config: {
      // ADR-003: temperature 0.1 for factual grounding over creativity.
      temperature: 0.1,
    },
  });

  // Step 4: Parse response and extract citations.
  const responseText = response.text;
  let parsedResponse: { summary: string; localImpact: string; citedPages: number[] };

  try {
    // Extract JSON from response (may be wrapped in markdown code blocks).
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error("No JSON found in model response");
    }
    parsedResponse = JSON.parse(jsonMatch[0]);
  } catch {
    logger.warn("Failed to parse structured response, using raw text", {
      reportId,
    });
    parsedResponse = {
      summary: responseText,
      localImpact: "Información no disponible",
      citedPages: [],
    };
  }

  // Step 5: Map cited pages back to SourceRef metadata.
  const citations: SourceRef[] = retrievalResult
    .filter((doc) => {
      const sourceRef = doc.metadata?.sourceRef as SourceRef | undefined;
      return sourceRef && parsedResponse.citedPages.includes(sourceRef.page);
    })
    .map((doc) => doc.metadata?.sourceRef as SourceRef);

  logger.info("Summary generation completed", {
    reportId,
    citationsCount: citations.length,
  });

  return {
    summary: parsedResponse.summary,
    localImpact: parsedResponse.localImpact,
    citations,
    reportId,
  };
}
