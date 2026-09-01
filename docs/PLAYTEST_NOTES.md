# Playtest Notes — Live Intake

This is the single source of truth for gameplay feedback. Append raw notes at the bottom; Claude triages them into the table and works from it directly (no `.agents/` relay).

## Active issues

| # | System | Report | Status | Root-cause / Fix |
| --- | --- | --- | --- | --- |
| 1 | Companion | Companion still not zundapal (cube) | ✅ Fixed & verified live | **All configured sources were dead:** config asset IDs (`84382…` etc.) load empty via InsertService, and `ServerStorage…Prefabs.zundapal`/`__MCPGeneratedModels` are MeshParts with **blank MeshId** = literal boxes. The only real mesh is the one placed in the level: `Workspace.Meshes/zundapalupdate4`, a lone MeshPart, MeshId `rbxassetid://124750913039753` — missed by every `FindFirstChild`. Fixed: loader now (1) finds the level mesh first by name **and** MeshId, (2) wraps a lone MeshPart into a Model, (3) **rejects any empty-MeshId source** so a cube is structurally impossible (errors loudly instead). **Verified in Play:** companion spawns with `MeshId=…124750913039753`. |
| 2 | UI / PeaWheel | Pea Wheel invisible / toggle doesn't activate on click | ✅ Fixed & verified live (screenshot) | Three separate bugs: (a) **module crashed on load** — `UserInputService.ReducedMotionEnabled` doesn't exist (it's on `GuiService`) → fixed; (b) **opened behind overlays** — wheel was DisplayOrder 80 but `UIPolishGui`/`TutorialGui` are 999, so it opened underneath and looked like the click did nothing → raised to **1000**; (c) **tofu hub icon** — `🫛` (Unicode 14) unsupported → swapped to `🌱`. **Verified in Play (screen capture):** wheel renders on top, all 8 icons + hub render, opens on click. |
| 3 | UI / HUD | HUD doesn't have proper keybinds | ✅ Fixed & verified live (2026-08-25, `tools/playtest-echo/runs/verify-ui-actions-20260825.json`) — all 13 actions have callbacks registered, key→action reverse map consistent (M/L/K/C/I/N/J/Tab bound; companions/materials/wardrobe/collection/settings button-only by design) | Real cause: **no central listener dispatched panel hotkeys at all** — keys C/M/J/I were dead; only Tab/Q, F1, a stray P, and HUD clicks worked. Fixed: added ONE keyboard dispatcher in `UIActionRegistry` (single source of truth) that turns any bound key → `dispatch()`; freed F1 (settings via wheel/HUD button) so it no longer double-fires with the Keybinds panel; wired the dead **Cook** slice (registered its callback in `CraftingScript`, bound to K). |
| 4 | UI / Settings | Settings panel doesn't close | ✅ Fixed & verified live (2026-08-25, same evidence file) — settings dispatch toggles open→close cleanly (Enabled false→true→false), zero legacy/vignette overlay GUIs alive in PlayerGui | Root cause was the same cleanup crash — `Size is not a valid member of UICorner` at `000_LegacyOverlayCleanup:61` aborted the whole legacy-overlay cleanup, leaving old duplicate panels alive. Fixed with an `IsA("Frame")` guard so cleanup completes and legacy shells are removed. (Settings' own close button was already correctly wired.) |
| 5 | Performance | Extreme lag | ✅ Fixed & verified live | Three per-frame offenders: (a) `SkyOverlay:60` assigned `TileOffset` (not a real ImageLabel property) → **threw every frame** (log flood + frame cost); (b) `WireframeOutline` scanned all **4155 workspace descendants every frame**; (c) `ReverbHandler` used a non-existent `Enum.AmbientReverbType` (dead on load). Fixed all three: removed the invalid TileOffset writes, cached the wireframe adornment set + ~15 Hz throttle, corrected reverb enum + cached zones + ~10 Hz throttle. **Verified in Play:** SkyOverlay/Reverb errors gone; reverb enum applies cleanly. |

| 6 | Companion | Zundapal too big; needs human size | ✅ Fixed & verified live | Source mesh is ~50 studs tall. `buildCompanion` now scales the model to ~5.2 studs (human) via `Model:ScaleTo`. **Verified in Play:** extents 4.9 × 5.2 × 4.0. |
| 7 | Companion | Zundapal should use his baked animations | ⛔ Blocked (needs asset) | The level mesh is a **static single MeshPart — 0 bones, no Animator, and no zunda Animation assets exist in the game.** Baked/skeletal animation needs either a rigged (skinned) mesh with bones + an AnimationController/Animator + Animation asset IDs, or the source FBX re-imported as a rig. Need the animated/rigged asset or animation IDs from the user. |

### Newly discovered from live console (not in your notes, but real)

| System | Error | Impact |
| --- | --- | --- |
| VN | `VNController:200: attempt to index nil with 'zundamon'` | Welcome dialogue errors mid-show |
| Endless loop | `CookCompleted is not a valid member of CookingService` (`EndlessLoopWiring:115`) | Endless/challenge wiring broken |
| FX | `FXController:11: Module code did not return exactly one value` | FXController fails to load |
| Guests | `GuestManager:390 require invalid argument` → `Mesh missing Torso` → procedural capsule | Guests spawn as capsules, not characters |
| Data | `UserId is not a valid member of Model` (`PlayerDataService:123` via `DailyController:28`) | Daily data passes character instead of player |
| GUIs | Infinite yield on `Shared:WaitForChild("ConfigurationFiles")` — `PromoCodeGui`, `WelcomeStarterPackGui`, `OutfitWardrobeGui` | Those panels never load (wrong path) |
| Cleanup | `Size is not a valid member of UICorner` (`000_LegacyOverlayCleanup:61`) | Legacy-overlay cleanup aborts (ties to #4) |

Legend: 🔍 investigating · 🔧 fixing · ✅ fixed (code) · 🎮 needs Studio verify · ❌ can't repro

---

## Raw note log

### 2026-07-23 (batch 1)
- companion still not zundapal
- Peawheel still invisible
- HUD doesn't have proper keybinds
- settings panel doesn't close
- extreme lag

### 2026-08-12 (stability audit batch — systems triage, from code audit)
- DailyChallengeService.updateProgress could nil-index `daily_challenge_claimed` (precedence bug) → fixed; claimed flag now set inside settlement mutation
- ChallengeModeService.selectChallengeRecipes could `math.random(1, 0)` on empty tier pool → guarded; wave 15+ would have crashed
- Challenge mode double-counted: cooking incremented guestsServed (wave completable without serving) → split `onCookComplete` vs `onGuestServed`
- Style points double-credited in challenge mode (ChallengeModeService + syncPlayerWardrobe) → wardobe sync is the single grant path, routed through PlayerDataService.mutate
- EndlessLoopWiring listened for `IngredientGathered`/`GoldEarned` remotes that do not exist → dead listener removed
- EndlessLoopWiring duplicated daily init (double-grant window) → DailyChallengeService.PlayerAdded is sole owner
- ServingService trusted client-mutable guest attributes: PayAmount/BonusGold clamped (≤500/≤200) at serve
- GuestManager capped guests globally, starving late joiners → cap is per player now
- Mineable respawn used `task.wait` inside an attribute-changed handler (blocked signal dispatch; destroyed-node error) → `task.delay` + pcall
- Matter loop had no error isolation → systems wrapped in pcall in ServerMain; one failing system can no longer kill the heartbeat

### 2026-08-24 (visual juice batch — A3)
- Added ChefPill scale-punch on every XP gain (back-ease size bump + sparkles), a second + third radial sparkle burst behind the level-up banner (gold + pink fan) for a fuller "ding", and a back-ease scale pop-in on all floating reward number pop-ups (serve gold/XP, bonus, item).
- All client-only (HudScript.client.lua); reuses existing `UIHelper.spawnSparkles` + reward events. Serve/reward numbers were already floating via `RewardCore.settle` → `PopupEvent`; these changes make them snap instead of softly fading. Verify in Play: gain XP (pill punches), level up (triple burst + punch), serve a guest (numbers pop in).

## Echo Run 2026-08-25 (live playtest, ~660s session)

### Issues

| # | System | Finding | Severity | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Guests | **12 guests spawned, ALL removed by timeout — zero serves.** No cook/harvest events in log either; player never completed the serve loop. Guest patience (~200-250s) vs player behavior needs a look, or tutorial doesn't teach serving fast enough. | HIGH | 21 GuestManager events, all Spawned/removed(timeout) |
| 2 | PeaWheelBootstrap | Callback registration runs **6 times** (9 callbacks x 6 = 54 duplicate registrations). Works but is re-entry spam — guard against repeat bootstrap. | MEDIUM | +3340.7 to +3342.9s, 54 registration prints |
| 3 | Companion anims | `rbxassetid://2510798496` fails to load (x6) — dead animation ID wired somewhere in companion/HUD. Matches PHASE4 D2 known gap (no real animation IDs). | MEDIUM | 6 ERR lines +2350-2358s |
| 4 | VN dialogue | Zundamon idle VN fires on every guest timeout ("The stars are beautiful tonight...") — flavor line plays when panel already open, queues and stacks. 67 VN.show calls total for one short session. | LOW | 6 'Panel already open, queuing' |
| 5 | Data | ProfileService/DataStore writes unavailable in Studio (expected, API access off). Quest `quest_first_100_gold` DID complete (+25g), so progression works locally. | INFO | +2873/+3334 ERRs |

### What worked
- Server boot clean: all services ready, Matter ECS initialized, HarvestValidator active
- Tutorial flowed steps 1-9 automatically after first spawn
- First quest completed (+25 gold) — reward pipeline functional
- Mesh guests spawning correctly (animal-deer/caterpillar/elephant — no more capsule fallback)
- Rojo sync verified twice ("ROJO SYNC OK")

Raw trace: [`tools/playtest-echo/../playtest-log-full.json`](../tools/playtest-log-full.json)

## Echo Run 2026-08-25 (56s)

### Issues

| Script | Error count | Unique error messages |
| --- | --- | --- |
| <code>ZundaHUD</code> | 6 | <code>Scale is not a valid member of TextLabel "Players.fromage3900.PlayerGui.ZundaHUD.PopupRoot.TextLabel"</code> |
| <code>CompanionManager</code> | 2 | <code>Argument 3 missing or nil</code> |
| <code>DailyReturnToast</code> | 1 | <code>Players.fromage3900.PlayerScripts.DailyReturnToast:102: attempt to index nil with 'Text'</code> |
| <code>GatheringNodes</code> | 1 | <code>PrimaryPart is not a valid member of Folder "Workspace.GameplayLoopArea.GatheringNodes.ZundaBerry"</code> |
| <code>HUD</code> | 1 | <code>Unable to assign property Font. EnumItem, number, or string expected, got Font</code> |

### Regression vs previous run

- New error signatures not in previous run:
  - <code>PrimaryPart is not a valid member of Folder "Workspace.GameplayLoopArea.GatheringNodes.ZundaBerry"</code>
  - <code>Argument 3 missing or nil</code>
  - <code>Scale is not a valid member of TextLabel "Players.fromage3900.PlayerGui.ZundaHUD.PopupRoot.TextLabel"</code>
  - <code>Unable to assign property Font. EnumItem, number, or string expected, got Font</code>
  - <code>Players.fromage3900.PlayerScripts.DailyReturnToast:102: attempt to index nil with 'Text'</code>

Warnings captured: 0 · State samples: 3

Raw trace: [`tools/playtest-echo/runs/live-serve-20260825-1.json`](../tools/playtest-echo/runs/live-serve-20260825-1.json)

<!-- playtest-echo-session:live-serve-20260825-1 -->

### 2026-08-25 (C1 verification — Endless + Daily, live Studio Play)

First real end-to-end run of Challenge Mode and Daily Challenges. Both were
**non-functional before this session** — not "untested", but structurally unable
to run. Root cause and fixes below; all verified live in Play, not by audit.

**Blocker 1 — UTF-8 BOM killed the whole Endless/Daily surface. ✅ Fixed & verified.**
`src/server/Services/DailyChallengeService.lua` began with a UTF-8 BOM (`EF BB BF`).
Luau's parser rejects it, so the module never compiled. `EndlessLoopWiring` requires
it at the top, so the wiring script died before line 71 — where all five client-facing
RemoteFunctions are created. Cascade: no `ChallengeStart` / `ChallengeAbandon` /
`ChallengeCompleteWave` / `DailyClaimReward` / `DailyClaimWeekly` → `ChallengeModeUI:20`
infinite-yields at module load → Challenge Mode could never be started from the client.
**All three gates passed the whole time**: StyLua and Selene tolerate a BOM, and
`rojo build` embeds source without compiling Luau. Repo-wide sweep found exactly one
affected file. After the fix, all 5 RemoteFunctions are created (verified server-side).

**Blocker 2 — `PlayerAdded` race meant daily state never initialised. ✅ Fixed & verified.**
`DailyChallengeService` connected `Players.PlayerAdded` with no backfill for players
already present. The module is required lazily by `EndlessLoopWiring`, so on a fast join
— always in Studio Play, and for the first joiner on a live server — the player is already
in `Players` when the connection is made and the event never fires. Result: `daily_challenges`,
`daily_challenge_progress`, `daily_streak` all stayed `nil` permanently. Fixed by extracting
`initPlayerDaily` and backfilling over `Players:GetPlayers()`, with a `player.Parent` guard
so a player who leaves during the 3s delay isn't initialised.

**Verified working after the fixes (live):**
- Challenge: `startSession` → waves 1-5, score 100/300/600/1000, tier Bronze→Silver at
  wave 4 → `onCookComplete`/`onGuestServed` scoring → `abandonSession` → best score/wave persist.
- Challenge lock is correct, not a bug: gated behind 10 guests served OR tier 2, and fires
  a `locked` status to the client.
- Daily: 3 challenges generated with well-formed `metric`/`goal`/`reward{gold,style,xp}`;
  claim-before-complete refused; claim after completion paid exactly +120 gold; double-claim
  refused with gold unchanged; claimed flag set.

**Open — scoring double-count (NOT fixed, needs a design call).**
One perfect dish is scored twice. `onCookComplete(quality)` fires on cook and
`onGuestServed(quality)` fires on serve, and **both** add `perfect_cook` (50) and
increment `perfectCooks`. Measured live: one cook + one serve → `perfectCooks=2`.
Two consequences: (a) a perfect serve never awards `guest_served` (20) because the
branch is if/elseif, so `onGuestServed` is really scoring cook quality, not serve
quality; (b) `DailyChallengeService.updateProgress(player, "perfect", 1)` is called in
BOTH the cook and serve handlers in `EndlessLoopWiring`, so a "get N perfect dishes"
daily completes at half its intended count. This is the same pattern already fixed twice
in this file (guestsServed double-count, style-point double-credit) — the lesson wasn't
generalised to `perfectCooks`/score.

**Open — cosmetic: mojibake in `DailyChallengeService.lua`.**
Comment separators are double-encoded (`U+00E2 U+201D U+20AC` where `─` U+2500 belongs) —
64 occurrences, comments only. Same root event as the BOM: the file was saved once through
a cp1252 round-trip.

**Environment note — stale `rojo serve` blocks the current build.**
`CookingService` now fails to load because `ReplicatedStorage.Rhythm.RhythmEngine` /
`RhythmScoreEvaluator` are absent from the DataModel. They exist on disk
(`src/shared/Rhythm/`) and ARE mapped in `default.project.json:60`, but the running
`rojo serve` was started before that mapping was added and Rojo does not reload its
project file. Until the serve is restarted (and the Studio Rojo plugin reconnected),
`EndlessLoopWiring` dies at its `CookingService` require and the five RemoteFunctions
disappear again — i.e. Blocker 1's symptom returns from an unrelated cause.
