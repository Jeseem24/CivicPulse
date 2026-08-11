/**
 * Fusion Engine — Combines text AI + vision AI + context into final analysis
 * Detects discrepancies between text and vision analysis.
 */

const { calculateAIPriority } = require("./priorityEngine");

const CATEGORY_TO_DEPARTMENT = {
  "Roads": "Roads Dept",
  "Sanitation": "Sanitation Dept",
  "Water": "Water Dept",
  "Electricity": "Electricity Dept",
  "Public Infrastructure": "Public Infrastructure Dept"
};

/**
 * Fuse multiple AI signal sources into a single coherent analysis
 * @param {object} params
 * @returns {object} Fused analysis result
 */
function fuseAnalysis({ llmResult, visionResult, duplicateResult, ruleResult }) {
  // Start with LLM result as primary, rule-based as fallback
  const primary = llmResult || {};
  const vision = visionResult || {};
  const dupe = duplicateResult || {};

  // Category: prefer LLM, fallback to rule-based
  const category = primary.category || ruleResult.category;
  const department = CATEGORY_TO_DEPARTMENT[category] || ruleResult.department;

  // Detect text-vision discrepancy
  let inputDiscrepancy = false;
  let discrepancyDetail = null;

  if (vision.available && vision.detected && primary.severity) {
    // Check if text says low but vision shows high damage
    const textSeverityNum = { low: 1, medium: 2, high: 3, critical: 4 }[primary.severity] || 2;
    const visionSeverityLevel = vision.visualSeverity > 70 ? 4 : vision.visualSeverity > 50 ? 3 : vision.visualSeverity > 25 ? 2 : 1;

    if (Math.abs(textSeverityNum - visionSeverityLevel) >= 2) {
      inputDiscrepancy = true;
      discrepancyDetail = `Text indicates ${primary.severity} severity, but image analysis suggests ${
        visionSeverityLevel >= 3 ? "higher" : "lower"
      } severity (visual score: ${vision.visualSeverity}/100).`;
    }
  }

  // Calculate fused priority using priority engine
  const { priority, breakdown } = calculateAIPriority({
    severity: primary.severity || "medium",
    urgency: primary.urgency || "routine",
    safetyRisk: primary.safetyRisk || false,
    affectedPopulation: primary.affectedPopulation || [],
    visualSeverity: (vision.available && vision.detected) ? vision.visualSeverity : 0,
    relatedCount: dupe.clusterSize ? dupe.clusterSize - 1 : 0,
    riskFactors: primary.riskFactors || []
  });

  // If vision detected higher severity, boost priority
  let adjustedPriority = priority;
  if (inputDiscrepancy && vision.visualSeverity > 60) {
    adjustedPriority = Math.min(100, priority + 10);
  }

  // Build confidence
  const confidences = [];
  if (primary.confidence) confidences.push(primary.confidence);
  if (vision.available && vision.confidence) confidences.push(vision.confidence);
  const overallConfidence = confidences.length > 0
    ? Math.round((confidences.reduce((a, b) => a + b, 0) / confidences.length) * 100) / 100
    : 0.5;

  return {
    category,
    priority: adjustedPriority,
    department,
    severity: primary.severity || "medium",
    urgency: primary.urgency || "routine",
    safetyRisk: primary.safetyRisk || false,
    affectedPopulation: primary.affectedPopulation || [],
    riskFactors: primary.riskFactors || [],
    confidence: overallConfidence,
    recommendedAction: primary.recommendedAction || "",
    recommendedSlaMinutes: primary.recommendedSlaMinutes || 1440,
    reason: primary.reason || ruleResult.reason || "",
    priorityBreakdown: breakdown,
    visionAnalysis: vision.available ? vision : null,
    duplicateInfo: dupe.relatedComplaintIds && dupe.relatedComplaintIds.length > 0 ? dupe : null,
    inputDiscrepancy,
    discrepancyDetail,
    aiPowered: !!llmResult,
    textConfidence: primary.confidence || 0,
    visionConfidence: (vision.available && vision.confidence) ? vision.confidence : 0
  };
}

module.exports = { fuseAnalysis, CATEGORY_TO_DEPARTMENT };
