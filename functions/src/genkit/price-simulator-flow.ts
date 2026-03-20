import { vertexAI } from "@genkit-ai/google-genai";
import { genkit, z } from "genkit";
import { createReportRetriever } from "./summary-flow";

const ai = genkit({
  plugins: [vertexAI({ location: "us-east1" })],
});

/**
 * Zod schema for the Genkit flow input.
 */
export const PriceSimulationInputSchema = z.object({
  productName: z.string().describe("The name of the commodity or product to simulate"),
  userBaseCost: z.number().describe("The user's raw production cost"),
  userSalePrice: z.number().describe("The user's intended target sale price"),
});

/**
 * Zod schema for the AI LLM output.
 */
export const PriceSimulationOutputSchema = z.object({
  marketAveragePrice: z.number().describe("The detected average market price in the industry"),
  confidenceScore: z.number().min(0).max(100).describe("How confident the AI is (0-100) based on the retrieved data"),
  insights: z.string().describe("Brief 2-sentence explanation of the market price and why this gap exists"),
});

const PRICE_SIMULATOR_SYSTEM_PROMPT = `
Eres un analista de inteligencia de precios para microempresarios cárnicos.
Tu objetivo es analizar los datos de los reportes de mercado recuperados y determinar 
el Precio Promedio de Mercado (Market Average Price) para el producto sugerido.

REGLAS:
1. Extrae el precio de venta directo al consumidor o precio de Anaquel para el producto indicado.
2. Si los reportes no mencionan el producto exacto, haz una estimación profesional basada en productos similares en el contexto.
3. Si de plano no hay NADA de información relacionada, devuelve el mismo userSalePrice que te envían como marketAveragePrice, pero con confidenceScore muy bajo (ej. 10).
4. El insight debe justificar brevemente la decisión.
`;

/**
 * Genkit Flow: simulatePrices
 * 
 * Uses RAG to find mentions of a specific product's price in the ingested reports,
 * then returns the market reference price and insights.
 */
export const simulatePricesFlow = ai.defineFlow(
  {
    name: "simulatePrices",
    inputSchema: PriceSimulationInputSchema,
    outputSchema: PriceSimulationOutputSchema,
  },
  async (input) => {
    // Note: To avoid the empty context issue (no composite index), we omit the where filter 
    // and rely on pure semantic search across all global chunks.
    const retriever = createReportRetriever(ai);

    const retrievalResult = await ai.retrieve({
      retriever,
      query: `precio mercado ticket promedio ventas anaquel consumidor ${input.productName}`,
      options: { limit: 10 },
    });

    const contextDocs = retrievalResult.map((doc) => doc.text).join("\n\n---\n\n");

    const promptContext = `
PRODUCTO A ANALIZAR: ${input.productName}
COSTO BASE DEL USUARIO: $${input.userBaseCost}
PRECIO DE VENTA PLANEADO: $${input.userSalePrice}

CONTEXTO EXTRAÍDO DE REPORTES:
${contextDocs || "No se encontraron documentos relevantes en la búsqueda vectorial."}
`;

    // Generate output with strictly enforced JSON
    const response = await ai.generate({
      model: vertexAI.model('gemini-2.5-flash'),
      system: PRICE_SIMULATOR_SYSTEM_PROMPT,
      prompt: promptContext,
      output: { schema: PriceSimulationOutputSchema },
      config: {
        temperature: 0.1, // Low temp for more deterministic numbers
      },
    });

    if (!response.output) {
      throw new Error("Failed to generate price simulation output.");
    }

    return response.output;
  }
);
