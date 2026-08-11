/**
 * CivicPulse — Persistent SQLite Database Layer (`backend/civicpulse.db`)
 * Fully persistent, zero cloud setup, thread-safe, fast SQL database.
 */

const path = require("path");
const sqlite3 = require("sqlite3").verbose();
const initialDepartments = require("../data/seedDepartments");
const { calculateTrustScore } = require("../logic/trustScore");

const DB_PATH = process.env.SQLITE_DB_PATH
  ? path.resolve(process.env.SQLITE_DB_PATH)
  : path.join(__dirname, "..", "civicpulse.db");
const dbSqlite = new sqlite3.Database(DB_PATH);

console.log(`[DB] Connected to persistent SQLite database at ${DB_PATH}`);

// Promisified helper functions for SQLite queries
function runAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    dbSqlite.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

function getAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    dbSqlite.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

function allAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    dbSqlite.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows || []);
    });
  });
}

// Initialize tables and seed initial departments
async function initTables() {
  try {
    // 1. Departments table
    await runAsync(`
      CREATE TABLE IF NOT EXISTS departments (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        trustScore INTEGER NOT NULL DEFAULT 100,
        totalComplaints INTEGER NOT NULL DEFAULT 0,
        resolvedCount INTEGER NOT NULL DEFAULT 0,
        reopenCount INTEGER NOT NULL DEFAULT 0
      )
    `);

    // 2. Complaints table
    await runAsync(`
      CREATE TABLE IF NOT EXISTS complaints (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL DEFAULT 'user_anonymous',
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        priority INTEGER NOT NULL,
        department TEXT NOT NULL,
        status TEXT NOT NULL,
        location TEXT,
        photoUrl TEXT,
        createdAt TEXT NOT NULL,
        resolution TEXT,
        reopenCount INTEGER NOT NULL DEFAULT 0,
        aiAnalysis TEXT
      )
    `);

    // Add fields introduced after the first local database version.
    const complaintColumns = await allAsync("PRAGMA table_info(complaints)");
    if (!complaintColumns.some(column => column.name === "userId")) {
      await runAsync(
        "ALTER TABLE complaints ADD COLUMN userId TEXT NOT NULL DEFAULT 'user_anonymous'"
      );
      console.log("[DB] Migrated complaints table: added userId.");
    }

    // 3. Decision Logs table
    await runAsync(`
      CREATE TABLE IF NOT EXISTS decision_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        complaintId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        action TEXT NOT NULL,
        logData TEXT NOT NULL
      )
    `);

    // Seed initial departments if table is empty
    const existingDepts = await allAsync("SELECT * FROM departments");
    if (existingDepts.length === 0) {
      for (const dept of initialDepartments) {
        await runAsync(
          "INSERT OR IGNORE INTO departments (id, name, trustScore, totalComplaints, resolvedCount, reopenCount) VALUES (?, ?, ?, ?, ?, ?)",
          [dept.id, dept.name, dept.trustScore, dept.totalComplaints, dept.resolvedCount, dept.reopenCount]
        );
      }
      console.log("[DB] Seeded 5 initial departments into SQLite database.");
    }
  } catch (err) {
    console.error("[DB] Table initialization error:", err.message);
  }
}

// Initialize tables promise
const initPromise = initTables();

// Helper to ensure database is initialized before any query runs
async function ensureInit() {
  await initPromise;
}

// Helper to parse JSON fields safely
function parseComplaintRow(row) {
  if (!row) return null;
  return {
    ...row,
    location: row.location ? JSON.parse(row.location) : { lat: 0.0, lng: 0.0, address: "Unspecified location" },
    resolution: row.resolution ? JSON.parse(row.resolution) : null,
    aiAnalysis: row.aiAnalysis ? JSON.parse(row.aiAnalysis) : null
  };
}

const db = {
  /**
   * Get all departments
   */
  async getDepartments() {
    await ensureInit();
    return await allAsync("SELECT * FROM departments");
  },

  /**
   * Get department by name
   */
  async getDepartmentByName(deptName) {
    await ensureInit();
    return await getAsync("SELECT * FROM departments WHERE name = ?", [deptName]);
  },

  /**
   * Update department metrics
   */
  async updateDepartmentMetrics(deptName, { isResolved = false, isReopened = false, incrementTotal = false }) {
    await ensureInit();
    let dept = await db.getDepartmentByName(deptName);
    if (!dept) {
      const newId = `dept-${deptName.toLowerCase().replace(/\s+/g, "-")}`;
      await runAsync(
        "INSERT INTO departments (id, name, trustScore, totalComplaints, resolvedCount, reopenCount) VALUES (?, ?, ?, ?, ?, ?)",
        [newId, deptName, 100, 0, 0, 0]
      );
      dept = await db.getDepartmentByName(deptName);
    }

    let totalComplaints = dept.totalComplaints || 0;
    let resolvedCount = dept.resolvedCount || 0;
    let reopenCount = dept.reopenCount || 0;
    let trustScore = dept.trustScore;

    if (incrementTotal) totalComplaints += 1;
    if (isResolved) resolvedCount += 1;
    if (isReopened) {
      reopenCount += 1;
      trustScore = calculateTrustScore(reopenCount);
    }

    await runAsync(
      "UPDATE departments SET totalComplaints = ?, resolvedCount = ?, reopenCount = ?, trustScore = ? WHERE name = ?",
      [totalComplaints, resolvedCount, reopenCount, trustScore, deptName]
    );

    return await db.getDepartmentByName(deptName);
  },

  /**
   * Save new complaint
   */
  async saveComplaint(complaint) {
    await ensureInit();
    const locationJson = JSON.stringify(complaint.location || { lat: 0.0, lng: 0.0, address: "Unspecified location" });
    const resolutionJson = complaint.resolution ? JSON.stringify(complaint.resolution) : null;
    const aiAnalysisJson = complaint.aiAnalysis ? JSON.stringify(complaint.aiAnalysis) : null;

    await runAsync(
      `INSERT OR REPLACE INTO complaints
       (id, userId, title, description, category, priority, department, status, location, photoUrl, createdAt, resolution, reopenCount, aiAnalysis)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        complaint.id,
        complaint.userId || "user_anonymous",
        complaint.title,
        complaint.description,
        complaint.category,
        complaint.priority,
        complaint.department,
        complaint.status,
        locationJson,
        complaint.photoUrl || "",
        complaint.createdAt || new Date().toISOString(),
        resolutionJson,
        complaint.reopenCount || 0,
        aiAnalysisJson
      ]
    );

    if (complaint.department) {
      await db.updateDepartmentMetrics(complaint.department, { incrementTotal: true });
    }

    return complaint;
  },

  /**
   * Get complaint by ID
   */
  async getComplaintById(id) {
    await ensureInit();
    const row = await getAsync("SELECT * FROM complaints WHERE id = ?", [id]);
    return parseComplaintRow(row);
  },

  /**
   * List all complaints with optional filtering
   */
  async getComplaints(filter = {}) {
    await ensureInit();
    let sql = "SELECT * FROM complaints WHERE 1=1";
    const params = [];

    if (filter.department) {
      sql += " AND department = ?";
      params.push(filter.department);
    }
    if (filter.status) {
      sql += " AND status = ?";
      params.push(filter.status);
    }

    sql += " ORDER BY createdAt DESC";
    const rows = await allAsync(sql, params);
    return rows.map(parseComplaintRow);
  },

  /**
   * Update existing complaint
   */
  async updateComplaint(id, updateFields) {
    await ensureInit();
    const existing = await db.getComplaintById(id);
    if (!existing) return null;

    const updated = { ...existing, ...updateFields };
    const locationJson = JSON.stringify(updated.location);
    const resolutionJson = updated.resolution ? JSON.stringify(updated.resolution) : null;
    const aiAnalysisJson = updated.aiAnalysis ? JSON.stringify(updated.aiAnalysis) : null;

    await runAsync(
      `UPDATE complaints SET
       userId = ?, title = ?, description = ?, category = ?, priority = ?, department = ?,
       status = ?, location = ?, photoUrl = ?, resolution = ?, reopenCount = ?, aiAnalysis = ? 
       WHERE id = ?`,
      [
        updated.userId || "user_anonymous",
        updated.title,
        updated.description,
        updated.category,
        updated.priority,
        updated.department,
        updated.status,
        locationJson,
        updated.photoUrl || "",
        resolutionJson,
        updated.reopenCount || 0,
        aiAnalysisJson,
        id
      ]
    );

    return updated;
  },

  /**
   * Save decision log entry
   */
  async saveDecisionLog(log) {
    await ensureInit();
    const logDataJson = JSON.stringify(log);
    await runAsync(
      "INSERT INTO decision_logs (complaintId, timestamp, action, logData) VALUES (?, ?, ?, ?)",
      [log.complaintId || "unknown", log.timestamp || new Date().toISOString(), log.action || "AI_ANALYSIS", logDataJson]
    );
    return log;
  },

  /**
   * Get decision logs for a complaint
   */
  async getDecisionLogs(complaintId) {
    await ensureInit();
    const rows = await allAsync(
      "SELECT * FROM decision_logs WHERE complaintId = ? ORDER BY id ASC",
      [complaintId]
    );
    return rows.map(r => JSON.parse(r.logData));
  },

  /**
   * Get global feed of recent decision logs
   */
  async getAllDecisionLogs(limit = 30) {
    await ensureInit();
    const rows = await allAsync(
      "SELECT * FROM decision_logs ORDER BY id DESC LIMIT ?",
      [limit]
    );
    return rows.map(r => JSON.parse(r.logData));
  },

  async close() {
    await ensureInit();
    return new Promise((resolve, reject) => {
      dbSqlite.close(error => {
        if (error) reject(error);
        else resolve();
      });
    });
  }
};

module.exports = db;
