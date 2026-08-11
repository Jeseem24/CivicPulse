/**
 * Duplicate Detector — Semantic similarity for complaint deduplication and clustering
 */

const { getEmbedding, cosineSimilarity, cacheEmbedding, getAllCachedEmbeddings } = require("./embeddingService");

const DUPLICATE_THRESHOLD = 0.70;
const RELATED_THRESHOLD = 0.50;

/**
 * Find duplicate/related complaints for a new complaint
 * @param {string} complaintId - New complaint ID
 * @param {string} text - Combined title + description
 * @param {Array} existingComplaints - All existing complaints from DB
 * @returns {object} { duplicateOf, relatedComplaintIds, similarityScore, clusterSize }
 */
async function findDuplicates(complaintId, text, existingComplaints = []) {
  const result = {
    duplicateOf: null,
    relatedComplaintIds: [],
    highestSimilarity: 0,
    clusterSize: 1
  };

  const newEmbedding = await getEmbedding(text);
  if (!newEmbedding) return result;

  cacheEmbedding(complaintId, newEmbedding);

  // Generate embeddings for existing complaints that don't have cached ones
  const similarities = [];

  for (const complaint of existingComplaints) {
    if (complaint.id === complaintId) continue;

    let existingEmbed = null;
    const cachedEmbeddings = getAllCachedEmbeddings();
    if (cachedEmbeddings.has(complaint.id)) {
      existingEmbed = cachedEmbeddings.get(complaint.id);
    } else {
      const compText = `${complaint.title} ${complaint.description}`;
      existingEmbed = await getEmbedding(compText);
      if (existingEmbed) cacheEmbedding(complaint.id, existingEmbed);
    }

    if (!existingEmbed) continue;

    const similarity = cosineSimilarity(newEmbedding, existingEmbed);
    similarities.push({ id: complaint.id, similarity });
  }

  // Sort by similarity descending
  similarities.sort((a, b) => b.similarity - a.similarity);

  for (const item of similarities) {
    if (item.similarity >= DUPLICATE_THRESHOLD) {
      if (!result.duplicateOf) result.duplicateOf = item.id;
      result.relatedComplaintIds.push(item.id);
    } else if (item.similarity >= RELATED_THRESHOLD) {
      result.relatedComplaintIds.push(item.id);
    }
    if (item.similarity > result.highestSimilarity) {
      result.highestSimilarity = item.similarity;
    }
  }

  result.clusterSize = result.relatedComplaintIds.length + 1;
  result.highestSimilarity = Math.round(result.highestSimilarity * 100) / 100;

  return result;
}

module.exports = { findDuplicates, DUPLICATE_THRESHOLD, RELATED_THRESHOLD };
