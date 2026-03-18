/**
 * PDF text extraction and chunking utility.
 *
 * Extracts text from PDF buffers, splits into page-aware chunks,
 * and generates SourceRef metadata for traceability (QA-04).
 */
import { createHash } from "crypto";
import { PDFParse } from "pdf-parse";
import { SourceRef } from "../types/firestore-schemas";

/** A text chunk with its traceability metadata. */
export interface TextChunk {
  content: string;
  sourceRef: SourceRef;
}

/** Maximum characters per chunk to stay within embedding model limits. */
const MAX_CHUNK_SIZE = 1000;

/**
 * Extracts text from a PDF buffer and splits it into chunks with metadata.
 *
 * Why page-level splitting: design.md (QA-04) mandates < 2s retrieval
 * of exact source origin (page, paragraph). Page boundaries provide
 * the most reliable anchor points for citation.
 */
export async function extractAndChunkPdf(
  pdfBuffer: Buffer,
  fileName: string
): Promise<TextChunk[]> {
  const fileHash = createHash("sha256").update(pdfBuffer).digest("hex");

  // pdf-parse v3 uses class-based API with per-page text extraction.
  const parser = new PDFParse({ data: new Uint8Array(pdfBuffer) });
  const textResult = await parser.getText();

  const chunks: TextChunk[] = [];

  for (const page of textResult.pages) {
    const pageText = page.text.trim();
    if (!pageText) continue;

    const paragraphs = splitIntoParagraphs(pageText);

    for (let paraIndex = 0; paraIndex < paragraphs.length; paraIndex++) {
      const paragraph = paragraphs[paraIndex].trim();
      if (!paragraph) continue;

      // Split large paragraphs into smaller chunks if they exceed the limit.
      const subChunks = splitBySize(paragraph, MAX_CHUNK_SIZE);

      for (const subChunk of subChunks) {
        chunks.push({
          content: subChunk,
          sourceRef: {
            page: page.num,
            paragraph: paraIndex + 1,
            fileHash,
            fileName,
          },
        });
      }
    }
  }

  // Clean up parser resources.
  await parser.destroy();

  return chunks;
}

/**
 * Splits text into paragraphs using double newlines as boundaries.
 * Falls back to single newlines if no double newlines are found.
 */
function splitIntoParagraphs(text: string): string[] {
  const doubleNewlineSplit = text.split(/\n\s*\n/);
  if (doubleNewlineSplit.length > 1) {
    return doubleNewlineSplit;
  }
  return text.split(/\n/);
}

/**
 * Splits a text string into chunks that do not exceed maxSize characters.
 * Attempts to split at sentence boundaries for readability.
 */
function splitBySize(text: string, maxSize: number): string[] {
  if (text.length <= maxSize) {
    return [text];
  }

  const chunks: string[] = [];
  let remaining = text;

  while (remaining.length > maxSize) {
    // Try to find a sentence boundary within the max size limit.
    let splitPoint = remaining.lastIndexOf(". ", maxSize);
    if (splitPoint === -1 || splitPoint < maxSize * 0.3) {
      // Fallback: split at the last space within the limit.
      splitPoint = remaining.lastIndexOf(" ", maxSize);
    }
    if (splitPoint === -1) {
      // Last resort: hard split at maxSize.
      splitPoint = maxSize;
    }

    chunks.push(remaining.substring(0, splitPoint + 1).trim());
    remaining = remaining.substring(splitPoint + 1).trim();
  }

  if (remaining) {
    chunks.push(remaining);
  }

  return chunks;
}
