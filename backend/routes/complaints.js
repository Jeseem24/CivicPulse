/**
 * Complaints API Router
 * Implements endpoints specified in DEVELOPER_2_AI_BACKEND.md Section 6.
 */

const express = require("express");
const router = express.Router();
const db = require("../config/db");
const { analyzeComplaint } = require("../logic/civicAgent");

/**
 * Generate human-readable Complaint ID (e.g., CP-2026-00214)
 */
function generateComplaintId() {
  const randomNum = Math.floor(10000 + Math.random() * 90000);
  return `CP-2026-${randomNum}`;
}

/**
 * POST /complaints
 * Submit a new complaint
 */
router.post("/", async (req, res) => {
  try {
    const { title, description, location, photoUrl } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: "title and description are required fields" });
    }

    // 1. Run CivicAgent analysis for categorization, priority scoring & department routing
    const aiResult = analyzeComplaint(title, description);

    // 2. Construct complaint document per MASTER.md data model
    const newComplaint = {
      id: generateComplaintId(),
      title: title.trim(),
      description: description.trim(),
      category: aiResult.category,
      priority: aiResult.priority,
      department: aiResult.department,
      status: "assigned",
      location: location || { lat: 0.0, lng: 0.0, address: "Unspecified location" },
      photoUrl: photoUrl || "",
      createdAt: new Date().toISOString(),
      resolution: null,
      reopenCount: 0
    };

    // 3. Save to database & update department total counter
    await db.saveComplaint(newComplaint);

    return res.status(201).json(newComplaint);
  } catch (error) {
    console.error("Error creating complaint:", error);
    return res.status(500).json({ error: "Failed to create complaint" });
  }
});

/**
 * GET /complaints
 * List all complaints with optional filtering by ?department= or ?status=
 */
router.get("/", async (req, res) => {
  try {
    const { department, status } = req.query;
    const complaints = await db.getComplaints({ department, status });
    return res.status(200).json(complaints);
  } catch (error) {
    console.error("Error listing complaints:", error);
    return res.status(500).json({ error: "Failed to list complaints" });
  }
});

/**
 * GET /complaints/:id
 * Retrieve single complaint by ID
 */
router.get("/:id", async (req, res) => {
  try {
    const complaint = await db.getComplaintById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ error: `Complaint with ID ${req.params.id} not found` });
    }
    return res.status(200).json(complaint);
  } catch (error) {
    console.error("Error getting complaint:", error);
    return res.status(500).json({ error: "Failed to get complaint" });
  }
});

/**
 * PATCH /complaints/:id/resolve
 * Official marks complaint resolved
 */
router.patch("/:id/resolve", async (req, res) => {
  try {
    const { id } = req.params;
    const { description } = req.body;

    const existing = await db.getComplaintById(id);
    if (!existing) {
      return res.status(404).json({ error: `Complaint with ID ${id} not found` });
    }

    const resolution = {
      description: description || "Resolved by official",
      resolvedAt: new Date().toISOString()
    };

    // Update complaint status to awaiting_verification
    const updatedComplaint = await db.updateComplaint(id, {
      status: "awaiting_verification",
      resolution: resolution
    });

    // Increment resolvedCount on assigned department
    if (existing.department) {
      await db.updateDepartmentMetrics(existing.department, { isResolved: true });
    }

    return res.status(200).json(updatedComplaint);
  } catch (error) {
    console.error("Error resolving complaint:", error);
    return res.status(500).json({ error: "Failed to resolve complaint" });
  }
});

/**
 * PATCH /complaints/:id/verify
 * Citizen verifies resolution: "fixed" -> closed/verified, "still_exists" -> reopened
 */
router.patch("/:id/verify", async (req, res) => {
  try {
    const { id } = req.params;
    const { result } = req.body;

    if (!result || !["fixed", "still_exists"].includes(result)) {
      return res.status(400).json({ error: "result must be either 'fixed' or 'still_exists'" });
    }

    const existing = await db.getComplaintById(id);
    if (!existing) {
      return res.status(404).json({ error: `Complaint with ID ${id} not found` });
    }

    let updateFields = {};

    if (result === "fixed") {
      updateFields = { status: "verified" };
    } else if (result === "still_exists") {
      const newReopenCount = (existing.reopenCount || 0) + 1;
      updateFields = {
        status: "reopened",
        reopenCount: newReopenCount
      };

      // Penalize department trust score
      if (existing.department) {
        await db.updateDepartmentMetrics(existing.department, { isReopened: true });
      }
    }

    const updatedComplaint = await db.updateComplaint(id, updateFields);
    return res.status(200).json(updatedComplaint);
  } catch (error) {
    console.error("Error verifying complaint:", error);
    return res.status(500).json({ error: "Failed to verify complaint" });
  }
});

module.exports = router;
