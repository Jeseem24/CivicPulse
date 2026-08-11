/**
 * Embedding Service — Text embeddings for semantic similarity
 * Uses Gemini embedContent if available, with a fast 128-dim TF-IDF n-gram vectorizer fallback.
 */

const { getEmbeddingModel, isAIAvailable } = require("./geminiClient");

// In-memory embedding cache (complaintId -> embedding vector)
const embeddingCache = new Map();

/**
 * Generate 128-dimensional normalized term n-gram embedding vector
 * @param {string} text
 * @returns {number[]} 128-dim unit vector
 */
function generateLocalEmbedding(text = "") {
  const normalized = text.toLowerCase().replace(/[^a-z0-9\s]/g, " ");
  const words = normalized.split(/\s+/).filter(w => w.length > 2);
  const vector = new Array(128).fill(0);

  const tokens = [];
  for (let i = 0; i < words.length; i++) {
    tokens.push(words[i]);
    if (i < words.length - 1) tokens.push(`${words[i]}_${words[i + 1]}`);
  }

  for (const token of tokens) {
    let hash = 0;
    for (let c = 0; c < token.length; c++) {
      hash = ((hash << 5) - hash + token.charCodeAt(c)) | 0;
    }
    const idx = Math.abs(hash) % 128;
    vector[idx] += 1;
  }

  // Normalize to unit length
  let norm = 0;
  for (let i = 0; i < 128; i++) norm += vector[i] * vector[i];
  norm = Math.sqrt(norm);
  if (norm > 0) {
    for (let i = 0; i < 128; i++) vector[i] /= norm;
  }

  return vector;
}

/**
 * Generate text embedding vector
 * @param {string} text
 * @returns {number[]} Embedding vector
 */
async function getEmbedding(text) {
  if (!text || typeof text !== "string") return generateLocalEmbedding("");

  if (isAIAvailable()) {
    const model = getEmbeddingModel();
    if (model) {
      try {
        const result = await Promise.race([
          model.embedContent(text),
          new Promise((_, reject) => setTimeout(() => reject(new Error("Embedding timeout")), 5000))
        ]);
        if (result && result.embedding && Array.isArray(result.embedding.values)) {
          return result.embedding.values;
        }
      } catch (err) {
        // API embedding unavailable or 404 — use local fallback vectorizer
      }
    }
  }

  return generateLocalEmbedding(text);
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

module.exports = {
  getEmbedding,
  generateLocalEmbedding,
  cosineSimilarity,
  cacheEmbedding,
  getCachedEmbedding,
  getAllCachedEmbeddings
};
