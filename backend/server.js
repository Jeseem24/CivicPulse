/**
 * CivicPulse — Express Server Entry Point (Developer 2)
 */

const express = require("express");
const cors = require("cors");
require("dotenv").config();

const complaintsRouter = require("./routes/complaints");
const departmentsRouter = require("./routes/departments");

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS & JSON parsing
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get("/", (req, res) => {
  res.status(200).json({
    app: "CivicPulse API Server",
    status: "online",
    endpoints: [
      "POST /complaints",
      "GET /complaints",
      "GET /complaints/:id",
      "PATCH /complaints/:id/resolve",
      "PATCH /complaints/:id/verify",
      "GET /departments"
    ]
  });
});

// Mount router modules
app.use("/complaints", complaintsRouter);
app.use("/departments", departmentsRouter);

// Start listening
if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, () => {
    console.log(`=================================================`);
    console.log(`🚀 CivicPulse Express API running on http://localhost:${PORT}`);
    console.log(`=================================================`);
  });
}

module.exports = app;
