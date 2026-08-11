/**
 * SLA Engine — Recommends response windows and detects breaches
 */

const SLA_POLICY = {
  critical: 120,     // 2 hours
  high: 480,         // 8 hours
  medium: 1440,      // 24 hours
  low: 4320          // 72 hours
};

/**
 * Calculate SLA recommendation
 * @param {string} severity
 * @param {boolean} safetyRisk
 * @returns {{ recommendedSlaMinutes: number, slaDeadline: string, slaLevel: string }}
 */
function calculateSLA(severity = "medium", safetyRisk = false, createdAt = null) {
  let slaMinutes = SLA_POLICY[severity] || SLA_POLICY.medium;

  // Safety risk cuts SLA by 50%
  if (safetyRisk && severity !== "critical") {
    slaMinutes = Math.round(slaMinutes * 0.5);
  }

  const created = createdAt ? new Date(createdAt) : new Date();
  const deadline = new Date(created.getTime() + slaMinutes * 60000);

  return {
    recommendedSlaMinutes: slaMinutes,
    slaDeadline: deadline.toISOString(),
    slaLevel: severity
  };
}

/**
 * Check if a complaint has breached its SLA
 * @param {object} complaint
 * @returns {object}
 */
function checkSLABreach(complaint) {
  const resolvedStatuses = ["verified", "closed", "resolved", "awaiting_verification"];
  if (resolvedStatuses.includes(complaint.status)) {
    return { breached: false, reason: "Complaint is resolved/verified" };
  }

  const slaDeadline = complaint.aiAnalysis?.slaDeadline || complaint.slaDeadline;
  if (!slaDeadline) {
    return { breached: false, reason: "No SLA deadline set" };
  }

  const now = new Date();
  const deadline = new Date(slaDeadline);
  const breached = now > deadline;
  const overdueMins = breached ? Math.round((now - deadline) / 60000) : 0;

  return {
    breached,
    overdueMinutes: overdueMins,
    overdueHours: Math.round(overdueMins / 60 * 10) / 10,
    reason: breached
      ? `SLA breached by ${Math.round(overdueMins / 60 * 10) / 10} hours`
      : `${Math.round((deadline - now) / 60000)} minutes remaining`
  };
}

module.exports = { calculateSLA, checkSLABreach, SLA_POLICY };
