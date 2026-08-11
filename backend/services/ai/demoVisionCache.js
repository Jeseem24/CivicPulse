/**
 * Demo Vision Cache — Pre-cached vision results for reliable live hackathon demonstrations
 */

const DEMO_CACHE = {
  pothole: {
    available: true,
    provider: "demo",
    detected: true,
    damageType: "pothole",
    visualSeverity: 82,
    description: "Large road surface damage with severe asphalt degradation and hazardous hole.",
    objects: ["pothole", "asphalt", "road_crack", "vehicle_hazard"],
    imageQuality: "good",
    confidence: 0.95,
    fallback: false
  },
  garbage: {
    available: true,
    provider: "demo",
    detected: true,
    damageType: "garbage_pile",
    visualSeverity: 75,
    description: "Uncontrolled accumulation of solid waste and overflowing trash near public walkway.",
    objects: ["garbage_bags", "plastic_waste", "overflowing_bin"],
    imageQuality: "good",
    confidence: 0.92,
    fallback: false
  },
  water: {
    available: true,
    provider: "demo",
    detected: true,
    damageType: "water_leak",
    visualSeverity: 78,
    description: "Significant surface water pooling caused by leaking water pipe main.",
    objects: ["flooding", "water_leakage", "submerged_road"],
    imageQuality: "good",
    confidence: 0.90,
    fallback: false
  },
  infrastructure: {
    available: true,
    provider: "demo",
    detected: true,
    damageType: "broken_infrastructure",
    visualSeverity: 68,
    description: "Damaged public infrastructure element requiring municipal maintenance.",
    objects: ["broken_structure", "safety_hazard"],
    imageQuality: "good",
    confidence: 0.88,
    fallback: false
  }
};

/**
 * Check if image input matches a known demo cache scenario
 * @param {string} imageInput - File path or URL or keyword
 * @returns {object|null} Cached vision result or null if no match
 */
function getDemoCacheResult(imageInput = "") {
  const str = imageInput.toLowerCase();

  // Match demo filenames or keywords
  if (str.includes("pothole") || str.includes("images.jpg") || str.includes("road")) {
    return { ...DEMO_CACHE.pothole };
  }
  if (str.includes("garbage") || str.includes("trash")) {
    return { ...DEMO_CACHE.garbage };
  }
  if (str.includes("water") || str.includes("leak") || str.includes("flood")) {
    return { ...DEMO_CACHE.water };
  }
  if (str.includes("infra") || str.includes("park") || str.includes("light")) {
    return { ...DEMO_CACHE.infrastructure };
  }

  return null;
}

module.exports = { getDemoCacheResult, DEMO_CACHE };
