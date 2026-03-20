/**
 * Market gaps analysis Genkit flow (US02).
 *
 * Crosses global report trends with local competitor catalog to identify
 * underserved market niches. Uses Gemini 1.5 Pro for deep analysis
 * (design.md model router: Pro for "Puntos Ciegos").
 *
 * For each gap found, generates a detailed Buyer Persona (US02 AC3).
 */
import { Genkit } from "genkit";
import { vertexAI } from "@genkit-ai/google-genai";
import { defineFirestoreRetriever } from "@genkit-ai/firebase";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  CompetitorDocument,
  MarketGapDocument,
  BuyerPersona,
  SourceRef,
} from "../types/firestore-schemas";

/** Structured gap item returned by the LLM. */
interface RawMarketGap {
  trend: string;
  niche: string;
  demandScore: number;
  supplyScore: number;
  opportunity: string;
  buyerPersona: BuyerPersona;
  citedPages: number[];
}

/**
 * System prompt for market gap analysis.
 *
 * Why Gemini 1.5 Pro: design.md prescribes Pro for deep "Puntos Ciegos" analysis.
 * Why temperature 0.2: slightly higher than US01 (0.1) to allow cross-referencing
 * creativity while still prioritizing factual grounding.
 */
const MARKET_GAPS_SYSTEM_PROMPT = `Eres un analista estratégico de mercado especializado en detectar nichos desatendidos.
Tu tarea es comparar las tendencias globales (del contexto de reportes) con la oferta de 
competidores locales para identificar brechas de mercado.

REGLAS:
1. Si la información NO está en el contexto proporcionado, responde "Información no disponible".
2. NUNCA inventes datos o tendencias que no estén en los reportes.
3. Para cada brecha identificada, asigna puntuaciones numéricas:
   - demandScore (0-100): demanda proyectada basada en tendencias globales
   - supplyScore (0-100): nivel de oferta actual de competidores locales
4. Para cada brecha, genera un Buyer Persona detallado.

FORMATO DE RESPUESTA (JSON):
{
  "gaps": [
    {
      "trend": "Nombre de la tendencia global detectada",
      "niche": "Nicho de mercado desatendido",
      "demandScore": 85,
      "supplyScore": 15,
      "opportunity": "Descripción de la oportunidad de negocio",
      "buyerPersona": {
        "name": "Nombre representativo del consumidor",
        "ageRange": "25-35",
        "income": "Medio-alto",
        "behaviors": ["comportamiento 1", "comportamiento 2"],
        "painPoints": ["punto de dolor 1", "punto de dolor 2"],
        "motivations": ["motivación 1", "motivación 2"]
      },
      "citedPages": [1, 5, 12]
    }
  ]
}`;

/**
 * Creates the Firestore vector retriever for trend extraction from reports.
 */
function createTrendRetriever(ai: Genkit) {
  const firestore = admin.firestore();

  return defineFirestoreRetriever(ai, {
    name: "trendRetriever",
    label: "Trend Data Retriever",
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
 * Loads all competitors from the Firestore catalog.
 */
async function loadCompetitorCatalog(): Promise<CompetitorDocument[]> {
  const db = admin.firestore();
  const snapshot = await db.collection("competitors").get();

  return snapshot.docs.map((doc) => doc.data() as CompetitorDocument);
}

/**
 * Formats the competitor catalog into a readable context string for the LLM.
 */
function formatCompetitorContext(competitors: CompetitorDocument[]): string {
  if (competitors.length === 0) {
    return "No hay competidores registrados en el catálogo local.";
  }

  return competitors
    .map(
      (c) =>
        `- ${c.name} (${c.category}, ${c.location}): ${c.products.join(", ")}`
    )
    .join("\n");
}

/**
 * Analyzes market gaps for a given report by crossing trends with competitors.
 */
export async function analyzeMarketGaps(
  ai: Genkit,
  reportId: string
): Promise<MarketGapDocument[]> {
  logger.info("Starting market gap analysis", { reportId });

  const retriever = createTrendRetriever(ai);

  // Step 1: Retrieve trend-related chunks from the report.
  const trendQuery =
    "tendencias de mercado, crecimiento, demanda, consumo, oportunidades";

  const retrievalResult = await ai.retrieve({
    retriever,
    query: trendQuery,
    options: { limit: 15 },
  });

  logger.info("Retrieved trend chunks", {
    reportId,
    chunksRetrieved: retrievalResult.length,
  });

  // Step 2: Load competitor catalog.
  const competitors = await loadCompetitorCatalog();
  const competitorContext = formatCompetitorContext(competitors);

  logger.info("Loaded competitor catalog", {
    competitorCount: competitors.length,
  });

  // Step 3: Build trend context from retrieved chunks.
  const trendContext = retrievalResult
    .map((doc, index) => {
      const metadata = doc.metadata || {};
      const sourceRef = metadata.sourceRef as SourceRef | undefined;
      const pageInfo = sourceRef
        ? `[Página ${sourceRef.page}]`
        : `[Fuente ${index + 1}]`;
      return `${pageInfo}: ${doc.text}`;
    })
    .join("\n\n");

  // Step 4: Generate market gap analysis with Gemini 1.5 Pro.
  // Why Pro: design.md model router prescribes Pro for deep "Puntos Ciegos" analysis.
  const response = await ai.generate({
    model: vertexAI.model('gemini-2.5-flash'),
    system: MARKET_GAPS_SYSTEM_PROMPT,
    prompt: `Analiza las siguientes tendencias de mercado y compáralas con la oferta de competidores locales 
para identificar nichos desatendidos.

TENDENCIAS GLOBALES (del reporte ${reportId}):
${trendContext}

CATÁLOGO DE COMPETIDORES LOCALES:
${competitorContext}

Identifica las brechas de mercado donde hay alta demanda proyectada pero baja oferta local.
Responde en formato JSON.`,
    config: {
      temperature: 0.2,
    },
  });

  // Step 5: Parse response.
  const responseText = response.text;
  let parsedGaps: RawMarketGap[];

  try {
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error("No JSON found in response");
    const parsed = JSON.parse(jsonMatch[0]);
    parsedGaps = parsed.gaps || [];
  } catch {
    logger.warn("Failed to parse market gaps response", { reportId });
    parsedGaps = [];
  }

  // Step 6: Store results in Firestore and map citations.
  const db = admin.firestore();
  const batch = db.batch();
  const results: MarketGapDocument[] = [];

  for (const gap of parsedGaps) {
    const citations: SourceRef[] = retrievalResult
      .filter((doc) => {
        const sr = doc.metadata?.sourceRef as SourceRef | undefined;
        return sr && gap.citedPages.includes(sr.page);
      })
      .map((doc) => doc.metadata?.sourceRef as SourceRef);

    const gapDoc: MarketGapDocument = {
      reportId,
      trend: gap.trend,
      niche: gap.niche,
      demandScore: Math.min(100, Math.max(0, gap.demandScore)),
      supplyScore: Math.min(100, Math.max(0, gap.supplyScore)),
      opportunity: gap.opportunity,
      buyerPersona: gap.buyerPersona,
      citations,
      createdAt: admin.firestore.Timestamp.now(),
    };

    const docRef = db.collection("market_gaps").doc();
    batch.set(docRef, gapDoc);
    results.push(gapDoc);
  }

  await batch.commit();

  logger.info("Market gap analysis completed", {
    reportId,
    gapsFound: results.length,
  });

  return results;
}
