# CivicPulse — DEVELOPER_3_MAP_INTELLIGENCE.md
**Owner: Map + Supporting Intelligence Developer**
Read `MASTER.md` first for data model and architecture. This file is your task list and interface contract.

---

## 1. Responsibilities & Ownership

You own the map screen (built as a Flutter widget within the shared app — coordinate folder placement with Developer 1) and the "intelligence" visuals: complaint visualization on the map, department/location routing display, and trust score presentation. You do not compute any of this data — you only render what Developer 2's backend returns.

---

## 2. Map / Location Functionality

- **Package:** `flutter_map` + OpenStreetMap tile layer (no API key needed — matches the stack assumption in `MASTER.md`)
- Map screen shows all complaints as markers at their `location.lat`/`location.lng`
- Tapping a marker shows a summary card: title, category, status, priority
- If time allows: tapping the card navigates to the full complaint detail screen (owned by Dev 1 — coordinate the navigation route/widget hookup with them directly, don't duplicate the detail screen)

**Location capture for submission:** decide with Developer 1 at the 0:20 sync whether the location picker lives on your map widget (embedded in the submit screen) or is a separate simple lat/lng field they own. Simplest option for 4 hours: you provide a reusable `LocationPickerWidget` that Dev 1 drops into their submit screen — build this early since Dev 1 depends on it.

---

## 3. Complaint Visualization

- Color-code markers by `status`:
  - Submitted/Assigned → yellow
  - In Progress → orange
  - Resolved/Verified/Closed → green
  - Reopened → red
- Optional (Nice to Have): size or highlight markers by `priority` (higher priority = larger/pulsing marker)
- Keep marker rendering simple — a colored pin icon is enough, don't spend time on custom marker graphics

---

## 4. Department / Location Routing

- Fetch `GET /departments` and display a simple **trust score list**: department name + score, color-coded (red <50, orange 50–75, green >75)
- This can be a simple screen or a panel/bottom-sheet on the map screen — your call, keep it minimal
- If "Public Accountability Wall" (Nice to Have) is attempted: same data, reframed as a read-only public screen showing overdue/reopened complaints by department — only build this after all Must Haves across the team are done

---

## 5. Supporting Intelligence / Features

Priority order — only move to the next item if the previous is solid:

1. **Must Have:** Map with color-coded complaint markers (Section 3)
2. **Must Have:** Department trust score display (Section 4)
3. **Nice to Have:** Live "Agent Decision Log" feed — if Dev 2 exposes a `decisionLog` array/endpoint, render it as a simple scrolling list (timestamp + action + reason). Poll every few seconds; real-time listeners are a bonus, not required.
4. **Nice to Have:** Public Accountability Wall
5. **Nice to Have:** "Ask CivicAgent" query box (only if Dev 2 has time to add a simple LLM-backed endpoint — do not attempt this yourselves without backend support)

---

## 6. Interfaces with Flutter / Backend

| You need | From | Endpoint / Widget |
|---|---|---|
| Complaint list with locations | Backend (Dev 2) | `GET /complaints` |
| Department trust scores | Backend (Dev 2) | `GET /departments` |
| Navigation to complaint detail | Flutter (Dev 1) | shared route/widget — coordinate directly, don't duplicate |
| Location picker consumed by | Flutter (Dev 1) | you provide `LocationPickerWidget`, they embed it |

You consume the exact same `Complaint` and `Department` model shapes defined in `MASTER.md` — if Dev 1 has already written `models/complaint.dart` and `models/department.dart`, reuse those, don't create your own duplicate models.

---

## 7. Integration Checklist

- [ ] `LocationPickerWidget` built and handed to Dev 1 before the 2:00 checkpoint (they're blocked on this for the submit screen)
- [ ] Map renders correctly with mock data before backend is ready — use the same mock complaints Dev 1 seeds, don't invent your own
- [ ] At 2:00 checkpoint: switch map data source to real `GET /complaints`, confirm markers appear correctly
- [ ] Trust score display pulls from real `GET /departments`, updates correctly after a test reopen (verify with Dev 2)
- [ ] Confirm you're not computing category/priority/trust score yourself anywhere — display-only
- [ ] Full map + trust score flow tested end to end at least twice before final rehearsal
