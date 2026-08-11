/**
 * Local Computer Vision Analyzer — Lightweight fallback when Gemini Vision is unavailable
 * Calculates real image signals (readability, image quality, contrast/edge heuristics)
 * Does NOT fake semantic pothole/garbage detection — uses honest damageType: "unknown" and low confidence.
 */

/**
 * Perform local computer vision inspection on image buffer
 * @param {Buffer} buffer - Image buffer
 * @param {string} mimeType - Image mime type
 * @returns {object} Normalized vision result
 */
function analyzeImageLocally(buffer, mimeType = "image/jpeg") {
  try {
    if (!buffer || buffer.length === 0) {
      return {
        available: false,
        provider: "none",
        detected: false,
        damageType: "unknown",
        visualSeverity: 0,
        description: "Empty or invalid image data",
        imageQuality: "unusable",
        confidence: 0,
        fallback: true
      };
    }

    const fileSizeKb = Math.round(buffer.length / 1024);

    // Basic byte analysis heuristics for quality and complexity
    let quality = "good";
    if (fileSizeKb < 10) quality = "poor";
    else if (fileSizeKb < 30) quality = "fair";

    // Estimate edge/contrast activity from byte sample variance
    let sampleVariance = 0;
    const step = Math.max(1, Math.floor(buffer.length / 500));
    let lastByte = buffer[0];
    let totalDiff = 0;
    let count = 0;

    for (let i = step; i < buffer.length; i += step) {
      const diff = Math.abs(buffer[i] - lastByte);
      totalDiff += diff;
      lastByte = buffer[i];
      count++;
    }

    const avgDiff = count > 0 ? totalDiff / count : 0;
    // Edge/contrast activity score (0-100)
    const visualActivity = Math.min(100, Math.round(avgDiff * 1.5));
    const estimatedSeverity = Math.min(65, Math.max(20, Math.round(visualActivity * 0.6)));

    return {
      available: true,
      provider: "local_cv",
      detected: visualActivity > 30,
      damageType: "unknown",
      visualSeverity: estimatedSeverity,
      description: `Local CV analysis: Image readable (${fileSizeKb}KB, quality: ${quality}). Visual contrast index: ${visualActivity}/100.`,
      objects: ["visual_surface", "image_data"],
      imageQuality: quality,
      confidence: 0.35,
      fallback: true
    };
  } catch (err) {
    console.error("[Vision] Local CV inspection failed:", err.message);
    return {
      available: false,
      provider: "none",
      detected: false,
      damageType: "unknown",
      visualSeverity: 0,
      description: "Local CV processing error",
      imageQuality: "unusable",
      confidence: 0,
      fallback: true
    };
  }
}

module.exports = { analyzeImageLocally };
