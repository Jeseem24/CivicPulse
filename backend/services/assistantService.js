/**
 * Ask CivicAgent — AI Assistant with tool-calling over real database data
 * No hallucinated data. All answers grounded in Firestore queries.
 */

const { getTextModel, isAIAvailable } = require("./ai/geminiClient");
const db = require("../config/db");
const { getAnalytics } = require("./analyticsService");
const { checkSLABreach } = require("./ai/slaEngine");
const { getNearbyComplaints, getHotspots } = require("./geoService");

// Tool definitions that the assistant can invoke
const TOOLS = {
  async getComplaint(args) {
    const complaint = await db.getComplaintById(args.id);
    return complaint || { error: `Complaint ${args.id} not found` };
  },
  async getComplaints(args) {
    const filter = {};
    if (args.department) filter.department = args.department;
    if (args.status) filter.status = args.status;
    const complaints = await db.getComplaints(filter);
    return complaints.map(c => ({
      id: c.id, title: c.title, category: c.category, priority: c.priority,
      status: c.status, department: c.department, createdAt: c.createdAt
    }));
  },
  async getDepartments() {
    return await db.getDepartments();
  },
  async getAnalyticsSummary() {
    return await getAnalytics();
  },
  async getCriticalComplaints() {
    const all = await db.getComplaints({});
    return all.filter(c => c.priority >= 70 && !["verified", "closed"].includes(c.status))
      .sort((a, b) => b.priority - a.priority)
      .slice(0, 15)
      .map(c => ({ id: c.id, title: c.title, priority: c.priority, category: c.category, department: c.department, status: c.status }));
  },
  async getOverdueComplaints() {
    const all = await db.getComplaints({});
    return all.filter(c => {
      const breach = checkSLABreach(c);
      return breach.breached;
    }).map(c => ({
      id: c.id, title: c.title, priority: c.priority, status: c.status,
      department: c.department, sla: checkSLABreach(c)
    }));
  },
  async getNearby(args) {
    const all = await db.getComplaints({});
    const nearby = getNearbyComplaints(all, args.lat, args.lng, args.radiusKm || 2);
    return nearby.slice(0, 20).map(c => ({
      id: c.id, title: c.title, category: c.category, status: c.status, distanceKm: c.distanceKm
    }));
  },
  async getHotspotData() {
    const all = await db.getComplaints({});
    return getHotspots(all).slice(0, 10);
  }
};

const ASSISTANT_SYSTEM = `You are CivicAgent, an intelligent AI assistant for the CivicPulse civic complaint management system.

You have access to REAL database tools to answer questions. NEVER make up data — always query the tools first.

Available tools (call by returning a JSON with "toolCalls"):
- getAnalyticsSummary: Get full system analytics (totals, distributions, department performance)
- getDepartments: List all departments with trust scores
- getCriticalComplaints: Get high-priority unresolved complaints
- getOverdueComplaints: Get complaints that breached their SLA
- getComplaints(department?, status?): Query complaints with optional filters
- getComplaint(id): Get a specific complaint by ID
- getNearby(lat, lng, radiusKm?): Find complaints near a location
- getHotspotData: Get complaint hotspot clusters

RULES:
1. First, determine which tool(s) you need to answer the question.
2. Return a JSON response with "toolCalls" array listing the tools to call.
3. After receiving tool results, generate a clear, helpful answer.
4. Always cite specific data from tool results.
5. Be concise but informative.
6. If the question cannot be answered with available tools, say so honestly.

For the FIRST response, return JSON:
{
  "toolCalls": [
    { "tool": "toolName", "args": {} }
  ]
}

For the FINAL response after receiving data, return JSON:
{
  "answer": "Your detailed answer based on real data",
  "highlights": ["key finding 1", "key finding 2"]
}`;

/**
 * Process a user question through the AI assistant
 * @param {string} message - User's question
 * @returns {object} { answer, sources, toolCalls }
 */
async function askCivicAgent(message) {
  if (!isAIAvailable()) {
    // Fallback: directly run analytics and format a basic answer
    return await fallbackAnswer(message);
  }

  const model = getTextModel();
  if (!model) return await fallbackAnswer(message);

  try {
    // Step 1: Ask LLM which tools to call
    const planResult = await Promise.race([
      model.generateContent({
        contents: [
          { role: "user", parts: [{ text: `${ASSISTANT_SYSTEM}\n\nUser question: ${message}` }] }
        ],
        generationConfig: { responseMimeType: "application/json", temperature: 0.1, maxOutputTokens: 512 }
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Assistant planning timeout")), 10000))
    ]);

    const planText = planResult.response.text();
    const plan = JSON.parse(planText);

    // If the LLM directly returned an answer (no tools needed)
    if (plan.answer && !plan.toolCalls) {
      return { answer: plan.answer, sources: [], toolCalls: [] };
    }

    // Step 2: Execute tool calls
    const toolResults = {};
    const toolCallsExecuted = [];

    if (plan.toolCalls && Array.isArray(plan.toolCalls)) {
      for (const call of plan.toolCalls.slice(0, 4)) { // max 4 tool calls
        const toolFn = TOOLS[call.tool];
        if (toolFn) {
          try {
            toolResults[call.tool] = await toolFn(call.args || {});
            toolCallsExecuted.push(call.tool);
          } catch (err) {
            toolResults[call.tool] = { error: err.message };
          }
        }
      }
    }

    // Step 3: Send tool results back to LLM for final answer
    const answerResult = await Promise.race([
      model.generateContent({
        contents: [
          { role: "user", parts: [{ text: `${ASSISTANT_SYSTEM}\n\nUser question: ${message}` }] },
          { role: "model", parts: [{ text: JSON.stringify(plan) }] },
          { role: "user", parts: [{ text: `Tool results:\n${JSON.stringify(toolResults, null, 2)}\n\nNow provide your final answer as JSON with "answer" and "highlights" fields.` }] }
        ],
        generationConfig: { responseMimeType: "application/json", temperature: 0.3, maxOutputTokens: 2048 }
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("Assistant answer timeout")), 15000))
    ]);

    const answerText = answerResult.response.text();
    const answer = JSON.parse(answerText);

    return {
      answer: answer.answer || "I couldn't generate a complete answer.",
      highlights: answer.highlights || [],
      sources: toolCallsExecuted,
      toolCalls: toolCallsExecuted
    };
  } catch (err) {
    console.error("[ASSISTANT] Error:", err.message);
    return await fallbackAnswer(message);
  }
}

/**
 * Fallback answer using direct database queries (no LLM)
 */
async function fallbackAnswer(message) {
  try {
    const analytics = await getAnalytics();
    const msg = message.toLowerCase();

    if (msg.includes("worst") || msg.includes("lowest trust") || msg.includes("performing")) {
      const worst = analytics.departmentPerformance.sort((a, b) => a.trustScore - b.trustScore)[0];
      return {
        answer: `${worst.name} has the lowest trust score at ${worst.trustScore}/100 with ${worst.reopenCount} reopened complaints out of ${worst.totalComplaints} total.`,
        highlights: [`Lowest trust: ${worst.name} (${worst.trustScore})`],
        sources: ["getDepartments"],
        toolCalls: ["getDepartments"]
      };
    }

    if (msg.includes("urgent") || msg.includes("critical") || msg.includes("priority")) {
      return {
        answer: `There are ${analytics.summary.critical} critical complaints. ${analytics.summary.open} complaints are currently open, with ${analytics.summary.slaBreaches} SLA breaches.`,
        highlights: [`${analytics.summary.critical} critical`, `${analytics.summary.slaBreaches} SLA breaches`],
        sources: ["getAnalyticsSummary"],
        toolCalls: ["getAnalyticsSummary"]
      };
    }

    // Default summary
    return {
      answer: `CivicPulse currently has ${analytics.summary.total} complaints: ${analytics.summary.open} open, ${analytics.summary.resolved} resolved, ${analytics.summary.reopened} reopened. ${analytics.summary.critical} are critical and ${analytics.summary.slaBreaches} have breached their SLA.`,
      highlights: [`${analytics.summary.total} total complaints`, `${analytics.summary.open} open`],
      sources: ["getAnalyticsSummary"],
      toolCalls: ["getAnalyticsSummary"]
    };
  } catch (err) {
    return { answer: "I'm unable to retrieve data at this time.", highlights: [], sources: [], toolCalls: [] };
  }
}

module.exports = { askCivicAgent };
