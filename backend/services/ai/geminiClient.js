/**
 * Gemini AI Client — Singleton initialization
 * Provides text generation, vision, and embedding models.
 * Returns null clients if GEMINI_API_KEY is not set (enables graceful fallback).
 */

const { GoogleGenerativeAI } = require("@google/generative-ai");

let genAI = null;
let textModel = null;
let visionModel = null;
let embeddingModel = null;
let isAvailable = false;

function initGemini() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.log("[AI] GEMINI_API_KEY not set. AI features disabled — using rule-based fallback.");
    return;
  }
  try {
    genAI = new GoogleGenerativeAI(apiKey);
    textModel = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    visionModel = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004" });
    isAvailable = true;
    console.log("[AI] Gemini AI initialized successfully (gemini-2.0-flash + text-embedding-004).");
  } catch (err) {
    console.error("[AI] Gemini init failed:", err.message);
    isAvailable = false;
  }
}

initGemini();

module.exports = {
  getTextModel: () => textModel,
  getVisionModel: () => visionModel,
  getEmbeddingModel: () => embeddingModel,
  isAIAvailable: () => isAvailable
};
