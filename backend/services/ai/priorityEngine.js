/**
 * Priority Engine — Transparent weighted scoring (0-100)
 * Combines multiple AI signals into a meaningful, differentiated priority.
 */

const SEVERITY_SCORES = { low: 5, medium: 12, high: 20, critical: 25 };
const URGENCY_SCORES = { routine: 3, soon: 8, urgent: 15, immediate: 20 };

/**
 * Calculate priority from AI signals. Produces meaningful differentiation:
 *   low issue: 20-40   |  moderate: 40-65  |  high: 65-85  |  critical: 85-100
 *
 * @param {object} params
 * @returns {{ priority: number, breakdown: object }}
 */
function calculateAIPriority({
  severity = "medium",
  urgency = "routine",
  safetyRisk = false,
  affectedPopulation = [],
  visualSeverity = 0,
  relatedCount = 0,
  riskFactors = []
}) {
  const breakdown = {};

  // Semantic severity (0-25)
  breakdown.severityScore = SEVERITY_SCORES[severity] || 12;

  // Urgency (0-20)
  breakdown.urgencyScore = URGENCY_SCORES[urgency] || 3;

  // Safety risk (0-20)
  breakdown.safetyScore = safetyRisk ? 20 : 0;

  // Affected population (0-15)
  const vulnGroups = ["children", "students", "elderly", "patients", "disabled"];
  const vulnCount = affectedPopulation.filter(p => vulnGroups.some(v => p.toLowerCase().includes(v))).length;
  breakdown.populationScore = Math.min(15, affectedPopulation.length * 3 + vulnCount * 4);

  // Visual severity (0-10)
  breakdown.visualScore = Math.round(visualSeverity / 10);

  // Related reports boost (0-10)
  breakdown.relatedScore = Math.min(10, relatedCount * 2);

  // Sum
  const raw = breakdown.severityScore + breakdown.urgencyScore + breakdown.safetyScore
    + breakdown.populationScore + breakdown.visualScore + breakdown.relatedScore;

  // Clamp to 0-100
  const priority = Math.min(100, Math.max(0, raw));

  return { priority, breakdown };
}

module.exports = { calculateAIPriority };
