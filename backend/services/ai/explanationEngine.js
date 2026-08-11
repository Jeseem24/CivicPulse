/**
 * Explanation Engine — Generates human-readable AI decision logs
 */

/**
 * Generate a decision log entry for an AI analysis
 * @param {string} complaintId
 * @param {object} fusedResult - Output from fusionEngine
 * @param {object} options
 * @returns {object} Decision log entry
 */
function generateDecisionLog(complaintId, fusedResult, options = {}) {
  const evidence = [];

  // Build evidence list
  if (fusedResult.severity) evidence.push(`Severity: ${fusedResult.severity.toUpperCase()}`);
  if (fusedResult.safetyRisk) evidence.push("Safety risk identified");
  if (fusedResult.affectedPopulation && fusedResult.affectedPopulation.length > 0) {
    evidence.push(`Affected: ${fusedResult.affectedPopulation.join(", ")}`);
  }
  if (fusedResult.riskFactors && fusedResult.riskFactors.length > 0) {
    evidence.push(`Risk factors: ${fusedResult.riskFactors.join(", ")}`);
  }
  if (fusedResult.visionAnalysis && fusedResult.visionAnalysis.detected) {
    evidence.push(`Visual: ${fusedResult.visionAnalysis.description}`);
  }
  if (fusedResult.duplicateInfo && fusedResult.duplicateInfo.clusterSize > 1) {
    evidence.push(`${fusedResult.duplicateInfo.clusterSize} related reports from citizens`);
  }
  if (fusedResult.inputDiscrepancy) {
    evidence.push(`⚠ ${fusedResult.discrepancyDetail}`);
  }

  // Build priority breakdown explanation
  const bd = fusedResult.priorityBreakdown || {};
  const breakdownText = [
    bd.severityScore ? `Severity: +${bd.severityScore}` : null,
    bd.urgencyScore ? `Urgency: +${bd.urgencyScore}` : null,
    bd.safetyScore ? `Safety: +${bd.safetyScore}` : null,
    bd.populationScore ? `Population: +${bd.populationScore}` : null,
    bd.visualScore ? `Visual: +${bd.visualScore}` : null,
    bd.relatedScore ? `Related reports: +${bd.relatedScore}` : null
  ].filter(Boolean);

  return {
    timestamp: new Date().toISOString(),
    complaintId,
    action: options.action || "AI_ANALYSIS",
    category: fusedResult.category,
    priority: fusedResult.priority,
    severity: fusedResult.severity,
    confidence: fusedResult.confidence,
    aiPowered: fusedResult.aiPowered,
    evidence,
    priorityBreakdown: breakdownText,
    reason: fusedResult.reason || "Analysis completed",
    recommendedAction: fusedResult.recommendedAction || "",
    slaMinutes: fusedResult.recommendedSlaMinutes
  };
}

/**
 * Generate a resolution verification log
 */
function generateResolutionLog(complaintId, resolutionAnalysis, verificationResult) {
  return {
    timestamp: new Date().toISOString(),
    complaintId,
    action: "RESOLUTION_VERIFICATION",
    resolutionQuality: resolutionAnalysis?.resolutionQuality || "unknown",
    resolutionScore: resolutionAnalysis?.resolutionQualityScore || 0,
    visualVerification: verificationResult || null,
    reason: resolutionAnalysis?.resolutionExplanation || ""
  };
}

/**
 * Generate an SLA breach log
 */
function generateSLABreachLog(complaintId, breachInfo) {
  return {
    timestamp: new Date().toISOString(),
    complaintId,
    action: "SLA_BREACH",
    overdueHours: breachInfo.overdueHours,
    reason: breachInfo.reason
  };
}

module.exports = { generateDecisionLog, generateResolutionLog, generateSLABreachLog };
