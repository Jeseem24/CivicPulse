/**
 * Ask CivicAgent — AI Assistant API Router
 */

const express = require("express");
const router = express.Router();
const { askCivicAgent } = require("../services/assistantService");

/**
 * POST /assistant/ask
 * Natural language query to CivicAgent
 */
router.post("/ask", async (req, res) => {
  try {
    const { message } = req.body;
    if (!message || typeof message !== "string" || message.trim().length === 0) {
      return res.status(400).json({ error: "message is required" });
    }

    const result = await askCivicAgent(message.trim());
    return res.status(200).json(result);
  } catch (error) {
    console.error("Error in assistant:", error);
    return res.status(500).json({ error: "Assistant failed to process your question" });
  }
});

module.exports = router;
