/**
 * Analytics Service — Aggregates civic intelligence metrics
 */

const db = require("../config/db");
const { checkSLABreach } = require("./ai/slaEngine");
const { getHotspots } = require("./geoService");

/**
 * Generate comprehensive analytics from all complaints and departments
 * @returns {object}
 */
async function getAnalytics() {
  const [complaints, departments] = await Promise.all([
    db.getComplaints({}),
    db.getDepartments()
  ]);

  const now = new Date();

  // Basic counts
  const total = complaints.length;
  const byStatus = {};
  const byCategory = {};
  const byDepartment = {};
  let criticalCount = 0;
  let slaBreaches = 0;
  let totalResolutionTimeMs = 0;
  let resolvedWithTimeCount = 0;

  for (const c of complaints) {
    // Status distribution
    byStatus[c.status] = (byStatus[c.status] || 0) + 1;

    // Category distribution
    byCategory[c.category] = (byCategory[c.category] || 0) + 1;

    // Department distribution
    byDepartment[c.department] = (byDepartment[c.department] || 0) + 1;

    // Critical
    if (c.priority >= 85 || (c.aiAnalysis && c.aiAnalysis.severity === "critical")) {
      criticalCount++;
    }

    // SLA breaches
    const breach = checkSLABreach(c);
    if (breach.breached) slaBreaches++;

    // Resolution time
    if (c.resolution && c.resolution.resolvedAt && c.createdAt) {
      const resTime = new Date(c.resolution.resolvedAt) - new Date(c.createdAt);
      if (resTime > 0) {
        totalResolutionTimeMs += resTime;
        resolvedWithTimeCount++;
      }
    }
  }

  const avgResolutionHours = resolvedWithTimeCount > 0
    ? Math.round(totalResolutionTimeMs / resolvedWithTimeCount / 3600000 * 10) / 10
    : null;

  // Department performance
  const departmentPerformance = departments.map(dept => ({
    name: dept.name,
    trustScore: dept.trustScore,
    totalComplaints: dept.totalComplaints,
    resolvedCount: dept.resolvedCount,
    reopenCount: dept.reopenCount,
    resolutionRate: dept.totalComplaints > 0
      ? Math.round(dept.resolvedCount / dept.totalComplaints * 100) : 0
  }));

  // Hotspots
  const hotspots = getHotspots(complaints);

  // Top unresolved critical
  const unresolvedCritical = complaints
    .filter(c => !["verified", "closed"].includes(c.status) && c.priority >= 70)
    .sort((a, b) => b.priority - a.priority)
    .slice(0, 10)
    .map(c => ({ id: c.id, title: c.title, priority: c.priority, category: c.category, department: c.department, status: c.status }));

  return {
    summary: {
      total,
      open: (byStatus.assigned || 0) + (byStatus.reopened || 0) + (byStatus.in_progress || 0),
      resolved: (byStatus.verified || 0) + (byStatus.closed || 0),
      awaiting: byStatus.awaiting_verification || 0,
      reopened: byStatus.reopened || 0,
      critical: criticalCount,
      slaBreaches,
      avgResolutionHours
    },
    byStatus,
    byCategory,
    byDepartment,
    departmentPerformance,
    hotspots: hotspots.slice(0, 5),
    unresolvedCritical,
    generatedAt: now.toISOString()
  };
}

module.exports = { getAnalytics };
