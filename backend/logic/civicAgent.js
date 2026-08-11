/**
 * CivicAgent — AI Core Engine for CivicPulse
 * Responsible for auto-categorization, priority scoring, and department assignment.
 */

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
 * Analyzes raw complaint title & description to determine category, priority (0-100), and assigned department.
 * @param {string} title - Complaint title
 * @param {string} description - Complaint description
 * @returns {{ category: string, priority: number, department: string }}
 */
function analyzeComplaint(title = "", description = "") {
  const fullText = `${title} ${description}`.toLowerCase();
  
  // 1. Categorize via keyword matching
  let matchedCategory = "Public Infrastructure"; // default fallback
  let maxKeywordScore = 0;

  for (const [catName, config] of Object.entries(CATEGORY_MAP)) {
    let matches = 0;
    for (const kw of config.keywords) {
      if (fullText.includes(kw)) {
        matches++;
      }
    }
    if (matches > maxKeywordScore) {
      maxKeywordScore = matches;
      matchedCategory = catName;
    }
  }

  const categoryConfig = CATEGORY_MAP[matchedCategory] || CATEGORY_MAP["Public Infrastructure"];
  
  // 2. Score priority (Base score + risk boosts)
  let priority = categoryConfig.basePriority;

  // Add priority boost for safety risk keywords
  for (const riskKw of RISK_KEYWORDS) {
    if (fullText.includes(riskKw)) {
      priority += 15;
    }
  }

  // Cap priority between 0 and 100
  priority = Math.min(100, Math.max(0, priority));

  // 3. Assign department
  const department = categoryConfig.department;

  return {
    category: matchedCategory,
    priority: priority,
    department: department
  };
}

module.exports = {
  analyzeComplaint,
  CATEGORY_MAP
};
