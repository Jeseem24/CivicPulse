/**
 * AI-Specific Test Suite for CivicPulse Backend Upgrade
 * Tests AI pipeline, fallback behavior, fusion, SLA, resolution quality, and analytics.
 */

const { analyzeComplaint, analyzeComplaintAI, ruleBasedAnalysis } = require("./logic/civicAgent");
const { calculateAIPriority } = require("./services/ai/priorityEngine");
const { calculateSLA, checkSLABreach } = require("./services/ai/slaEngine");
const { fuseAnalysis } = require("./services/ai/fusionEngine");
const { generateDecisionLog } = require("./services/ai/explanationEngine");
const { haversineDistance, getNearbyComplaints, getHotspots } = require("./services/geoService");
const { getAnalytics } = require("./services/analyticsService");
const db = require("./config/db");

async function runAITests() {
  console.log("==================================================");
  console.log("🧠 Running AI Backend Verification Tests");
  console.log("==================================================\n");

  let passed = 0;
  let failed = 0;

  function check(name, condition) {
    if (condition) {
      console.log(`  ✅ ${name}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${name}`);
      failed++;
    }
  }

  // ── Test 1: Backward Compatibility ──
  console.log("\n[1] BACKWARD COMPATIBILITY");
  const syncResult = analyzeComplaint("Pothole on Main Street", "Deep hole in road");
  check("analyzeComplaint returns category", syncResult.category === "Roads");
  check("analyzeComplaint returns department", syncResult.department === "Roads Dept");
  check("analyzeComplaint returns priority > 0", syncResult.priority > 0);

  // ── Test 2: Rule-Based Fallback ──
  console.log("\n[2] RULE-BASED FALLBACK");
  const ruleRes = ruleBasedAnalysis("Garbage everywhere", "Trash piled up in the park");
  check("Rule fallback: Sanitation category", ruleRes.category === "Sanitation");
  check("Rule fallback: Sanitation Dept", ruleRes.department === "Sanitation Dept");

  // ── Test 3: Priority Engine Differentiation ──
  console.log("\n[3] PRIORITY ENGINE DIFFERENTIATION");
  const lowPriority = calculateAIPriority({ severity: "low", urgency: "routine", safetyRisk: false, affectedPopulation: [] });
  const highPriority = calculateAIPriority({ severity: "critical", urgency: "immediate", safetyRisk: true, affectedPopulation: ["children", "students"], visualSeverity: 80, relatedCount: 5 });
  check(`Low priority = ${lowPriority.priority} (expected 8-40)`, lowPriority.priority >= 8 && lowPriority.priority <= 40);
  check(`High priority = ${highPriority.priority} (expected 70-100)`, highPriority.priority >= 70 && highPriority.priority <= 100);
  check("Low < High priority", lowPriority.priority < highPriority.priority);
  check("Priority breakdown has components", Object.keys(lowPriority.breakdown).length >= 4);

  // ── Test 4: Fusion Engine ──
  console.log("\n[4] FUSION ENGINE");
  const fusedResult = fuseAnalysis({
    llmResult: {
      category: "Roads", severity: "critical", urgency: "immediate",
      safetyRisk: true, affectedPopulation: ["students"], riskFactors: ["school", "accident"],
      confidence: 0.95, recommendedAction: "Immediate repair", recommendedSlaMinutes: 120,
      reason: "Large pothole near school"
    },
    visionResult: { available: true, detected: true, visualSeverity: 85, description: "Large pothole visible", confidence: 0.9, damageType: "pothole", imageQuality: "good", objects: ["road", "hole"] },
    duplicateResult: { duplicateOf: null, relatedComplaintIds: ["CP-001", "CP-002"], highestSimilarity: 0.82, clusterSize: 3 },
    ruleResult: { category: "Roads", priority: 50, department: "Roads Dept", reason: "keyword match" }
  });
  check("Fused category = Roads", fusedResult.category === "Roads");
  check("Fused department = Roads Dept", fusedResult.department === "Roads Dept");
  check(`Fused priority = ${fusedResult.priority} (expected >= 80)`, fusedResult.priority >= 80);
  check("Fused is AI powered", fusedResult.aiPowered === true);
  check("Fused has vision analysis", fusedResult.visionAnalysis !== null);
  check("Fused has duplicate info", fusedResult.duplicateInfo !== null);

  // ── Test 5: Text-Vision Discrepancy Detection ──
  console.log("\n[5] DISCREPANCY DETECTION");
  const discrepancy = fuseAnalysis({
    llmResult: { category: "Roads", severity: "low", urgency: "routine", safetyRisk: false, confidence: 0.8, affectedPopulation: [], riskFactors: [], recommendedSlaMinutes: 4320, reason: "Minor issue" },
    visionResult: { available: true, detected: true, visualSeverity: 90, description: "Massive pothole", confidence: 0.95, damageType: "pothole", imageQuality: "good", objects: [] },
    duplicateResult: { clusterSize: 1, relatedComplaintIds: [] },
    ruleResult: { category: "Roads", priority: 50, department: "Roads Dept", reason: "keyword" }
  });
  check("Discrepancy detected", discrepancy.inputDiscrepancy === true);
  check("Discrepancy detail present", !!discrepancy.discrepancyDetail);

  // ── Test 6: SLA Engine ──
  console.log("\n[6] SLA ENGINE");
  const critSla = calculateSLA("critical", true);
  const lowSla = calculateSLA("low", false);
  check(`Critical SLA = ${critSla.recommendedSlaMinutes}min (expected 120)`, critSla.recommendedSlaMinutes === 120);
  check(`Low SLA = ${lowSla.recommendedSlaMinutes}min (expected 4320)`, lowSla.recommendedSlaMinutes === 4320);
  check("SLA deadline is ISO string", typeof critSla.slaDeadline === "string");

  // SLA breach check
  const breachedComplaint = {
    status: "assigned",
    aiAnalysis: { slaDeadline: new Date(Date.now() - 3600000).toISOString() }
  };
  const breachResult = checkSLABreach(breachedComplaint);
  check("SLA breach detected for overdue complaint", breachResult.breached === true);

  const resolvedComplaint = { status: "verified" };
  const noBreachResult = checkSLABreach(resolvedComplaint);
  check("No SLA breach for verified complaint", noBreachResult.breached === false);

  // ── Test 7: Decision Log ──
  console.log("\n[7] EXPLAINABLE AI DECISION LOG");
  const decLog = generateDecisionLog("CP-TEST-001", fusedResult);
  check("Decision log has timestamp", !!decLog.timestamp);
  check("Decision log has complaintId", decLog.complaintId === "CP-TEST-001");
  check("Decision log has evidence array", Array.isArray(decLog.evidence));
  check("Decision log has priority breakdown", Array.isArray(decLog.priorityBreakdown));
  check("Decision log has reason", typeof decLog.reason === "string");

  // ── Test 8: Geo Service ──
  console.log("\n[8] GEO-SPATIAL INTELLIGENCE");
  const dist = haversineDistance(12.9716, 77.5946, 12.9750, 77.5980);
  check(`Haversine distance = ${dist.toFixed(2)}km (expected 0.3-0.6)`, dist > 0.2 && dist < 1.0);

  const mockComplaints = [
    { id: "G1", title: "Test1", location: { lat: 12.9718, lng: 77.5948 }, status: "assigned", category: "Roads", priority: 80 },
    { id: "G2", title: "Test2", location: { lat: 12.9720, lng: 77.5950 }, status: "assigned", category: "Roads", priority: 60 },
    { id: "G3", title: "Test3", location: { lat: 13.0200, lng: 77.6500 }, status: "assigned", category: "Water", priority: 40 }
  ];
  const nearby = getNearbyComplaints(mockComplaints, 12.9716, 77.5946, 1);
  check(`Nearby within 1km = ${nearby.length} (expected 2)`, nearby.length === 2);

  const hotspots = getHotspots(mockComplaints, 0.5);
  check(`Hotspots found = ${hotspots.length} (expected >= 1)`, hotspots.length >= 1);

  // ── Test 9: AI Pipeline (async, with fallback) ──
  console.log("\n[9] FULL AI PIPELINE (FALLBACK MODE)");
  const aiPipeResult = await analyzeComplaintAI(
    "Broken water pipe flooding residential area",
    "Major pipe burst on 3rd street, water everywhere, children at risk",
    { photoUrl: "", complaintId: "CP-TEST-AI-001" }
  );
  check("AI pipeline returns category", !!aiPipeResult.category);
  check("AI pipeline returns priority", typeof aiPipeResult.priority === "number");
  check("AI pipeline returns department", !!aiPipeResult.department);
  check("AI pipeline returns aiAnalysis", !!aiPipeResult.aiAnalysis);
  check("AI pipeline aiAnalysis has severity", !!aiPipeResult.aiAnalysis.severity);

  // ── Test 10: Analytics ──
  console.log("\n[10] ANALYTICS SERVICE");
  const analytics = await getAnalytics();
  check("Analytics has summary", !!analytics.summary);
  check("Analytics has summary.total", typeof analytics.summary.total === "number");
  check("Analytics has byCategory", !!analytics.byCategory);
  check("Analytics has departmentPerformance", Array.isArray(analytics.departmentPerformance));
  check("Analytics has generatedAt", !!analytics.generatedAt);

  // ── Test 11: DB Decision Log Storage ──
  console.log("\n[11] DECISION LOG STORAGE");
  await db.saveDecisionLog({ complaintId: "CP-TEST-LOG", action: "TEST", reason: "Test entry", timestamp: new Date().toISOString() });
  const logs = await db.getDecisionLogs("CP-TEST-LOG");
  check("Decision log saved and retrieved", logs.length === 1);
  check("Decision log content correct", logs[0].action === "TEST");

  // ═══════════════════════════════════════
  console.log("\n==================================================");
  console.log(`🧠 AI Tests: ${passed} passed, ${failed} failed`);
  if (failed === 0) {
    console.log("🎉 ALL AI TESTS PASSED!");
  } else {
    console.error(`💥 ${failed} AI TEST(S) FAILED`);
  }
  console.log("==================================================");
  process.exit(failed > 0 ? 1 : 0);
}

runAITests();
