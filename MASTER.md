# CivicPulse — MASTER.md
**Smart Public Complaint Management System (PS8) — CodeSprint'26**
Single source of truth. If any other doc conflicts with this one, this one wins.

---

## 1. Vision & Problem

Public complaint systems don't fail at intake — they fail at accountability. Citizens file complaints, officials mark them "Resolved" with no verification, and nothing forces action when problems are ignored.

**CivicPulse** is a mobile app where citizens report civic issues (potholes, garbage, water leaks, etc.), an AI layer (**CivicAgent**) categorizes and prioritizes them automatically, and resolutions must be verified by the citizen before a complaint closes — making inaction visible and fake resolutions harder.

**Pitch line:** *"We didn't just build a way to file complaints. We built a way to make inaction visible."*

---

## 2. MVP Scope

### Must Have (build these, in this order of priority)
1. Citizen submits a complaint (title, description, category, location, photo)
2. Backend auto-categorizes + assigns priority + routes to a department
3. Citizen can track complaint status by ID
4. Official can view complaints and mark them Resolved
5. Citizen verifies resolution: Fixed → Closed, or Still Exists → Reopened
6. Map view showing complaints as markers, color-coded by status/priority
7. Basic department trust indicator (simple score based on reopen rate)

### Nice to Have (only if core is done early)
- Live "Agent Decision Log" feed (why CivicAgent did what it did)
- Public accountability view (overdue complaints by department)
- SLA countdown + auto-escalation simulation
- "Ask CivicAgent" natural-language query

### Out of Scope (do not build)
- Real authentication/login system (use a role switcher instead)
- Computer vision / photo authenticity checks
- Predictive analytics, trend forecasting
- Voice input, multilingual support
- Any real ML training — all "AI" is rule/keyword-based logic

---

## 3. Core User Flow

```
Citizen opens app
   → Submits complaint (title, description, category, photo, location)
   → Backend receives it, CivicAgent categorizes + scores priority + assigns department
   → Complaint appears on Map + Official dashboard
   → Official marks it "Resolved" (with a short description)
   → Citizen gets notified, opens app, verifies:
        - Fixed → complaint closes
        - Still Exists → complaint reopens, department trust score drops
```

---

## 4. System Architecture

```
[Flutter App]
   ├── Citizen screens (submit, track, verify)
   ├── Map screen (complaint visualization)
   └── Official/Intelligence screens (dashboard, trust score, decision log)
            │
            ▼  REST API (JSON over HTTP)
   [Backend — Node.js + Express]
            │
            ├── CivicAgent logic (categorization, priority, routing, trust score)
            │
            ▼
   [Database — Firebase Firestore]
```

One Flutter app, one backend, one database. No microservices, no separate AI service — keep it in one Express project to minimize integration overhead in 4 hours.

---

## 5. Technology / Stack Assumptions

| Layer | Choice | Why |
|---|---|---|
| Mobile app | **Flutter** | Team decision — single codebase, fast to build UI |
| Backend | **Node.js + Express** | Established in prior planning, simple REST setup |
| Database | **Firebase Firestore** | No server/DB setup overhead, real-time reads work well with Flutter |
| Map | **flutter_map + OpenStreetMap tiles** | No API key required, works offline-friendly for setup speed |
| AI | **Rule/keyword-based logic in the backend** | No training needed, fully explainable, buildable in hours not days |
| Auth | **None — role switcher (Citizen/Official) in-app** | Real auth is out of scope for a 4-hour MVP |

If Firestore setup fails at venue (no internet / account issues), fallback is a local JSON file served by Express — document this decision in COLLABORATION.md if it happens, don't silently change it.

---

## 6. Data Model

### `complaints`
```json
{
  "id": "CP-2026-00214",
  "title": "string",
  "description": "string",
  "category": "string",        // set by backend/CivicAgent
  "priority": 0,                // 0-100, set by backend
  "department": "string",       // set by backend
  "status": "submitted | assigned | in_progress | resolved | awaiting_verification | verified | closed | reopened",
  "location": { "lat": 0.0, "lng": 0.0, "address": "string" },
  "photoUrl": "string",
  "createdAt": "timestamp",
  "resolution": { "description": "string", "resolvedAt": "timestamp" },
  "reopenCount": 0
}
```

### `departments`
```json
{
  "name": "string",
  "trustScore": 100,
  "totalComplaints": 0,
  "resolvedCount": 0,
  "reopenCount": 0
}
```

### `decisionLog` (Nice to Have)
```json
{ "timestamp": "timestamp", "complaintId": "string", "action": "string", "reason": "string" }
```

**Ownership rule:** the Flutter app never computes `category`, `priority`, `department`, or `trustScore` — it only sends raw submission data and reads back what the backend returns. This is the core contract between Developer 1 and Developer 2.

---

## 7. Integration Points Between Developers

| Point | Who → Who | What crosses the boundary |
|---|---|---|
| Complaint submission | Flutter → Backend | `POST /complaints` with raw citizen input |
| AI-processed data | Backend → Flutter | `category`, `priority`, `department`, `status` on every complaint read |
| Map data | Backend → Map dev | List of complaints with `location`, `status`, `priority` |
| Department routing display | Backend → Map dev | `department` field + `departments` collection for trust scores |
| Verification | Flutter → Backend | `PATCH /complaints/:id/verify` |

Full endpoint specs live in `DEVELOPER_2_AI_BACKEND.md` — that file is the contract for every request/response shape.

---

## 8. Definition of Done (MVP)

A complaint can be:
1. Submitted from the Flutter app with a photo and location
2. Automatically categorized, scored, and routed by the backend
3. Seen on the map, color-coded by status
4. Marked Resolved by an official (in-app role switch)
5. Verified or disputed by the citizen, with status updating correctly
6. All of the above demoable live, end-to-end, without a crash

If steps 1–6 work, ship it. Anything beyond this is bonus, not required.

---

## 9. 4-Hour Execution Priorities

| Time | Priority |
|---|---|
| 0:00–0:20 | All three: agree on data model (this doc) and API contract — do not skip this sync |
| 0:20–2:00 | Build Must Haves in parallel per developer doc |
| 2:00–2:30 | **Mandatory integration checkpoint** — connect Flutter ↔ Backend ↔ Map, fix breakage immediately |
| 2:30–3:30 | Continue Must Haves; only start Nice to Haves if fully done |
| 3:30–3:50 | Final integration test, seed demo data, fix crashes only |
| 3:50–4:00 | Rehearse demo once, as a team |

If behind schedule at 2:30, cut Nice to Haves first, then trim Must Haves in this order: trust score → map color-coding → verification flow (never cut submission → tracking → resolve, that's your minimum demoable path).
