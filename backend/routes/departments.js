/**
 * Departments API Router
 */

const express = require("express");
const router = express.Router();
const db = require("../config/db");

/**
 * GET /departments
 * Returns array of departments with trustScore
 */
router.get("/", async (req, res) => {
  try {
    const departments = await db.getDepartments();
    return res.status(200).json(departments);
  } catch (error) {
    console.error("Error fetching departments:", error);
    return res.status(500).json({ error: "Failed to fetch departments" });
  }
});

module.exports = router;
