# Playtest Notes — Live Intake

This is the single source of truth for gameplay feedback. Append raw notes at the bottom; Claude triages them into the table and works from it directly (no `.agents/` relay).

## Active issues

| # | System | Report | Status | Root-cause / Fix |
| --- | --- | --- | --- | --- |
| 1 | Companion | Companion still not zundapal (cube) | ✅ Fixed & verified live | **All configured sources were dead:** config asset IDs (`84382…` etc.) load empty via InsertService, and `ServerStorage…Prefabs.zundapal`/`__MCPGeneratedModels` are MeshParts with **blank MeshId** = literal boxes. The only real mesh is the one placed in the level: `Workspace.Meshes/zundapalupdate4`, a lone MeshPart, MeshId `rbxassetid://124750913039753` — missed by every `FindFirstChild`. Fixed: loader now (1) finds the level mesh first by name **and** MeshId, (2) wraps a lone MeshPart into a Model, (3) **rejects any empty-MeshId source** so a cube is structurally impossible (errors loudly instead). **Verified in Play:** companion spawns with `MeshId=…124750913039753`. |
| 2 | UI / PeaWheel | Pea Wheel invisible / toggle doesn't activate on click | ✅ Fixed & verified live (screenshot) | Three separate bugs: (a) **module crashed on load** — `UserInputService.ReducedMotionEnabled` doesn't exist (it's on `GuiService`) → fixed; (b) **opened behind overlays** — wheel was DisplayOrder 80 but `UIPolishGui`/`TutorialGui` are 999, so it opened underneath and looked like the click did nothing → raised to **1000**; (c) **tofu hub icon** — `🫛` (Unicode 14) unsupported → swapped to `🌱`. **Verified in Play (screen capture):** wheel renders on top, all 8 icons + hub render, opens on click. |
| 3 | UI / HUD | HUD doesn't have proper keybinds | 🔧 Fixed (code) → needs Rojo resync + Studio verify | Real cause: **no central listener dispatched panel hotkeys at all** — keys C/M/J/I were dead; only Tab/Q, F1, a stray P, and HUD clicks worked. Fixed: added ONE keyboard dispatcher in `UIActionRegistry` (single source of truth) that turns any bound key → `dispatch()`; freed F1 (settings via wheel/HUD button) so it no longer double-fires with the Keybinds panel; wired the dead **Cook** slice (registered its callback in `CraftingScript`, bound to K). |
| 4 | UI / Settings | Settings panel doesn't close | 🔧 Fixed (code) → verify | Root cause was the same cleanup crash — `Size is not a valid member of UICorner` at `000_LegacyOverlayCleanup:61` aborted the whole legacy-overlay cleanup, leaving old duplicate panels alive. Fixed with an `IsA("Frame")` guard so cleanup completes and legacy shells are removed. (Settings' own close button was already correctly wired.) |
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
