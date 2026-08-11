# CivicPulse — DEVELOPER_1_FLUTTER.md
**Owner: Flutter App Developer**
Read `MASTER.md` first for data model and architecture. This file is your task list and interface contract.

---

## 1. Responsibilities & Ownership

You own the citizen-facing mobile experience and the app's overall Flutter architecture (navigation, state management, shared widgets) that Developer 3 will also build screens within.

You do **not** own: map rendering logic (Developer 3), or any categorization/priority/trust-score computation (Developer 2, backend-side only).

---

## 2. Screens / User Flows to Implement

### Must Have
1. **Submit Complaint** — title, description, category dropdown, location picker (can be a simple lat/lng capture or manual pin — coordinate with Dev 3 on whether map-based picking lives here or in their screen), photo picker (camera or gallery)
2. **Track Complaint** — enter/scan complaint ID → show status, category, department, priority
3. **Verify Resolution** — shown when status is `awaiting_verification`: "Fixed" / "Still Exists" buttons
4. **Official View (role-switched)** — list of complaints, tap to view detail, "Mark Resolved" button with a short text field
5. **Role Switcher** — simple toggle/dropdown at app start or in a settings screen: Citizen / Official. No real login.

### Nice to Have
- Push/local notification style banner when status changes (can be simulated with a simple in-app alert on refresh)
- Complaint list/history for a citizen (multiple submitted complaints)

---

## 3. Flutter Architecture / Folder Guidance

Keep it flat and simple — this is a 4-hour build, not a production app.

```
lib/
  main.dart
  models/
    complaint.dart        // Complaint data class, fromJson/toJson
    department.dart
  services/
    api_service.dart      // all HTTP calls, single source of truth for backend calls
    mock_data_service.dart // returns fake data, same method signatures as api_service
  screens/
    submit_complaint_screen.dart
    track_complaint_screen.dart
    verify_resolution_screen.dart
    official_dashboard_screen.dart
    complaint_detail_screen.dart
  widgets/
    status_badge.dart
    complaint_card.dart
  state/
    app_state.dart        // simple ChangeNotifier/Provider for current role + active complaint
```

Use **Provider** (or plain `setState` if the team isn't comfortable with Provider) — do not introduce Riverpod/Bloc/GetX under time pressure, they add setup overhead you don't need for an MVP demo.

---

## 4. API / Data Interfaces You Depend On

All defined in full in `DEVELOPER_2_AI_BACKEND.md`. Summary:

| Action | Endpoint | You send | You receive |
|---|---|---|---|
| Submit complaint | `POST /complaints` | title, description, category, location, photoUrl | full complaint object incl. `id` |
| Track complaint | `GET /complaints/:id` | — | full complaint object incl. `category`, `priority`, `department`, `status` |
| List complaints (official view) | `GET /complaints` | optional filters | array of complaint objects |
| Resolve complaint | `PATCH /complaints/:id/resolve` | resolution description | updated complaint object |
| Verify resolution | `PATCH /complaints/:id/verify` | `{ result: "fixed" \| "still_exists" }` | updated complaint object |

**Do not build your own logic to guess category/priority/department in the app.** Always display what the backend returns.

---

## 5. Mock-Data Strategy (so you're never blocked)

Build `mock_data_service.dart` with the **exact same method signatures** as `api_service.dart` (e.g., both expose `submitComplaint()`, `getComplaint(id)`, `listComplaints()`, `resolveComplaint(id, desc)`, `verifyComplaint(id, result)`). Have a single boolean flag (e.g., `useMock = true`) that switches between them app-wide.

Start with `useMock = true` and hardcoded sample complaints (write 5–6 fake ones covering different categories/statuses) so you can build and test every screen immediately, without waiting on Developer 2's backend. Switch to `false` at the 2:00–2:30 integration checkpoint once real endpoints are live.

---

## 6. Integration Checklist

- [ ] `Complaint` model fields match `MASTER.md` data model exactly (field names, types)
- [ ] `api_service.dart` methods match the endpoint table above exactly
- [ ] At the 2:00 checkpoint: switch `useMock` to `false`, test submit → track → resolve → verify end to end against the real backend
- [ ] Confirm your app never writes to `category`, `priority`, `department`, or `trustScore` — only reads them
- [ ] Confirm photo upload produces a URL the backend accepts (agree on upload method with Dev 2 — simplest option: upload to Firebase Storage directly from Flutter and just send the resulting URL string to the backend)
- [ ] Confirm your map-related screens (if any live in your files) correctly hand off to Developer 3's map widget rather than duplicating map logic
- [ ] Run the full demo flow at least twice before the final rehearsal
