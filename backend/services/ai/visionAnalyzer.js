/**
 * Demo-Safe Vision Analyzer Architecture for CivicPulse
 * Hierarchy: Demo Cache → Gemini Vision (Primary + Bounded Retries) → Local CV Fallback → Text/Rule Fallback
 */

const { getVisionModel, isAIAvailable } = require("./geminiClient");
const { getDemoCacheResult } = require("./demoVisionCache");
const { analyzeImageLocally } = require("./localCvAnalyzer");
const https = require("https");
const http = require("http");
const fs = require("fs");
const path = require("path");

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
 * Download remote HTTP/HTTPS image as base64 and buffer
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
        resolve({
          buffer,
          base64: buffer.toString("base64"),
          mimeType: contentType.split(";")[0]
        });
      });
    });
    req.on("error", reject);
    req.on("timeout", () => { req.destroy(); reject(new Error("Image download timeout")); });
  });
}

/**
 * Resolve image bytes from HTTP URL, Local File Path, Data URI, or Base64 string
 */
async function resolveImageBytes(imageInput) {
  if (!imageInput || typeof imageInput !== "string" || imageInput.trim() === "") {
    throw new Error("No image input provided");
  }

  const str = imageInput.trim();

  // 1. Data URI (e.g. data:image/png;base64,iVBORw0KG...)
  if (str.startsWith("data:image/")) {
    const parts = str.split(";base64,");
    if (parts.length === 2) {
      const mimeType = parts[0].replace("data:", "");
      const buffer = Buffer.from(parts[1], "base64");
      return { buffer, mimeType, base64: parts[1] };
    }
  }

  // 2. Local File Path (e.g. C:\Users\... or file:///C:/...)
  let localPath = str;
  if (localPath.startsWith("file:///")) {
    localPath = localPath.replace("file:///", "");
  }

  if (fs.existsSync(localPath)) {
    const buffer = fs.readFileSync(localPath);
    const ext = path.extname(localPath).toLowerCase();
    const mimeType = ext === ".png" ? "image/png" : ext === ".webp" ? "image/webp" : "image/jpeg";
    return { buffer, mimeType, base64: buffer.toString("base64") };
  }

  // 3. Remote HTTP/HTTPS URL
  if (str.startsWith("http://") || str.startsWith("https://")) {
    return await downloadImageAsBase64(str);
  }

  // 4. Direct raw base64 string (>100 chars, no spaces)
  if (str.length > 100 && !str.includes(" ")) {
    const buffer = Buffer.from(str, "base64");
    return { buffer, mimeType: "image/jpeg", base64: str };
  }

  throw new Error(`Unsupported image input format: ${str.substring(0, 30)}...`);
}

/**
 * Bounded Retry Helper for Gemini API Calls
 * Retries up to 3 times on transient errors (503, 429, 500, 502, 504)
 */
async function callGeminiVisionWithRetry(model, parts, maxAttempts = 3) {
  let lastError = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      console.log(`[Vision] Gemini Vision call attempt ${attempt}/${maxAttempts}...`);
      const result = await Promise.race([
        model.generateContent({
          contents: [{ role: "user", parts }],
          generationConfig: { responseMimeType: "application/json", temperature: 0.1, maxOutputTokens: 1024 }
        }),
        new Promise((_, reject) => setTimeout(() => reject(new Error("Vision timeout")), 12000))
      ]);
      return result;
    } catch (err) {
      lastError = err;
      const isTransient = /503|429|500|502|504|timeout|Service Unavailable/i.test(err.message);

      if (isTransient && attempt < maxAttempts) {
        const delayMs = attempt * 1000;
        console.log(`[Vision] Transient error (${err.message}). Retrying in ${delayMs}ms...`);
        await new Promise(r => setTimeout(r, delayMs));
      } else {
        throw err;
      }
    }
  }

  throw lastError;
}

/**
 * Analyze a single complaint image with robust multi-layer fallback
 * Fallback Hierarchy: Demo Cache → Gemini Vision → Local CV → No Vision
 *
 * @param {string} imageInput
 * @returns {object} Normalized vision result
 */
async function analyzeImage(imageInput) {
  const noVisionFallback = {
    available: false,
    provider: "none",
    detected: false,
    damageType: "unknown",
    visualSeverity: 0,
    description: "Vision analysis unavailable — using text/rule-based analysis",
    objects: [],
    imageQuality: "unknown",
    confidence: 0,
    fallback: true
  };

  if (!imageInput || typeof imageInput !== "string" || imageInput.trim() === "") {
    return noVisionFallback;
  }

  // ── LAYER 1: Demo Cache Match ──
  const cachedDemo = getDemoCacheResult(imageInput);
  if (cachedDemo) {
    console.log("[Vision] Demo cache hit — Provider: demo");
    return cachedDemo;
  }

  // Resolve image bytes first (needed for Gemini & Local CV)
  let imageBytes = null;
  try {
    imageBytes = await resolveImageBytes(imageInput);
  } catch (err) {
    console.log(`[Vision] Image load failed (${err.message}) — using text/rule-based analysis`);
    return noVisionFallback;
  }

  // ── LAYER 2: Gemini Vision Primary (with Bounded Retry) ──
  if (isAIAvailable()) {
    const model = getVisionModel();
    if (model) {
      try {
        const parts = [
          { inlineData: { data: imageBytes.base64, mimeType: imageBytes.mimeType } },
          { text: VISION_PROMPT }
        ];

        const result = await callGeminiVisionWithRetry(model, parts, 3);
        const text = result.response.text();
        const parsed = JSON.parse(text);

        console.log("[Vision] Provider: Gemini — Analysis successful");

        return {
          available: true,
          provider: "gemini",
          detected: !!parsed.detected,
          damageType: parsed.damageType || "unknown",
          visualSeverity: Math.min(100, Math.max(0, parseInt(parsed.visualSeverity) || 0)),
          description: parsed.description || "",
          objects: Array.isArray(parsed.objects) ? parsed.objects : [],
          imageQuality: parsed.imageQuality || "good",
          confidence: Math.min(1, Math.max(0, parseFloat(parsed.confidence) || 0.9)),
          fallback: false
        };
      } catch (err) {
        console.log(`[Vision] Gemini unavailable (${err.message}) — Falling back to Local CV`);
      }
    }
  }

  // ── LAYER 3: Local CV Fallback ──
  if (imageBytes && imageBytes.buffer) {
    console.log("[Vision] Provider: local_cv — Analysis successful");
    return analyzeImageLocally(imageBytes.buffer, imageBytes.mimeType);
  }

  // ── LAYER 4: No Vision ──
  console.log("[Vision] Vision unavailable — using text/rule-based analysis");
  return noVisionFallback;
}

/**
 * Compare before/after images for resolution verification
 */
async function compareBeforeAfter(beforeInput, afterInput) {
  const fallback = {
    available: false,
    provider: "none",
    damageBeforeScore: 0,
    damageAfterScore: 0,
    visualRepairConfidence: 0,
    visualChangeDetected: false,
    repairDescription: "Comparison unavailable",
    possibleFalseResolution: false,
    explanation: "Vision comparison unavailable"
  };

  if (!beforeInput || !afterInput) return fallback;

  if (isAIAvailable()) {
    const model = getVisionModel();
    if (model) {
      try {
        const [before, after] = await Promise.all([
          resolveImageBytes(beforeInput),
          resolveImageBytes(afterInput)
        ]);

        const parts = [
          { inlineData: { data: before.base64, mimeType: before.mimeType } },
          { inlineData: { data: after.base64, mimeType: after.mimeType } },
          { text: COMPARISON_PROMPT }
        ];

        const result = await callGeminiVisionWithRetry(model, parts, 2);
        const parsed = JSON.parse(result.response.text());
        parsed.available = true;
        parsed.provider = "gemini";
        return parsed;
      } catch (err) {
        console.log(`[Vision] Comparison failed (${err.message})`);
      }
    }
  }

  return fallback;
}

module.exports = { analyzeImage, compareBeforeAfter, resolveImageBytes };
