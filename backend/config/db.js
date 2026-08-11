/**
 * Database Abstraction Layer for CivicPulse
 * Uses Firebase Firestore if credentials exist, otherwise falls back to local in-memory store.
 */

const initialDepartments = require("../data/seedDepartments");
const { calculateTrustScore } = require("../logic/trustScore");

let dbInstance = null;
let isFirestore = false;

// Local in-memory storage fallback
const localStore = {
  complaints: new Map(),
  departments: new Map(),
  decisionLogs: new Map()
};

// Seed initial departments into local store
initialDepartments.forEach(dept => {
  localStore.departments.set(dept.name, { ...dept });
});

function initDb() {
  try {
    const admin = require("firebase-admin");
    let serviceAccount = null;

    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } else {
      try {
        serviceAccount = require("../serviceAccountKey.json");
      } catch (err) {
        // serviceAccountKey.json not present
      }
    }

    if (serviceAccount && !admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      dbInstance = admin.firestore();
      isFirestore = true;
      console.log("[DB] Connected to Firebase Firestore");
    } else {
      console.log("[DB] Firebase credentials not found. Using fast Local Memory Store.");
    }
  } catch (error) {
    console.log("[DB] Firestore init error, using Local Memory Store fallback:", error.message);
  }
}

// Initialize database
initDb();

const db = {
  /**
   * Get all departments
   */
  async getDepartments() {
    if (isFirestore) {
      const snapshot = await dbInstance.collection("departments").get();
      if (snapshot.empty) {
        // Seed departments to Firestore if empty
        const batch = dbInstance.batch();
        initialDepartments.forEach(dept => {
          const docRef = dbInstance.collection("departments").doc(dept.name);
          batch.set(docRef, dept);
        });
        await batch.commit();
        return initialDepartments;
      }
      return snapshot.docs.map(doc => doc.data());
    } else {
      return Array.from(localStore.departments.values());
    }
  },

  /**
   * Get department by name
   */
  async getDepartmentByName(deptName) {
    if (isFirestore) {
      const doc = await dbInstance.collection("departments").doc(deptName).get();
      return doc.exists ? doc.data() : null;
    } else {
      return localStore.departments.get(deptName) || null;
    }
  },

  /**
   * Update department metrics (resolvedCount, reopenCount, trustScore)
   */
  async updateDepartmentMetrics(deptName, { isResolved = false, isReopened = false, incrementTotal = false }) {
    let dept = await db.getDepartmentByName(deptName);
    if (!dept) {
      dept = {
        id: `dept-${deptName.toLowerCase().replace(/\s+/g, "-")}`,
        name: deptName,
        trustScore: 100,
        totalComplaints: 0,
        resolvedCount: 0,
        reopenCount: 0
      };
    }

    if (incrementTotal) dept.totalComplaints = (dept.totalComplaints || 0) + 1;
    if (isResolved) dept.resolvedCount = (dept.resolvedCount || 0) + 1;
    if (isReopened) {
      dept.reopenCount = (dept.reopenCount || 0) + 1;
      dept.trustScore = calculateTrustScore(dept.reopenCount);
    }

    if (isFirestore) {
      await dbInstance.collection("departments").doc(deptName).set(dept, { merge: true });
    } else {
      localStore.departments.set(deptName, dept);
    }

    return dept;
  },

  /**
   * Save new complaint
   */
  async saveComplaint(complaint) {
    if (isFirestore) {
      await dbInstance.collection("complaints").doc(complaint.id).set(complaint);
    } else {
      localStore.complaints.set(complaint.id, complaint);
    }
    // Increment total count on target department
    if (complaint.department) {
      await db.updateDepartmentMetrics(complaint.department, { incrementTotal: true });
    }
    return complaint;
  },

  /**
   * Get complaint by ID
   */
  async getComplaintById(id) {
    if (isFirestore) {
      const doc = await dbInstance.collection("complaints").doc(id).get();
      return doc.exists ? doc.data() : null;
    } else {
      return localStore.complaints.get(id) || null;
    }
  },

  /**
   * List all complaints, with optional department & status filtering
   */
  async getComplaints(filter = {}) {
    let list = [];
    if (isFirestore) {
      let query = dbInstance.collection("complaints");
      if (filter.department) query = query.where("department", "==", filter.department);
      if (filter.status) query = query.where("status", "==", filter.status);
      const snapshot = await query.get();
      list = snapshot.docs.map(doc => doc.data());
    } else {
      list = Array.from(localStore.complaints.values());
      if (filter.department) {
        list = list.filter(c => c.department === filter.department);
      }
      if (filter.status) {
        list = list.filter(c => c.status === filter.status);
      }
    }
    return list;
  },

  /**
   * Update existing complaint
   */
  async updateComplaint(id, updateFields) {
    const existing = await db.getComplaintById(id);
    if (!existing) return null;

    const updated = { ...existing, ...updateFields };

    if (isFirestore) {
      await dbInstance.collection("complaints").doc(id).update(updateFields);
    } else {
      localStore.complaints.set(id, updated);
    }

    return updated;
  },

  /**
   * Save a decision log entry
   */
  async saveDecisionLog(log) {
    const key = log.complaintId || 'unknown';
    if (isFirestore) {
      await dbInstance.collection('decisionLogs').add(log);
    } else {
      if (!localStore.decisionLogs.has(key)) localStore.decisionLogs.set(key, []);
      localStore.decisionLogs.get(key).push(log);
    }
    return log;
  },

  /**
   * Get decision logs for a complaint
   */
  async getDecisionLogs(complaintId) {
    if (isFirestore) {
      const snapshot = await dbInstance.collection('decisionLogs')
        .where('complaintId', '==', complaintId).get();
      return snapshot.docs.map(doc => doc.data());
    } else {
      return localStore.decisionLogs.get(complaintId) || [];
    }
  }
};

module.exports = db;
