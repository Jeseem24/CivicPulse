/**
 * Embedding Service — Text embeddings via Gemini for semantic similarity
 */

const { getEmbeddingModel, isAIAvailable } = require("./geminiClient");

// In-memory embedding cache (complaintId -> embedding vector)
const embeddingCache = new Map();

/**
 * Generate text embedding
 * @param {string} text
 * @returns {number[]|null}
 */
async function getEmbedding(text) {
  if (!isAIAvailable()) return null;
  const model = getEmbeddingModel();
  if (!model) return null;

  try {
    const result = await Promise.race([
      model.embedContent(text),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Embedding timeout")), 8000))
    ]);
    return result.embedding.values;
  } catch (err) {
    console.error("[EMBEDDING] Failed:", err.message);
    return null;
  }
}

/**
 * Compute cosine similarity between two vectors
 */
function cosineSimilarity(a, b) {
  if (!a || !b || a.length !== b.length) return 0;
  let dot = 0, magA = 0, magB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  const denom = Math.sqrt(magA) * Math.sqrt(magB);
  return denom === 0 ? 0 : dot / denom;
}

/**
 * Cache an embedding for a complaint
 */
function cacheEmbedding(complaintId, embedding) {
  if (embedding) embeddingCache.set(complaintId, embedding);
}

/**
 * Get cached embedding
 */
function getCachedEmbedding(complaintId) {
  return embeddingCache.get(complaintId) || null;
}

/**
 * Get all cached embeddings
 */
function getAllCachedEmbeddings() {
  return embeddingCache;
}

module.exports = { getEmbedding, cosineSimilarity, cacheEmbedding, getCachedEmbedding, getAllCachedEmbeddings };
