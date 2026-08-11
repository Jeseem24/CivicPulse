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

// Authentication Endpoints for Mobile App Compatibility
const MOCK_USERS = [
  { id: 'admin_roads', name: 'Rajesh Kumar (Roads Admin)', email: 'roads_admin@gov.in', password: 'admin123', role: 'ADMIN', departmentId: 'ROADS_HIGHWAYS' },
  { id: 'admin_water', name: 'Anil Sharma (Water Admin)', email: 'water_admin@gov.in', password: 'admin123', role: 'ADMIN', departmentId: 'WATER_SUPPLY' },
  { id: 'admin_sanitation', name: 'Suresh Patel (Sanitation Admin)', email: 'sanitation_admin@gov.in', password: 'admin123', role: 'ADMIN', departmentId: 'SANITATION_WASTE' },
  { id: 'user_citizen', name: 'Janardhan Rao', email: 'citizen@example.com', password: 'citizen123', role: 'USER', departmentId: null }
];

const handleAuthLogin = (req, res) => {
  const { email, password } = req.body;
  const user = MOCK_USERS.find(u => u.email.toLowerCase() === (email || '').trim().toLowerCase());
  if (!user || user.password !== password) {
    return res.status(401).json({ error: "Invalid email or password" });
  }
  const { password: _, ...userNoPass } = user;
  return res.status(200).json({ token: `jwt_${user.id}_token`, user: userNoPass });
};

app.post('/auth/login', handleAuthLogin);
app.post('/api/v1/auth/login', handleAuthLogin);
app.get('/api/v1/auth/me', (req, res) => res.status(200).json({ user: MOCK_USERS[3] }));

// Live AI Decision Feed endpoint
app.get("/decision-log/feed", async (req, res) => {
  try {
    const db = require("./config/db");
    const limit = parseInt(req.query.limit) || 30;
    const logs = await db.getAllDecisionLogs(limit);
    return res.status(200).json(logs);
  } catch (error) {
    console.error("Error fetching decision log feed:", error);
    return res.status(500).json({ error: "Failed to fetch decision log feed" });
  }
});

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
  app.listen(PORT, "0.0.0.0", () => {
    const { isAIAvailable } = require("./services/ai/geminiClient");
    console.log(`=================================================`);
    console.log(`🚀 CivicPulse AI Server running on http://0.0.0.0:${PORT}`);
    console.log(`🤖 AI Engine: ${isAIAvailable() ? "ACTIVE (Gemini)" : "DISABLED (rule-based fallback)"}`);
    console.log(`=================================================`);
  });
}

module.exports = app;
