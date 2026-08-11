# CivicPulse — DEVELOPER_2_AI_BACKEND.md
**Owner: AI + Backend Developer**
Read `MASTER.md` first for data model and architecture. This file is your task list and the authoritative API contract — Developer 1 and Developer 3 both build against what's specified here.

---

## 1. Responsibilities & Ownership

You own the backend server, the database, and all "CivicAgent" logic: categorization, priority scoring, department routing, and trust score calculation. You are the only one who writes these computed fields — Flutter and the map layer only ever read them.

---

## 2. Backend / API / Database Requirements

- **Server:** Node.js + Express, single project, REST endpoints (JSON)
- **Database:** Firebase Firestore — collections: `complaints`, `departments` (schema in `MASTER.md`)
- **Photo storage:** simplest option — Flutter uploads directly to Firebase Storage and sends you the resulting URL string; you just store the string. Do not build a file-upload endpoint yourself unless Dev 1 can't get direct Storage upload working — confirm this at the 0:20 sync.
- Seed `departments` collection at startup with fixed entries: Roads, Sanitation, Water, Electricity, Public Infrastructure — each starting at `trustScore: 100`.

---

## 3. Complaint Categorization Flow

On `POST /complaints`, before saving, run the complaint through CivicAgent logic in this order:

1. **Categorize** — keyword match against `title` + `description`:
   - Roads/potholes, Garbage/Sanitation, Water leakage, Drainage, Electricity, Streetlights, Public Infrastructure, Parks, Other
   - Simple approach: a lookup table of keywords → category, first match wins, default to "Other"
2. **Score priority (0–100)** — base score per category (pick reasonable defaults, e.g. water leak=60, pothole=50, garbage=40) + boost if description contains safety-risk keywords (school, hospital, accident, danger, children) → cap at 100
3. **Assign department** — category → department lookup table (1:1 mapping, keep it simple):
   - Roads/potholes → Roads Dept
   - Garbage/Sanitation → Sanitation Dept
   - Water leakage/Drainage → Water Dept
   - Electricity/Streetlights → Electricity Dept
   - Public Infrastructure/Parks/Other → Public Infrastructure Dept

Write `category`, `priority`, `department` onto the complaint document, set `status: assigned`, then return the full object.

---

## 4. AI Input/Output Contract

**Input** (from the submission payload):
```json
{ "title": "string", "description": "string" }
```

**Output** (fields you compute and attach):
```json
{ "category": "string", "priority": 0, "department": "string" }
```

Keep this function pure and isolated (e.g., a single `analyzeComplaint(title, description)` function) so it's easy to test independently and easy to explain to judges in one sentence if asked.

---

## 5. Department Assignment Logic (Trust Score)

On every `verify` call where `result: "still_exists"`:
- Increment `reopenCount` on the complaint
- Increment `reopenCount` on the department
- Recalculate `trustScore`: simple formula, e.g. `trustScore = 100 - (departmentReopenCount * 10)`, floor at 0
- On every `resolve` call, increment department `resolvedCount`; on `verify: fixed`, no penalty

Keep the formula in one function, e.g. `recalculateTrustScore(department)` — same reasoning as above: simple and explainable beats clever and fragile.

---

## 6. API Contracts Required by Flutter (and Map dev)

| Method | Endpoint | Request Body | Response |
|---|---|---|---|
| POST | `/complaints` | `{ title, description, category?, location: {lat, lng, address}, photoUrl }` | full complaint object with `id`, `category`, `priority`, `department`, `status: "assigned"` |
| GET | `/complaints/:id` | — | full complaint object |
| GET | `/complaints` | optional query: `?department=`, `?status=` | array of complaint objects |
| PATCH | `/complaints/:id/resolve` | `{ description }` | updated complaint, `status: "awaiting_verification"` |
| PATCH | `/complaints/:id/verify` | `{ result: "fixed" \| "still_exists" }` | updated complaint, `status: "verified"` or `"reopened"` |
| GET | `/departments` | — | array of department objects incl. `trustScore` |

`category` sent by the client on submission (if any) is treated as a suggestion only — your `analyzeComplaint` function always overrides it. Document any deviation from this table immediately in the team chat if you change a field name or shape — Dev 1 and Dev 3 are building against this exact contract.

---

## 7. Integration Checklist

- [ ] All endpoints above implemented and manually tested (curl/Postman) before the 2:00 checkpoint
- [ ] `departments` collection seeded and `GET /departments` returns real data
- [ ] `analyzeComplaint()` tested against at least 8–10 varied sample complaint texts, confirm category/priority look reasonable
- [ ] At 2:00 checkpoint: confirm Dev 1's Flutter app can hit your real endpoints successfully (switch off their mock flag together)
- [ ] Confirm Dev 3 can read `GET /complaints` and `GET /departments` for map + trust score display
- [ ] CORS enabled if Flutter web is used for testing; not required for mobile-only builds
- [ ] No breaking changes to field names/response shapes after the 2:00 checkpoint without notifying both other devs immediately
