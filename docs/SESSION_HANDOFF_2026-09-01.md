# Session Handoff — 2026-09-01

Next session should start here. All commits below are on `main` and **pushed**.

## What happened this session

### 0. Environment repair
- **Killed 4 stale `rojo serve` processes** (§16 violation); a single fresh serve on port 34872 is running.
- **Git object corruption incident — RESOLVED.** 12 loose objects were zero-length
  (interrupted write/AV). `git fetch origin main --refetch` restored every one from
  origin (incl. committed blob `assets/sounds/ui/b.wav`, 493 KB). `git fsck` clean.
  Pre-repair `.git` backup kept at `.git.bak-corrupt/` (gitignored; delete when confident).
  **Loss:** the *staged* index blobs of the uncommitted waves were unrecoverable —
  working-tree files (the newest linted state) were used instead. Staged-vs-unstaged
  distinction was lost (mixed reset); everything re-committed from disk.

### 1. Committed the entire uncommitted backlog (6 commits, one concern each)
| Commit | What |
| --- | --- |
| `48e1d67` | feat(zundarooms): depth progression + memory fragment long-term loop |
| `79e197a` | feat(rhythm): rhythm cooking engine, beatmaps, and 122-test E2E suite |
| `9ac7f6e` | feat(content): damon dex/evolution/types, seasonal+tournament+lore, 26-companion & 154-quest expansion |
| `59fdd33` | feat(pipelines): damon texture pipeline, VOICEVOX voiceline pipeline, generated VoiceConfig |
| `029f242` | docs: playtest intake, handoff updates, echo pipeline probe + crossref audit |
| `a6ac7c7` | fix(visual): palette SSOT drift normalization, sky/postfx, HUD and endless-loop wiring polish |

Note: commit-msg hook only accepts feat/fix/docs/chore-style types — `tune` is rejected.

### 2. Challenge scoring double-count — FIXED (`86285ac`)
- `onCookComplete` is the sole owner of cook-quality score + `perfectCooks`.
- `onGuestServed` now awards `guest_served` (20) + new `perfect_serve` (25) / `great_serve` (10) bonuses; no cook-quality re-credit.
- `DailyChallengeService.updateProgress(player,"perfect",1)` is cook-owned; "N perfect dishes" dailies now complete at the intended count.
- Repaired 64 mojibake comment separators in `DailyChallengeService.lua` (cp1252 round-trip → `─`/`—`).

### 3. Verification
- Gates: `stylua --check src` ✅ · `selene --allow-warnings src` ✅ (389 warnings, 0 errors) · `rojo build` ✅
- `run_rhythm_tests.py`: **122/122 PASS** after the scoring change.
- `verify_expansion_oracle.py`: all content checks PASS; the harness **crashes at its tail on a socket timeout in the companion-AI HTTP probe** (network flake in the bridge test, unrelated to gameplay code — worth a retry/timeout fix in that script).
- Not yet verified live in Studio: scoring fix + Zundarooms loop + client-1 echo capture (see below).

## Resume steps (next session)
1. Playtest live: challenge mode scoring (one cook + one serve → `perfectCooks=1`, `guest_served` paid), Zundarooms enter → fragments → escape → memory readout.
2. Run the **client-1 echo capture** of a Zundarooms run (`tools/playtest-echo/`, role `client-1`) → `echo_to_notes.mjs` → `compare_runs.mjs`.
3. Fix `verify_expansion_oracle.py` tail-timeout (retry logic or longer socket timeout).
4. Content merge: review `scripts/ollama_output/generated_*.lua` (dedupe 2 recipe names) → oracles → gates → separate commit.
5. `git push` if any local commits remain unpushed.
