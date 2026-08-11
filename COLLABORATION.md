# CivicPulse — COLLABORATION.md
**Team rules for a 3-person, 4-hour build.**

---

## 1. Git Branching / Commit / Merge Rules

- `main` branch = always working/demoable. Never commit broken code directly to `main`.
- Each developer works on their own branch:
  - `feature/flutter-app` (Dev 1)
  - `feature/ai-backend` (Dev 2)
  - `feature/map-intelligence` (Dev 3)
- Commit small, commit often — every 15–20 minutes minimum, with a short message describing what changed (`add complaint submission form`, not `wip`)
- Merge to `main` only at the two scheduled checkpoints (2:00 and 3:30 in `MASTER.md`'s timeline) — not continuously. This avoids mid-build breakage while everyone's heads-down.
- Before merging: pull `main`, resolve conflicts locally, confirm your own feature still runs, then push.
- No force-pushing to `main`, ever.

---

## 2. Shared API/Data Contracts

- The single source of truth for data shapes is `MASTER.md` (Section 6) and `DEVELOPER_2_AI_BACKEND.md` (Section 6, API table).
- If a contract needs to change (a field renamed, a new required field, etc.), the developer proposing the change must say so out loud to the other two **before** implementing it — not after. Update the relevant `.md` file in the same commit as the code change.
- Nobody assumes a field exists that isn't documented in `MASTER.md`.

---

## 3. File / Module Ownership

| Area | Owner | Others should... |
|---|---|---|
| `lib/screens/submit_*`, `track_*`, `verify_*`, `official_*`, `state/`, `services/api_service.dart` | Dev 1 | Not edit directly — request via chat |
| `lib/screens/map_*`, `LocationPickerWidget`, trust score/decision log widgets | Dev 3 | Not edit directly — request via chat |
| `backend/` (all Express routes, CivicAgent logic, Firestore setup) | Dev 2 | Not edit directly — request via chat |
| `lib/models/` | Shared — created by Dev 1, read by all | Anyone can propose additions, but only Dev 1 merges changes to avoid duplicate/conflicting models |

If you need something changed in a file you don't own, ask the owner to make the change — don't silently edit someone else's in-progress file.

---

## 4. How the Three Developers Coordinate

- **0:00–0:20** — mandatory joint sync: confirm data model, API contract, and who's building the `LocationPickerWidget` handoff. Do not start coding before this is settled.
- **Every ~60 minutes** — 2-minute check-in: what's done, what's blocked, any contract changes needed.
- **2:00** — mandatory integration checkpoint: merge everything to `main`, connect Flutter ↔ Backend ↔ Map with real data, fix breakage together before continuing.
- **3:30** — final integration checkpoint: same as above, plus seed demo data together.
- Use one shared chat thread for anything that affects another person's work — don't let contract changes surface for the first time at a merge.

---

## 5. Rules for Using AI Coding Agents

- AI agents (Claude Code, Copilot, etc.) are welcome for speed — use them freely inside your own owned files.
- **Never let an AI agent touch files outside your ownership** (see Section 3) without the owner's knowledge — agents will happily "helpfully" refactor a shared file if asked loosely; scope your prompts to your own folder/files explicitly.
- **Never let an AI agent change the data model or API contract on its own initiative.** If an agent suggests a different field name or structure, that's a proposal to bring to the team, not something to merge silently.
- Review every AI-generated change before committing — especially anything touching `models/`, API routes, or Firestore schema. Don't commit code you haven't read.
- If an agent generates a large refactor "while it's at it," reject it and ask for the minimal diff instead — see Section 6.

---

## 6. Rules Against Unnecessary Refactoring / Dependency Changes

- Do not add new packages/dependencies without a quick team check — every new dependency is setup risk in a 4-hour window.
- Do not refactor working code for style/elegance during the build — if it works and matches the contract, leave it.
- No swapping state management approaches, restructuring folders, or renaming established fields after the 0:20 sync, unless agreed by all three.
- If you find a genuinely better approach mid-build, note it, keep building with what's agreed, revisit only if there's slack time after 3:30.

---

## 7. Testing & Integration Procedure

1. Test your own feature in isolation using mock data before the 2:00 checkpoint (Dev 1 and Dev 3 both use mock data per their docs; Dev 2 tests endpoints via curl/Postman).
2. At 2:00: merge all branches to `main`, switch mock flags off, run the full flow together: submit → categorize → map marker appears → resolve → verify → trust score updates.
3. Fix breakage as a team immediately — don't let one person debug alone while the other two idle if it's blocking the demo path.
4. At 3:30: repeat the full flow with seeded, realistic demo data (5–8 complaints across categories/statuses) to confirm everything looks good for the live run.
5. Run the actual demo script twice before presenting.

---

## 8. Handling Conflicts or Changes to Shared Interfaces

- If two people need to change the same file: whoever has the change ready first posts it in the shared chat, the other waits and pulls after merge — don't both edit simultaneously.
- If a contract change is needed late (after 2:00): only make it if it doesn't break already-working integration — prefer additive changes (new optional field) over renaming/removing existing ones.
- If a merge conflict happens: resolve by keeping both changes if possible; if genuinely conflicting logic, the file owner (Section 3) makes the final call to keep momentum.
- When in doubt, prioritize a working end-to-end demo over a "more correct" implementation — this is a 4-hour MVP, not production software.
