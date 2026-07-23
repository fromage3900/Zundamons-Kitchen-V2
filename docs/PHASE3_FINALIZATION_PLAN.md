# Phase 3 Finalization — Deep Review & Game Plan

Author: Claude (deep review pass)
Date: 2026-07-23
Branch: `codex/core-production-baseline`
Basis: line-by-line diff review of the uncommitted working tree vs `HEAD`, cross-checked against `TODO.md` and `docs/PHASE3_ACCEPTANCE_STATUS.md`.

---

## 0. TL;DR

The Phase 3 *code* is in reasonable shape and several fixes are genuinely correct. **But the tracking docs materially misdescribe two of the seven "fixes," the whole tree is uncommitted (~6.3k lines), and the only thing actually blocking "Phase 3 done" is runtime Studio verification** — which has not been run for any of the July fixes.

Finalizing Phase 3 = **(A) reconcile docs to reality, (B) clean the tree so it's committable and buildable, (C) run the 9 Studio runtime gates.** Nothing else is on the critical path.

---

## 1. Deep review findings

### 1.1 Fixes that are CORRECT (verified against source)

| Fix | Verdict | Evidence |
| --- | --- | --- |
| **CookingController** intent-only notes | ✅ Correct | Client no longer sends `"miss"`; sends only `(sessionId, noteIndex:number)`. Server `CookingService.hit` rejects non-number indices, and `CookingService.step` auto-advances `nextExpected` past expired OK-windows and counts remaining notes as misses at `finishAt`. Server fully owns quality. No forgeable path remains. |
| **VNController** welcome timing | ✅ Correct (better than documented) | Replaces `task.delay(2.5)` with a 10s poll loop **plus** a `_G.ZundaVN_welcomeShown` session guard so welcome fires once, not on every respawn. The doc only described the polling. |
| **HarvestController** remote hardening | ✅ Correct | `FindFirstChild` → `WaitForChild("RemoteEvents",5)/WaitForChild("HarvestNode",5)` with a warning on miss. Sound. |

### 1.2 Fixes the docs MISDESCRIBE (integrity gaps — fix the docs, and in one case the code)

**A. CompanionManager — the doc's central claim is false.**
`TODO.md` and `PHASE3_ACCEPTANCE_STATUS.md` state: *"Removed fragile InsertService/workspace fallback paths (7-level chain → 2-level)… primary load from `workspace.ServerStorage.zundapalupdate4`."*
The actual code does the opposite:
- **Primary path is still `InsertService:LoadAsset(assetId)`** — the exact mechanism the doc says was removed.
- Fallback order is now: InsertService → `workspace.zundapalupdate4` → `ServerStorage` (recursive find) → **a procedural green-cube placeholder Model**. That's 4 levels ending in a cube, not "2-level."
- **Regression risk:** the new `PrimaryPart` assignments use `clone:FindFirstChildWhichIsA("BasePart")` **without the recursive `true` flag** (the old code passed `true`). If the mesh's parts are nested under a sub-Model, `PrimaryPart` resolves to `nil`, the branch is skipped, and load silently falls through toward the cube.
- **Suspect reasoning:** the inline comment asserts `InsertService:LoadAsset` returns the model at the root. It actually returns a **container Model** whose children are the asset — cloning the container and then doing a non-recursive `PrimaryPart` lookup is exactly the failure case above.
- **Action:** Either (a) rewrite the doc to describe the real 4-level chain, or (b) make the code match the documented intent (drop InsertService as primary, lead with the workspace/ServerStorage prefab, restore recursive BasePart lookup). Recommended: **(b)** — it's what the doc promises and avoids the InsertService-in-Studio fragility the doc itself complains about. Must be validated by the companion Studio gate.

**B. HarvestValidator "Seeded" fix — diagnosis is factually wrong; server change is inert.**
The doc claims wild flower/mushroom nodes were rejected because `node:GetAttribute("Seeded") == false` evaluated true for `nil`. **In Lua `nil == false` is `false`**, so the original code never rejected wild (attribute-absent) nodes. The server-side "fix" (`seeded ~= nil and seeded == false`) is therefore **behaviorally identical** to the original for wild nodes — a no-op.
- The *real* behavioral change is client-side: `HarvestController.startHarvest` now **adds** a `Seeded ~= nil and == false` cancel gate that wasn't there before. That is fine, but it means if flowers were genuinely unpickable pre-fix, the cause was **not** the validator — look elsewhere (node tagging, `Available` attribute, or the remote wiring hardened in 1.1).
- **Action:** Correct the root-cause narrative in the docs, and treat "wild flower/mushroom pickable" as **unverified** until the harvest Studio gate actually picks one.

**C. PeaWheelController — doc says "already clean, no changes required"; there is a 384-line rewrite.**
The controller was substantially rewritten to add viewport-fit scaling (`updateWheelScale`, clamp 0.55–1.20, 88% margin) and strict type annotations — a real, reasonable change for the "centered, never clips" requirement. The doc claiming "no changes" is stale.
- **Action:** Update the doc; verify centering/no-clip at min and max viewport in the Studio gate.

### 1.3 Repo / build integrity

| Item | State | Action |
| --- | --- | --- |
| `default.project.json` UTF-8 BOM | **FIXED this pass** (3 BOM bytes stripped; `Lighting`/`ClockTime:14` content change preserved) | Verify Rojo parses. |
| Whole tree uncommitted (~6.3k lines vs HEAD) | Risk of loss | Commit in logical chunks (see §2). |
| Tabs-vs-spaces reformat churn | Large portion of the ±6k diff is indentation flips (space→tab) | Run project StyLua once to normalize repo-wide, isolate in its own commit so logic diffs stay readable. |
| Dependency fork swaps: `ProfileService` → `alreadypro`, `ReplicaService` → `barenton`; ProfileService moved to new `[server-dependencies]` realm | Unverified supply-chain change to persistence | `wally install`, regen lock, persistence smoke test before trusting. |
| Tracked noise: `test_terminal_sim.js`, `mcp_req.json`, root `*.rbxl` (`build-test.rbxl`, `build_test.rbxl`, `place.rbxl`, `test_build.rbxl`), `build/*.rbxl` | Pollutes tree | `.gitignore` + `git rm --cached`. |
| `.fbx` meshes committed to git | Not LFS | Move to LFS or an asset pipeline (non-blocking for Phase 3). |
| `.agents/` trackers contradict each other | Orchestrator says "UI overhaul, 0% done, iter 1/32"; Sentinel says "companions"; TODO/PHASE3 say "Phase 3 fixes done" | Pick TODO+PHASE3 as source of truth; archive/delete the stale orchestrator+sentinel state so it stops misleading. |

---

## 2. Game plan to finalize Phase 3

Three workstreams. A and B are desk work (doable now, no Studio). C is the actual gate.

### Workstream A — Reconcile documentation to code truth
- [ ] A1. Rewrite the CompanionManager section of `PHASE3_ACCEPTANCE_STATUS.md` + `TODO.md` to describe the real load chain (or, preferred, change the code per §1.2-A, then document that).
- [ ] A2. Correct the HarvestValidator root-cause narrative (§1.2-B); mark flower/mushroom pickability as unverified-pending-Studio.
- [ ] A3. Update the PeaWheel entry from "no changes" to the real viewport-fit rewrite (§1.2-C).
- [ ] A4. Collapse the `.agents/` trackers to a single source of truth; archive the stale orchestrator/sentinel boards.

### Workstream B — Make the tree committable & buildable
- [x] B1. Strip BOM from `default.project.json`. **(done this pass)**
- [ ] B2. Fix CompanionManager recursive `PrimaryPart` lookup (restore `,true`) — low-risk, prevents silent cube fallback. *(Recommend doing even if keeping InsertService primary.)*
- [ ] B3. `.gitignore` build artifacts (`*.rbxl`, `build/`, `*.rbxlx`) + `git rm --cached` the tracked ones; remove `test_terminal_sim.js`, `mcp_req.json`.
- [ ] B4. `wally install`; confirm `ProfileService`/`ReplicaService` forks resolve; regen `wally.lock`.
- [ ] B5. `rojo build default.project.json -o build/verify.rbxl` — must pass with BOM removed.
- [ ] B6. Run project-pinned StyLua as a **single dedicated "format" commit** to kill the repo-wide drift, keeping logic commits clean.
- [ ] B7. Commit in logical chunks: (1) doc reconciliation, (2) code fixes, (3) hygiene/gitignore, (4) formatting. Keep marketing/social scripts out of the Phase 3 commits.

### Workstream C — Runtime Studio gates (the real acceptance blocker)
Run in one Studio session (MCP `58741` + Rojo `34872` listening). From `PHASE3_ACCEPTANCE_STATUS.md`, still-open gates:
- [ ] C1. Companion spawns with the `zundapalupdate4` mesh (NOT the placeholder cube) on character spawn.
- [ ] C2. VN welcome fires once after respawn; does not re-fire on subsequent respawns.
- [ ] C3. Wild flower/mushroom nodes are pickable end-to-end.
- [ ] C4. Cooking notes travel client→server; quality is server-derived; missed/skipped notes are counted by the server sweep.
- [ ] C5. PeaWheel centered and all 8 slices fully visible at min and max viewport (test the 0.55 and 1.20 scale clamps).
- [ ] C6. Multi-player Cook/Serve loop — no cross-player guest/session access.
- [ ] C7. Two-player full Harvest→Cook→Serve→Reward loop — cross-player ownership rejection holds.
- [ ] C8. Production rejoin with DataStore API enabled (complements the passing ProfileService mock probe).
- [ ] C9. Zundarooms catch/death/timeout/re-entry award no escape; rejoin persists escape/discovery.

### Definition of done (Phase 3)
1. Docs match code (Workstream A). 2. Tree builds clean, deps resolve, no BOM, no artifact noise, committed (Workstream B). 3. Gates C1–C5 pass single-player; C6–C9 pass for concurrency/persistence.

---

## 3. Priority order
1. **B2 + C1** (companion cube risk is the most likely live regression).
2. **A1–A3** (stop the docs from asserting things the code doesn't do).
3. **B3–B7** (committable/buildable).
4. **C2–C9** (remaining runtime acceptance).
