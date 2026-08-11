/**
 * Complaints API Router — AI-Powered
 * Implements endpoints specified in DEVELOPER_2_AI_BACKEND.md Section 6.
 * PLUS: AI analysis, decision logs, SLA, overdue/escalated, resolution quality.
 *
 * ALL ORIGINAL ENDPOINTS PRESERVED WITH SAME CONTRACT.
 */

const express = require("express");
const router = express.Router();
const db = require("../config/db");
const { analyzeComplaint, analyzeComplaintAI } = require("../logic/civicAgent");
const { checkSLABreach } = require("../services/ai/slaEngine");
const { analyzeResolution } = require("../services/ai/resolutionAnalyzer");
const { compareBeforeAfter } = require("../services/ai/visionAnalyzer");
const { generateResolutionLog } = require("../services/ai/explanationEngine");
const {
  saveImageData,
  toAnalysisImageInput,
  toPublicComplaint
} = require("../services/imageStorage");

/**
 * Generate human-readable Complaint ID (e.g., CP-2026-00214)
 */
function generateComplaintId() {
  const randomNum = Math.floor(10000 + Math.random() * 90000);
  return `CP-2026-${randomNum}`;
}

/**
 * POST /complaints
 * Submit a new complaint — NOW with full AI pipeline
 * Response contract: SAME required fields + additive aiAnalysis
 */
router.post("/", async (req, res) => {
  try {
    const {
      title,
      description,
      location,
      photoUrl,
      photoData,
      photoPath,
      photo,
      userId
    } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: "title and description are required fields" });
    }

    const complaintId = generateComplaintId();
    const imageInput = photoData || photoPath || photoUrl || photo || "";

    // Run full AI pipeline (falls back to rules automatically)
    const aiResult = await analyzeComplaintAI(title, description, {
      photoUrl: imageInput,
      location: location || null,
      complaintId
    });

    const storedPhotoUrl = photoData
      ? await saveImageData(photoData, complaintId, "reported")
      : (photoUrl || "");

    // Construct complaint document per MASTER.md data model
    // ALL REQUIRED FIELDS PRESERVED
    const newComplaint = {
      id: complaintId,
      userId: userId || "user_anonymous",
      title: title.trim(),
      description: description.trim(),
      category: aiResult.category,
      priority: aiResult.priority,
      department: aiResult.department,
      status: "assigned",
      location: location || { lat: 0.0, lng: 0.0, address: "Unspecified location" },
      photoUrl: storedPhotoUrl,
      createdAt: new Date().toISOString(),
      resolution: null,
      reopenCount: 0,
      // ADDITIVE AI metadata
      aiAnalysis: aiResult.aiAnalysis || null
    };

    // Save to database & update department total counter
    await db.saveComplaint(newComplaint);

    return res.status(201).json(toPublicComplaint(req, newComplaint));
  } catch (error) {
    console.error("Error creating complaint:", error);
    return res.status(error.statusCode || 500).json({
      error: error.statusCode ? error.message : "Failed to create complaint"
    });
  }
});

/**
 * GET /complaints/overdue
 * Returns complaints that have breached their SLA
 * NEW ENDPOINT — does not conflict with existing routes
 */
router.get("/overdue", async (req, res) => {
  try {
    const all = await db.getComplaints({});
    const overdue = all
      .filter(c => {
        const breach = checkSLABreach(c);
        return breach.breached;
      })
      .map(c => toPublicComplaint(req, {
        ...c,
        slaBreach: checkSLABreach(c)
      }))
      .sort((a, b) => (b.slaBreach.overdueMinutes || 0) - (a.slaBreach.overdueMinutes || 0));

    return res.status(200).json(overdue);
  } catch (error) {
    console.error("Error fetching overdue complaints:", error);
    return res.status(500).json({ error: "Failed to fetch overdue complaints" });
  }
});

/**
 * GET /complaints/escalated
 * Returns critical complaints that have breached SLA
 * NEW ENDPOINT
 */
router.get("/escalated", async (req, res) => {
  try {
    const all = await db.getComplaints({});
    const escalated = all
      .filter(c => {
        if (c.priority < 70) return false;
        const breach = checkSLABreach(c);
        return breach.breached;
      })
      .map(c => toPublicComplaint(req, {
        ...c,
        slaBreach: checkSLABreach(c)
      }))
      .sort((a, b) => b.priority - a.priority);

    return res.status(200).json(escalated);
  } catch (error) {
    console.error("Error fetching escalated complaints:", error);
    return res.status(500).json({ error: "Failed to fetch escalated complaints" });
  }
});

/**
 * GET /complaints
 * List all complaints with optional filtering by ?department= or ?status=
 * ORIGINAL CONTRACT — PRESERVED
 */
router.get("/", async (req, res) => {
  try {
    const { department, status } = req.query;
    const complaints = await db.getComplaints({ department, status });
    return res.status(200).json(
      complaints.map(complaint => toPublicComplaint(req, complaint))
    );
  } catch (error) {
    console.error("Error listing complaints:", error);
    return res.status(500).json({ error: "Failed to list complaints" });
  }
});

/**
 * GET /complaints/:id/decision-log
 * Returns AI decision log for a complaint
 * NEW ENDPOINT
 */
router.get("/:id/decision-log", async (req, res) => {
  try {
    const logs = await db.getDecisionLogs(req.params.id);
    return res.status(200).json(logs);
  } catch (error) {
    console.error("Error fetching decision logs:", error);
    return res.status(500).json({ error: "Failed to fetch decision logs" });
  }
});

/**
 * GET /complaints/:id
 * Retrieve single complaint by ID
 * ORIGINAL CONTRACT — PRESERVED
 */
router.get("/:id", async (req, res) => {
  try {
    const complaint = await db.getComplaintById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ error: `Complaint with ID ${req.params.id} not found` });
    }
    return res.status(200).json(toPublicComplaint(req, complaint));
  } catch (error) {
    console.error("Error getting complaint:", error);
    return res.status(500).json({ error: "Failed to get complaint" });
  }
});

/**
 * PATCH /complaints/:id/resolve
 * Official marks complaint resolved — NOW with resolution quality analysis
 * ORIGINAL CONTRACT — PRESERVED (additive resolutionAnalysis field)
 */
router.patch("/:id/resolve", async (req, res) => {
  try {
    const { id } = req.params;
    const { description, afterPhotoData, afterPhotoUrl } = req.body;

    const existing = await db.getComplaintById(id);
    if (!existing) {
      return res.status(404).json({ error: `Complaint with ID ${id} not found` });
    }

    const resolutionDesc = description || "Resolved by official";
    const resolutionPhotoUrl = afterPhotoData
      ? await saveImageData(afterPhotoData, id, "resolved")
      : (afterPhotoUrl || "");

    // AI: Analyze resolution quality
    let resolutionAnalysis = null;
    try {
      resolutionAnalysis = await analyzeResolution(existing, resolutionDesc);
    } catch (err) {
      // Resolution analysis is best-effort
    }

    const resolution = {
      description: resolutionDesc,
      resolvedAt: new Date().toISOString(),
      qualityAnalysis: resolutionAnalysis,
      photoUrl: resolutionPhotoUrl
    };

    // Update complaint status to awaiting_verification
    const updatedComplaint = await db.updateComplaint(id, {
      status: "awaiting_verification",
      resolution: resolution
    });

    // Save resolution decision log
    if (resolutionAnalysis) {
      try {
        const log = generateResolutionLog(id, resolutionAnalysis, null);
        await db.saveDecisionLog(log);
      } catch (err) {}
    }

    // Increment resolvedCount on assigned department
    if (existing.department) {
      await db.updateDepartmentMetrics(existing.department, { isResolved: true });
    }

    return res.status(200).json(toPublicComplaint(req, updatedComplaint));
  } catch (error) {
    console.error("Error resolving complaint:", error);
    return res.status(error.statusCode || 500).json({
      error: error.statusCode ? error.message : "Failed to resolve complaint"
    });
  }
});

/**
 * PATCH /complaints/:id/verify
 * Citizen verifies resolution: "fixed" -> closed/verified, "still_exists" -> reopened
 * ORIGINAL CONTRACT — PRESERVED
 * NEW: accepts optional afterPhotoUrl for before/after comparison
 */
router.patch("/:id/verify", async (req, res) => {
  try {
    const { id } = req.params;
    const { result, afterPhotoUrl, afterPhotoData } = req.body;

    if (!result || !["fixed", "still_exists"].includes(result)) {
      return res.status(400).json({ error: "result must be either 'fixed' or 'still_exists'" });
    }

    const existing = await db.getComplaintById(id);
    if (!existing) {
      return res.status(404).json({ error: `Complaint with ID ${id} not found` });
    }

    let updateFields = {};
    let verificationAnalysis = null;
    const verificationImage = afterPhotoData
      ? await saveImageData(afterPhotoData, id, "verification")
      : (afterPhotoUrl || "");

    // AI: Before/after image comparison (if after photo provided)
    if (verificationImage && existing.photoUrl) {
      try {
        verificationAnalysis = await compareBeforeAfter(
          toAnalysisImageInput(existing.photoUrl),
          toAnalysisImageInput(verificationImage)
        );
      } catch (err) {
        // Vision comparison is best-effort
      }
    }

    if (result === "fixed") {
      updateFields = {
        status: "verified",
        verificationAnalysis: verificationAnalysis
      };
    } else if (result === "still_exists") {
      const newReopenCount = (existing.reopenCount || 0) + 1;
      updateFields = {
        status: "reopened",
        reopenCount: newReopenCount,
        verificationAnalysis: verificationAnalysis
      };

      // Penalize department trust score
      if (existing.department) {
        await db.updateDepartmentMetrics(existing.department, { isReopened: true });
      }
    }

    const updatedComplaint = await db.updateComplaint(id, updateFields);
    return res.status(200).json(toPublicComplaint(req, updatedComplaint));
  } catch (error) {
    console.error("Error verifying complaint:", error);
    return res.status(error.statusCode || 500).json({
      error: error.statusCode ? error.message : "Failed to verify complaint"
    });
  }
});

module.exports = router;
