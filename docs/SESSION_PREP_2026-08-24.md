# Session Prep — 2026-08-24 (Polish + Gameplay Expansion)

Baseline verified before this session. All gates green, Rojo serve live.

## Verified baseline (from disk, this session)
- Repo: `G:\Zundamons-Kitchen-V2` (github.com/fromage3900/Zundamons-Kitchen-V2, private)
- Branch: `main` — now in sync with `origin/main` (9 commits were un-pushed; pushed this session, verified 0/0 ahead/behind)
- Working tree: clean
- Gates: StyLua PASS · Selene 0 errors / 357 pre-existing warnings · `rojo build` PASS → `build/ZundamonsKitchen.rbxl`
- Rojo serve: **running on port 34872** (started this session; killed the stale sourcemap watchers that were not serving)
- Rojo Studio plugin present: `RojoManagedPlugin.rbxm` (Aug 12) in `%LOCALAPPDATA%\Roblox\Plugins\`

## The friend's PC / "old version" — resolved
The repo/git side is fixed (pushed). The friend's PC shows old content because the
place has NOT been republished to Roblox. Rojo only syncs disk↔Studio while editing;
it never publishes. The remaining step is a manual Studio action on your end:
1. Open the V2 place in Roblox Studio (confirm place name is the V2 game).
2. Plugins → Rojo → Connect → `localhost:34872` (server is already listening).
3. Let Rojo sync, then **File → Publish to Roblox** (or Publish As for the live place).
4. Have your friend rejoin/re-press Play — they'll get the published build.

## Session focus — two tracks (pick one to run first)

### Track 1 — POLISH (highest felt-impact-per-effort, per PHASE4_PLAN)
Ordered from the plan's "Suggested execution order":
1. **A1+A2 Audio/reward stingers** — SoundConfig/SoundService currently point ~26 letters at
   1-2 placeholder IDs. Map distinct per-action samples (hover/confirm/open/reward). User is
   supplying custom click SFX — drop in when ready.
2. **B1 Guests visibly want service** — patience ring (green→red), idle bounce/sway, emote
   bubble with desired dish. `GuestManager` already sets patience + a BillboardGui — enrich,
   don't rebuild. (Patience ring was listed as next-session option #4 in SESSION_HANDOFF.)
3. **A3 Visual juice** — number pop-ups, ChefPill scale-punch on XP, particle burst on level-up.
   Reuse `UIHelper.spawnSparkles` + `FloatingRating`.
4. **C1 Tune Endless/Daily end-to-end** — verify waves, daily reset+reward are actually fun
   before adding more. ChallengeModeUI is Phase-4 surface but NOT playtest-verified yet
   (start → wave → abandon/complete → claim).

### Track 2 — GAMEPLAY EXPANSION (from PHASE4_GAMEPLAY_DIRECTION, "Infinity Nikki x Uma Musume")
Highest-leverage gap: **no per-companion bond/affinity system**. All additive, no new art:
1. **Wire companion bond XP** — new `data.companion_bond[compType]` table (no schema migration;
   PlayerDataService has an explicit allowlist pattern). +2 XP per serve w/ active companion,
   +5 per `companion_chat`. This makes the currently-dead `companion_chats`/`companion_affection`
   counters do something.
2. **Re-key `getCompanionDialogue`** from player level → per-companion bond level
   (VNDialogueData.lua tiers `level1_10/11_20/21_50` already exist structurally).
3. **Serve-time companion reaction line** — reuse the `GUEST_BY_TYPE` lookup-fallback template
   (GuestManager) applied to companions.
4. **Bias guest spawn weighting by biome** — extend GuestManager's weighted selection with a
   biome param (Forest → more wildlife, ZundaMarket → market-goers). Zero new dialogue.
5. Defer: Wardrobe/outfit equip (needs real assets + an equip pipeline; flagged as the
   natural "next tier" — don't duplicate).

## Rules to respect this session (from AGENTS.md)
- Keep `$ignoreUnknownInstances: true` under Workspace in default.project.json — never remove.
- Client UI via `ClientGuiBootstrap`; top-level ScreenGuis `ResetOnSpawn=false`; modal panels
  start `Visible=false`.
- All 3 gates before commit; never `--no-verify`; no scratch `print()` in commits.
- One concern per commit; **never `git add -A`** in this mixed workspace (owner assets in
  `crucialassets/`, root `.blend`/`.fbx`). Stage explicit paths.
- Server stability: Matter systems in pcall; no `task.wait` in event handlers (use `task.delay`);
  route data writes through `PlayerDataService.mutate`; clamps on guest PayAmount ≤500 / BonusGold ≤200.
- Challenge scoring: cooking (`onCookComplete`) never increments guests served; style points
  granted once via `syncPlayerWardrobe`.
- Log playtest findings to `docs/PLAYTEST_NOTES.md` (raw log bottom, issues table top).

## Session opening checklist
1. Open V2 place in Studio, confirm name, connect Rojo to 34872, sync.
2. Save Studio place before stopping Rojo / switching branches.
3. Smoke loop: harvest → collect → cook → serve → reward → respawn → rejoin.
4. Check Studio Output for bootstrap errors; watch the pcall-wrapped Matter heartbeat.
5. Commit per verified batch; push to main (CI runs gates + uploads rojo-build artifact).
