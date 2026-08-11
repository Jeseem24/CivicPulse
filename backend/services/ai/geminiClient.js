/**
 * Gemini AI Client — Singleton initialization
 * Provides text generation, vision, and embedding models.
 * Returns null clients if GEMINI_API_KEY is not set (enables graceful fallback).
 */

require("dotenv").config();
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
    textModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    visionModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    embeddingModel = genAI.getGenerativeModel({ model: "embedding-001" });
    isAvailable = true;
    console.log("[AI] Gemini AI initialized successfully (gemini-2.5-flash + embedding-001).");
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
