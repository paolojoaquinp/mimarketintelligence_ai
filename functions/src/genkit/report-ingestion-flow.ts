/**
 * Report ingestion Genkit flow.
 *
 * Pipeline: Download PDF from Storage → Extract text → Chunk with SourceRef
 * → Generate embeddings → Store in Firestore report_chunks collection.
 *
 * Why Cloud Storage trigger: design.md ADR-002 prescribes async serverless
 * ingestion to avoid blocking the main thread.
 */
import { Genkit } from "genkit";
import { vertexAI } from "@genkit-ai/google-genai";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { extractAndChunkPdf, TextChunk } from "../utils/pdf-processor";
import { ReportChunkDocument, ReportStatus } from "../types/firestore-schemas";

/** Batch size for Firestore writes. Reduced to 50 to avoid 'Transaction too big' (10 MiB limit) due to large embedding vectors. */
const FIRESTORE_BATCH_LIMIT = 50;

/**
 * Processes a newly uploaded PDF report.
 *
 * Triggered when a file is uploaded to Cloud Storage.
 * Downloads the PDF, extracts text, generates embeddings,
 * and stores vectorized chunks in Firestore.
 */
export async function processReportUpload(
  ai: Genkit,
  filePath: string,
  reportId: string
): Promise<void> {
  const db = admin.firestore();
  const storage = admin.storage();

  try {
    await updateReportStatus(db, reportId, "processing");
    logger.info("Starting report ingestion", { reportId, filePath });

    // Step 1: Download PDF from Cloud Storage.
    const bucket = storage.bucket();
    const file = bucket.file(filePath);
    const [pdfBuffer] = await file.download();
    logger.info("PDF downloaded", { reportId, sizeBytes: pdfBuffer.length });

    // Step 2: Extract text and create chunks with SourceRef metadata.
    const fileName = filePath.split("/").pop() || "unknown.pdf";
    const chunks = await extractAndChunkPdf(pdfBuffer, fileName);
    logger.info("Text extracted and chunked", {
      reportId,
      totalChunks: chunks.length,
    });

    // Step 3: Generate embeddings for all chunks.
    const chunksWithEmbeddings = await generateEmbeddings(ai, chunks);
    logger.info("Embeddings generated", { reportId });

    // Step 4: Store chunks in Firestore.
    await storeChunksInFirestore(db, reportId, chunksWithEmbeddings);
    logger.info("Chunks stored in Firestore", { reportId });

    await updateReportStatus(db, reportId, "completed");
    logger.info("Report ingestion completed", { reportId });
  } catch (error) {
    logger.error("Report ingestion failed", { reportId, error });
    await updateReportStatus(db, reportId, "failed");
    throw error;
  }
}

/** Generate vector embeddings for text chunks using Vertex AI. */
async function generateEmbeddings(
  ai: Genkit,
  chunks: TextChunk[]
): Promise<Array<TextChunk & { embedding: number[] }>> {
  const results: Array<TextChunk & { embedding: number[] }> = [];

  // Process embeddings in batches to avoid rate limits.
  const batchSize = 50;
  for (let i = 0; i < chunks.length; i += batchSize) {
    const batch = chunks.slice(i, i + batchSize);

    const embeddings = await Promise.all(
      batch.map(async (chunk) => {
        const response = await ai.embed({
          embedder: vertexAI.embedder("text-embedding-004", {outputDimensionality: 768}),
          content: chunk.content,
        });
        // ai.embed() returns EmbedResponse[]; extract the vector from the first element.
        const vector = response[0]?.embedding ?? [];
        return {
          ...chunk,
          embedding: vector,
        };
      })
    );

    results.push(...embeddings);
  }

  return results;
}

/** Store vectorized chunks in Firestore using batched writes. */
async function storeChunksInFirestore(
  db: FirebaseFirestore.Firestore,
  reportId: string,
  chunks: Array<TextChunk & { embedding: number[] }>
): Promise<void> {
  const { FieldValue } = admin.firestore;
  
  for (let i = 0; i < chunks.length; i += FIRESTORE_BATCH_LIMIT) {
    const batch = db.batch();
    const batchChunks = chunks.slice(i, i + FIRESTORE_BATCH_LIMIT);

    for (const chunk of batchChunks) {
      const docRef = db.collection("report_chunks").doc();
      const doc: ReportChunkDocument = {
        reportId,
        content: chunk.content,
        // Enforce vector type so Genkit COSINE searches work
        embedding: FieldValue.vector(chunk.embedding),
        sourceRef: chunk.sourceRef,
      };
      batch.set(docRef, doc);
    }

    await batch.commit();
  }
}

/** Update the status field of a report document. */
async function updateReportStatus(
  db: FirebaseFirestore.Firestore,
  reportId: string,
  status: ReportStatus
): Promise<void> {
  await db.collection("reports").doc(reportId).update({ status });
}


