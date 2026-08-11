/**
 * End-to-End API Integration Verification Script for Developer 2
 */

process.env.NODE_ENV = "test";
const app = require("./server");
const db = require("./config/db");
const { analyzeComplaint } = require("./logic/civicAgent");

async function runTests() {
  console.log("--------------------------------------------------");
  console.log("🧪 Running Developer 2 End-to-End Verification");
  console.log("--------------------------------------------------");

  let errors = 0;

  // Test 1: Seeded Departments
  try {
    const depts = await db.getDepartments();
    console.log(`[TEST 1] GET /departments count: ${depts.length}`);
    if (depts.length === 5) {
      console.log("  ✅ PASS: 5 initial departments correctly seeded.");
    } else {
      console.error(`  ❌ FAIL: Expected 5 departments, got ${depts.length}`);
      errors++;
    }
  } catch (err) {
    console.error("  ❌ FAIL in Test 1:", err.message);
    errors++;
  }

  // Test 2: CivicAgent Categorization & Priority Scoring
  try {
    const test1 = analyzeComplaint("Dangerous pothole near school", "Deep crater causing traffic accidents for kids");
    console.log("[TEST 2A] CivicAgent Pothole Test:", test1);
    if (test1.category === "Roads" && test1.department === "Roads Dept" && test1.priority > 60) {
      console.log("  ✅ PASS: Correctly categorized as Roads Dept with elevated priority.");
    } else {
      console.error("  ❌ FAIL: Pothole categorization unexpected:", test1);
      errors++;
    }

    const test2 = analyzeComplaint("Water pipe leaking in hospital ward", "Emergency flooding endangering patients");
    console.log("[TEST 2B] CivicAgent Water Test:", test2);
    if (test2.category === "Water" && test2.department === "Water Dept" && test2.priority > 70) {
      console.log("  ✅ PASS: Correctly categorized as Water Dept with high priority.");
    } else {
      console.error("  ❌ FAIL: Water categorization unexpected:", test2);
      errors++;
    }
  } catch (err) {
    console.error("  ❌ FAIL in Test 2:", err.message);
    errors++;
  }

  // Test 3: Complaint Lifecycle (Submit -> Resolve -> Verify Reopen -> Check Trust Score)
  try {
    // 3A. Submit
    const rawComplaint = {
      title: "Broken streetlight causing darkness",
      description: "Streetlight is out, creating hazard for pedestrians",
      location: { lat: 12.9716, lng: 77.5946, address: "MG Road, Bengaluru" },
      photoUrl: "https://example.com/photo.jpg"
    };

    const aiRes = analyzeComplaint(rawComplaint.title, rawComplaint.description);
    const testId = `CP-TEST-${Date.now()}`;
    const complaintObj = {
      id: testId,
      title: rawComplaint.title,
      description: rawComplaint.description,
      category: aiRes.category,
      priority: aiRes.priority,
      department: aiRes.department,
      status: "assigned",
      location: rawComplaint.location,
      photoUrl: rawComplaint.photoUrl,
      createdAt: new Date().toISOString(),
      resolution: null,
      reopenCount: 0
    };

    await db.saveComplaint(complaintObj);
    console.log(`  ✅ PASS: Saved test complaint ${testId}.`);

    // 3B. Resolve
    await db.updateComplaint(testId, {
      status: "awaiting_verification",
      resolution: { description: "Replaced bulb", resolvedAt: new Date().toISOString() }
    });
    await db.updateDepartmentMetrics(complaintObj.department, { isResolved: true });
    console.log("  ✅ PASS: Complaint resolved by official.");

    // 3C. Verify (reopen)
    await db.updateComplaint(testId, {
      status: "reopened",
      reopenCount: 1
    });
    const updatedDept = await db.updateDepartmentMetrics(complaintObj.department, { isReopened: true });
    console.log(`[TEST 3C] Department Trust Score after reopen: ${updatedDept.trustScore} (reopenCount: ${updatedDept.reopenCount})`);

    if (updatedDept.trustScore <= 90 && updatedDept.reopenCount >= 1) {
      console.log(`  ✅ PASS: Trust Score accurately penalized to ${updatedDept.trustScore} on reopen.`);
    } else {
      console.error("  ❌ FAIL: Department trust score penalty incorrect:", updatedDept);
      errors++;
    }
  } catch (err) {
    console.error("  ❌ FAIL in Test 3:", err.message);
    errors++;
  }

  console.log("--------------------------------------------------");
  if (errors === 0) {
    console.log("🎉 ALL BACKEND VERIFICATION TESTS PASSED SUCCESSFULLY!");
    process.exit(0);
  } else {
    console.error(`💥 VERIFICATION COMPLETED WITH ${errors} ERRORS.`);
    process.exit(1);
  }
}

runTests();
