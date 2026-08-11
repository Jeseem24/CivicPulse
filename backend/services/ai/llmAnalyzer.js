/**
 * LLM Analyzer — Semantic complaint understanding via Gemini
 * Returns structured AI analysis or null on failure (triggers rule fallback).
 */

const { getTextModel, isAIAvailable } = require("./geminiClient");

const ALLOWED_CATEGORIES = ["Roads", "Sanitation", "Water", "Electricity", "Public Infrastructure"];
const ALLOWED_SEVERITIES = ["low", "medium", "high", "critical"];
const ALLOWED_URGENCIES = ["routine", "soon", "urgent", "immediate"];

const SYSTEM_PROMPT = `You are CivicAgent, an AI civic complaint analyst for a Smart Public Complaint Management System called CivicPulse.

Analyze the following civic complaint and return a JSON object with these exact fields:

{
  "category": one of: "Roads", "Sanitation", "Water", "Electricity", "Public Infrastructure",
  "severity": one of: "low", "medium", "high", "critical",
  "urgency": one of: "routine", "soon", "urgent", "immediate",
  "safetyRisk": boolean,
  "affectedPopulation": array of strings (e.g. ["students", "pedestrians", "motorists", "residents"]),
  "riskFactors": array of strings (specific risk factors identified),
  "confidence": number between 0.0 and 1.0,
  "recommendedAction": string (1-2 sentence recommended action),
  "recommendedSlaMinutes": integer (recommended response time in minutes),
  "reason": string (2-3 sentence explanation of your analysis)
}

Be precise. Assess actual severity — do not inflate. A minor pothole is NOT critical. A large pothole near a school IS critical.
Only mark safetyRisk:true when there is genuine danger to people.
Return ONLY valid JSON, no markdown.`;

/**
 * Analyze complaint text using Gemini LLM
 * @param {string} title
 * @param {string} description
 * @returns {object|null} Structured analysis or null on failure
 */
async function analyzeLLM(title, description) {
  if (!isAIAvailable()) return null;
  
  const model = getTextModel();
  if (!model) return null;

  try {
    const prompt = `${SYSTEM_PROMPT}\n\nComplaint Title: ${title}\nComplaint Description: ${description}`;
    
    const result = await Promise.race([
      model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0.2,
          maxOutputTokens: 1024
        }
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("LLM timeout")), 12000))
    ]);

    const text = result.response.text();
    const parsed = JSON.parse(text);

    // Validate critical fields
    return validateLLMOutput(parsed);
  } catch (err) {
    console.error("[LLM] Analysis failed:", err.message);
    return null;
  }
}

/**
 * Validate and sanitize LLM output
 */
function validateLLMOutput(data) {
  if (!data || typeof data !== "object") return null;

  // Validate category
  if (!ALLOWED_CATEGORIES.includes(data.category)) {
    data.category = "Public Infrastructure";
  }
  // Validate severity
  if (!ALLOWED_SEVERITIES.includes(data.severity)) {
    data.severity = "medium";
  }
  // Validate urgency
  if (!ALLOWED_URGENCIES.includes(data.urgency)) {
    data.urgency = "routine";
  }
  // Validate confidence
  if (typeof data.confidence !== "number" || data.confidence < 0 || data.confidence > 1) {
    data.confidence = 0.5;
  }
  // Validate safetyRisk
  data.safetyRisk = !!data.safetyRisk;
  // Validate arrays
  if (!Array.isArray(data.affectedPopulation)) data.affectedPopulation = [];
  if (!Array.isArray(data.riskFactors)) data.riskFactors = [];
  // Validate SLA
  if (typeof data.recommendedSlaMinutes !== "number" || data.recommendedSlaMinutes < 30) {
    data.recommendedSlaMinutes = 1440; // default 24h
  }
  // Validate strings
  if (typeof data.recommendedAction !== "string") data.recommendedAction = "";
  if (typeof data.reason !== "string") data.reason = "";

  return data;
}

module.exports = { analyzeLLM, ALLOWED_CATEGORIES, ALLOWED_SEVERITIES, ALLOWED_URGENCIES };
