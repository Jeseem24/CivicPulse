/**
 * Analytics API Router
 */

const express = require("express");
const router = express.Router();
const { getAnalytics } = require("../services/analyticsService");
const db = require("../config/db");
const { getNearbyComplaints, getHotspots } = require("../services/geoService");

/**
 * GET /analytics
 * Full analytics dashboard data
 */
router.get("/", async (req, res) => {
  try {
    const analytics = await getAnalytics();
    return res.status(200).json(analytics);
  } catch (error) {
    console.error("Error generating analytics:", error);
    return res.status(500).json({ error: "Failed to generate analytics" });
  }
});

/**
 * GET /analytics/hotspots
 * Complaint hotspot data for map visualization
 */
router.get("/hotspots", async (req, res) => {
  try {
    const complaints = await db.getComplaints({});
    const hotspots = getHotspots(complaints);
    return res.status(200).json(hotspots);
  } catch (error) {
    console.error("Error generating hotspots:", error);
    return res.status(500).json({ error: "Failed to generate hotspots" });
  }
});

/**
 * GET /analytics/nearby?lat=&lng=&radius=
 * Nearby complaints for a location
 */
router.get("/nearby", async (req, res) => {
  try {
    const { lat, lng, radius } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ error: "lat and lng are required" });
    }
    const complaints = await db.getComplaints({});
    const nearby = getNearbyComplaints(
      complaints,
      parseFloat(lat),
      parseFloat(lng),
      parseFloat(radius) || 2
    );
    return res.status(200).json(nearby);
  } catch (error) {
    console.error("Error finding nearby complaints:", error);
    return res.status(500).json({ error: "Failed to find nearby complaints" });
  }
});

module.exports = router;
