/**
 * CivicPulse — AI-Powered Express Server Entry Point (Developer 2)
 */

const express = require("express");
const cors = require("cors");
require("dotenv").config();

const complaintsRouter = require("./routes/complaints");
const departmentsRouter = require("./routes/departments");
const assistantRouter = require("./routes/assistant");
const analyticsRouter = require("./routes/analytics");

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS & JSON parsing
app.use(cors());
app.use(express.json({ limit: "10mb" }));

// Health check endpoint
app.get("/", (req, res) => {
  const { isAIAvailable } = require("./services/ai/geminiClient");
  res.status(200).json({
    app: "CivicPulse AI-Powered API Server",
    status: "online",
    aiEnabled: isAIAvailable(),
    endpoints: [
      "POST /complaints",
      "GET /complaints",
      "GET /complaints/:id",
      "GET /complaints/:id/decision-log",
      "GET /complaints/overdue",
      "GET /complaints/escalated",
      "PATCH /complaints/:id/resolve",
      "PATCH /complaints/:id/verify",
      "GET /departments",
      "POST /assistant/ask",
      "GET /analytics",
      "GET /analytics/hotspots",
      "GET /analytics/nearby?lat=&lng=&radius=",
      "POST /seed-demo"
    ]
  });
});

// Mount router modules
app.use("/complaints", complaintsRouter);
app.use("/departments", departmentsRouter);
app.use("/assistant", assistantRouter);
app.use("/analytics", analyticsRouter);

// Demo seed endpoint
app.post("/seed-demo", async (req, res) => {
  try {
    const demoComplaints = require("./data/demoComplaints");
    const db = require("./config/db");
    const { analyzeComplaintAI } = require("./logic/civicAgent");

    const results = [];
    for (const demo of demoComplaints) {
      // Check if already exists
      const existing = await db.getComplaintById(demo.id);
      if (existing) {
        results.push({ id: demo.id, status: "already_exists" });
        continue;
      }

      // Run AI analysis on each demo complaint
      const aiResult = await analyzeComplaintAI(demo.title, demo.description, {
        photoUrl: demo.photoUrl || "",
        complaintId: demo.id
      });

      const complaint = {
        ...demo,
        category: aiResult.category,
        priority: aiResult.priority,
        department: aiResult.department,
        aiAnalysis: aiResult.aiAnalysis || null
      };

      await db.saveComplaint(complaint);
      results.push({ id: demo.id, category: complaint.category, priority: complaint.priority, department: complaint.department });
    }

    return res.status(200).json({ seeded: results.length, complaints: results });
  } catch (error) {
    console.error("Error seeding demo data:", error);
    return res.status(500).json({ error: "Failed to seed demo data" });
  }
});

// Start listening
if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, () => {
    const { isAIAvailable } = require("./services/ai/geminiClient");
    console.log(`=================================================`);
    console.log(`🚀 CivicPulse AI Server running on http://localhost:${PORT}`);
    console.log(`🤖 AI Engine: ${isAIAvailable() ? "ACTIVE (Gemini)" : "DISABLED (rule-based fallback)"}`);
    console.log(`=================================================`);
  });
}

module.exports = app;
