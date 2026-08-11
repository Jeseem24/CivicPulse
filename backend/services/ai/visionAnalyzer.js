/**
 * Vision Analyzer — Image analysis via Gemini multimodal
 * Analyzes complaint photos for damage type, severity, and quality.
 */

const { getVisionModel, isAIAvailable } = require("./geminiClient");
const https = require("https");
const http = require("http");

const VISION_PROMPT = `You are a civic infrastructure damage analyst. Analyze this image of a reported civic problem.

Return a JSON object with these exact fields:
{
  "detected": boolean (true if a civic issue is visible),
  "damageType": string (e.g. "pothole", "garbage_pile", "water_leak", "broken_infrastructure", "electrical_hazard", "flooding", "none"),
  "visualSeverity": integer 0-100 (how severe the visible damage appears),
  "description": string (1-2 sentence description of what you see),
  "objects": array of strings (notable objects/features in image),
  "imageQuality": one of: "good", "fair", "poor", "unusable",
  "confidence": number 0.0-1.0
}

Be accurate. If the image is unclear or doesn't show a civic issue, say so. Return ONLY valid JSON.`;

const COMPARISON_PROMPT = `You are a civic repair verification analyst. Compare these two images:

IMAGE 1: BEFORE (the original damage/problem)
IMAGE 2: AFTER (the claimed repair/fix)

Return a JSON object:
{
  "damageBeforeScore": integer 0-100 (damage visible in before image),
  "damageAfterScore": integer 0-100 (damage visible in after image),
  "visualRepairConfidence": integer 0-100 (confidence that repair was performed),
  "visualChangeDetected": boolean,
  "repairDescription": string (what changed between images),
  "possibleFalseResolution": boolean (true if damage appears to remain),
  "explanation": string
}

Return ONLY valid JSON.`;

/**
 * Download image from URL and return as base64
 */
async function downloadImageAsBase64(imageUrl) {
  return new Promise((resolve, reject) => {
    const client = imageUrl.startsWith("https") ? https : http;
    const req = client.get(imageUrl, {
      headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) CivicPulse/1.0" },
      timeout: 8000
    }, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      const chunks = [];
      res.on("data", chunk => chunks.push(chunk));
      res.on("end", () => {
        const buffer = Buffer.concat(chunks);
        const contentType = res.headers["content-type"] || "image/jpeg";
        resolve({ base64: buffer.toString("base64"), mimeType: contentType.split(";")[0] });
      });
    });
    req.on("error", reject);
    req.on("timeout", () => { req.destroy(); reject(new Error("Image download timeout")); });
  });
}

/**
 * Analyze a single complaint image
 * @param {string} imageUrl
 * @returns {object} Vision analysis result
 */
async function analyzeImage(imageUrl) {
  const fallback = {
    available: false, detected: false, damageType: "unknown",
    visualSeverity: 0, description: "Vision analysis unavailable",
    objects: [], imageQuality: "unknown", confidence: 0
  };

  if (!isAIAvailable() || !imageUrl || imageUrl === "") return fallback;

  const model = getVisionModel();
  if (!model) return fallback;

  try {
    const { base64, mimeType } = await downloadImageAsBase64(imageUrl);

    const result = await Promise.race([
      model.generateContent({
        contents: [{
          role: "user",
          parts: [
            { inlineData: { data: base64, mimeType } },
            { text: VISION_PROMPT }
          ]
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.1, maxOutputTokens: 1024 }
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Vision timeout")), 15000))
    ]);

    const text = result.response.text();
    const parsed = JSON.parse(text);

    return {
      available: true,
      detected: !!parsed.detected,
      damageType: parsed.damageType || "unknown",
      visualSeverity: Math.min(100, Math.max(0, parseInt(parsed.visualSeverity) || 0)),
      description: parsed.description || "",
      objects: Array.isArray(parsed.objects) ? parsed.objects : [],
      imageQuality: parsed.imageQuality || "unknown",
      confidence: Math.min(1, Math.max(0, parseFloat(parsed.confidence) || 0))
    };
  } catch (err) {
    console.error("[VISION] Image analysis failed:", err.message);
    return fallback;
  }
}

/**
 * Compare before/after images for resolution verification
 * @param {string} beforeUrl
 * @param {string} afterUrl
 * @returns {object}
 */
async function compareBeforeAfter(beforeUrl, afterUrl) {
  const fallback = {
    available: false, damageBeforeScore: 0, damageAfterScore: 0,
    visualRepairConfidence: 0, visualChangeDetected: false,
    repairDescription: "Comparison unavailable", possibleFalseResolution: false,
    explanation: "Vision comparison unavailable"
  };

  if (!isAIAvailable() || !beforeUrl || !afterUrl) return fallback;

  const model = getVisionModel();
  if (!model) return fallback;

  try {
    const [before, after] = await Promise.all([
      downloadImageAsBase64(beforeUrl),
      downloadImageAsBase64(afterUrl)
    ]);

    const result = await Promise.race([
      model.generateContent({
        contents: [{
          role: "user",
          parts: [
            { inlineData: { data: before.base64, mimeType: before.mimeType } },
            { inlineData: { data: after.base64, mimeType: after.mimeType } },
            { text: COMPARISON_PROMPT }
          ]
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.1, maxOutputTokens: 1024 }
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Comparison timeout")), 20000))
    ]);

    const text = result.response.text();
    const parsed = JSON.parse(text);
    parsed.available = true;
    return parsed;
  } catch (err) {
    console.error("[VISION] Before/after comparison failed:", err.message);
    return fallback;
  }
}

module.exports = { analyzeImage, compareBeforeAfter };
