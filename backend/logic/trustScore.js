/**
 * Trust Score Calculation Engine for Departments
 * Formula: trustScore = max(0, 100 - (departmentReopenCount * 10))
 */

/**
 * Calculates updated trust score for a department given its total reopen count.
 * @param {number} reopenCount - Cumulative reopen count for the department
 * @returns {number} Trust score (0 to 100)
 */
function calculateTrustScore(reopenCount = 0) {
  const score = 100 - (reopenCount * 10);
  return Math.max(0, score);
}

module.exports = {
  calculateTrustScore
};
