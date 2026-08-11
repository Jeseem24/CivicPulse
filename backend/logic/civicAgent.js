/**
 * CivicAgent — AI-Powered Civic Intelligence Engine for CivicPulse
 *
 * UPGRADE: Wraps the original rule-based analysis with a multimodal AI pipeline.
 * If AI fails at any stage, the original rule-based logic is the automatic fallback.
 *
 * Pipeline:  Text AI → Vision AI → Duplicate Detection → AI Fusion → SLA → Decision Log
 */

const { analyzeLLM } = require("../services/ai/llmAnalyzer");
const { analyzeImage } = require("../services/ai/visionAnalyzer");
const { findDuplicates } = require("../services/ai/duplicateDetector");
const { fuseAnalysis } = require("../services/ai/fusionEngine");
const { calculateSLA } = require("../services/ai/slaEngine");
const { generateDecisionLog } = require("../services/ai/explanationEngine");
const db = require("../config/db");

// ═══════════════════════════════════════════════════════════
// ORIGINAL RULE-BASED LOGIC (PRESERVED AS FALLBACK)
// ═══════════════════════════════════════════════════════════

const CATEGORY_MAP = {
  "Roads": {
    keywords: ["pothole", "potholes", "road", "street", "asphalt", "crack", "tar", "traffic light", "footpath", "sidewalk", "divider"],
    basePriority: 50,
    department: "Roads Dept"
  },
  "Sanitation": {
    keywords: ["garbage", "trash", "waste", "dump", "bin", "smell", "stink", "litter", "cleaning", "sewage", "overflow"],
    basePriority: 40,
    department: "Sanitation Dept"
  },
  "Water": {
    keywords: ["water", "leak", "leakage", "pipe", "drain", "drainage", "burst", "flood", "flooding", "supply", "tap", "drinking water"],
    basePriority: 60,
    department: "Water Dept"
  },
  "Electricity": {
    keywords: ["electricity", "power", "wire", "cable", "streetlight", "light", "outage", "transformer", "spark", "current", "pole"],
    basePriority: 55,
    department: "Electricity Dept"
  },
  "Public Infrastructure": {
    keywords: ["park", "bench", "bridge", "building", "playground", "fence", "gate", "wall", "public", "bus stop", "shelter"],
    basePriority: 35,
    department: "Public Infrastructure Dept"
  }
};

const RISK_KEYWORDS = [
  "school", "hospital", "accident", "danger", "dangerous", "children",
  "kid", "kids", "emergency", "hazard", "hazardious", "fire", "injury",
  "hurt", "risk", "critical", "severe", "blocking", "blocked"
];

/**
 * Original rule-based analysis (unchanged, always available)
 */
function ruleBasedAnalysis(title = "", description = "") {
  const fullText = `${title} ${description}`.toLowerCase();

  let matchedCategory = "Public Infrastructure";
  let maxKeywordScore = 0;

  for (const [catName, config] of Object.entries(CATEGORY_MAP)) {
    let matches = 0;
    for (const kw of config.keywords) {
      if (fullText.includes(kw)) matches++;
    }
    if (matches > maxKeywordScore) {
      maxKeywordScore = matches;
      matchedCategory = catName;
    }
  }

  const categoryConfig = CATEGORY_MAP[matchedCategory] || CATEGORY_MAP["Public Infrastructure"];
  let priority = categoryConfig.basePriority;

  for (const riskKw of RISK_KEYWORDS) {
    if (fullText.includes(riskKw)) priority += 15;
  }
  priority = Math.min(100, Math.max(0, priority));

  return {
    category: matchedCategory,
    priority: priority,
    department: categoryConfig.department,
    reason: `Rule-based: matched category "${matchedCategory}" with ${maxKeywordScore} keyword hits`
  };
}

// ═══════════════════════════════════════════════════════════
// AI-POWERED ANALYSIS PIPELINE
// ═══════════════════════════════════════════════════════════

/**
 * Full AI-powered complaint analysis
 * Returns the same contract as the original: { category, priority, department }
 * PLUS additional aiAnalysis metadata.
 *
 * @param {string} title
 * @param {string} description
 * @param {object} options - { photoUrl, location, complaintId }
 * @returns {{ category, priority, department, aiAnalysis }}
 */
async function analyzeComplaintAI(title, description, options = {}) {
  // Always compute rule-based as fallback
  const ruleResult = ruleBasedAnalysis(title, description);

  try {
    // ── Step 1: LLM Semantic Analysis ──
    const llmResult = await analyzeLLM(title, description);

    // ── Step 2: Vision Analysis (if photo exists) ──
    let visionResult = null;
    if (options.photoUrl && options.photoUrl !== "") {
      visionResult = await analyzeImage(options.photoUrl);
    }

    // ── Step 3: Duplicate Detection ──
    let duplicateResult = { duplicateOf: null, relatedComplaintIds: [], highestSimilarity: 0, clusterSize: 1 };
    if (options.complaintId) {
      try {
        const existingComplaints = await db.getComplaints({});
        duplicateResult = await findDuplicates(
          options.complaintId,
          `${title} ${description}`,
          existingComplaints
        );
      } catch (err) {
        console.error("[AGENT] Duplicate detection failed:", err.message);
      }
    }

    // ── Step 4: AI Fusion ──
    const fusedResult = fuseAnalysis({
      llmResult,
      visionResult,
      duplicateResult,
      ruleResult
    });

    // ── Step 5: SLA Calculation ──
    const sla = calculateSLA(fusedResult.severity, fusedResult.safetyRisk);

    // ── Step 6: Decision Log ──
    const decisionLog = generateDecisionLog(options.complaintId || "unknown", fusedResult);

    // Save decision log if we have a complaint ID
    if (options.complaintId) {
      try {
        await db.saveDecisionLog(decisionLog);
      } catch (err) {
        // Decision log storage is best-effort
      }
    }

    // Return in the SAME CONTRACT as original + additive aiAnalysis
    return {
      category: fusedResult.category,
      priority: fusedResult.priority,
      department: fusedResult.department,
      aiAnalysis: {
        severity: fusedResult.severity,
        urgency: fusedResult.urgency,
        safetyRisk: fusedResult.safetyRisk,
        affectedPopulation: fusedResult.affectedPopulation,
        riskFactors: fusedResult.riskFactors,
        confidence: fusedResult.confidence,
        recommendedAction: fusedResult.recommendedAction,
        reason: fusedResult.reason,
        recommendedSlaMinutes: sla.recommendedSlaMinutes,
        slaDeadline: sla.slaDeadline,
        slaLevel: sla.slaLevel,
        priorityBreakdown: fusedResult.priorityBreakdown,
        visionAnalysis: fusedResult.visionAnalysis,
        duplicateInfo: fusedResult.duplicateInfo,
        inputDiscrepancy: fusedResult.inputDiscrepancy,
        discrepancyDetail: fusedResult.discrepancyDetail,
        aiPowered: fusedResult.aiPowered,
        textConfidence: fusedResult.textConfidence,
        visionConfidence: fusedResult.visionConfidence,
        decisionLog
      }
    };
  } catch (err) {
    console.error("[AGENT] AI pipeline error, falling back to rules:", err.message);
    return {
      category: ruleResult.category,
      priority: ruleResult.priority,
      department: ruleResult.department,
      aiAnalysis: {
        aiPowered: false,
        severity: "medium",
        urgency: "routine",
        safetyRisk: false,
        confidence: 0.3,
        reason: `Fallback: ${ruleResult.reason}`,
        recommendedSlaMinutes: 1440,
        slaDeadline: new Date(Date.now() + 1440 * 60000).toISOString(),
        slaLevel: "medium"
      }
    };
  }
}

/**
 * Synchronous analyzeComplaint — backward compatible with existing tests
 * Returns ONLY { category, priority, department }
 */
function analyzeComplaint(title = "", description = "") {
  return ruleBasedAnalysis(title, description);
}

module.exports = {
  analyzeComplaint,       // Sync, backward-compatible (existing tests use this)
  analyzeComplaintAI,     // Async, full AI pipeline (routes use this)
  ruleBasedAnalysis,      // Exposed for direct testing
  CATEGORY_MAP
};
