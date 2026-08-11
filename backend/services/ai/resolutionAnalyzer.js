/**
 * Resolution Analyzer — AI-powered resolution quality assessment
 */

const { getTextModel, isAIAvailable } = require("./geminiClient");

const RESOLUTION_PROMPT = `You are a civic resolution quality analyst. Evaluate this official resolution description for a civic complaint.

The complaint was about:
TITLE: {title}
DESCRIPTION: {description}
CATEGORY: {category}

The official's resolution description is:
"{resolution}"

Return a JSON object:
{
  "resolutionQualityScore": integer 0-100,
  "resolutionQuality": one of: "excellent", "good", "adequate", "poor", "insufficient",
  "isSpecific": boolean (mentions specific actions taken),
  "isActionOriented": boolean (describes what was done, not just "fixed"),
  "resolutionExplanation": string (1-2 sentence assessment)
}

Be fair. Short responses like "Fixed" should score low. Detailed action descriptions should score high.
Return ONLY valid JSON.`;

/**
 * Analyze the quality of an official's resolution description
 * @param {object} complaint
 * @param {string} resolutionDescription
 * @returns {object}
 */
async function analyzeResolution(complaint, resolutionDescription) {
  const fallback = {
    resolutionQualityScore: 50,
    resolutionQuality: "unknown",
    isSpecific: false,
    isActionOriented: false,
    resolutionExplanation: "Resolution quality analysis unavailable"
  };

  // Quick rule-based check for obviously poor resolutions
  const desc = (resolutionDescription || "").trim();
  if (desc.length < 10) {
    return {
      resolutionQualityScore: Math.max(5, desc.length * 2),
      resolutionQuality: "insufficient",
      isSpecific: false,
      isActionOriented: false,
      resolutionExplanation: "Resolution description is too vague. No specific actions mentioned."
    };
  }

  if (!isAIAvailable()) return fallback;
  const model = getTextModel();
  if (!model) return fallback;

  try {
    const prompt = RESOLUTION_PROMPT
      .replace("{title}", complaint.title || "")
      .replace("{description}", complaint.description || "")
      .replace("{category}", complaint.category || "")
      .replace("{resolution}", desc);

    const result = await Promise.race([
      model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.2, maxOutputTokens: 512 }
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Resolution analysis timeout")), 10000))
    ]);

    const parsed = JSON.parse(result.response.text());
    parsed.resolutionQualityScore = Math.min(100, Math.max(0, parseInt(parsed.resolutionQualityScore) || 50));
    return parsed;
  } catch (err) {
    console.error("[RESOLUTION] Analysis failed:", err.message);
    return fallback;
  }
}

module.exports = { analyzeResolution };
