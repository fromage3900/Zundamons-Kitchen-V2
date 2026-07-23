# FX & UI Layering — Audit + Infinity Nikki Polish Plan

Date: 2026-07-23 · Companion doc to [PHASE3_HANDOFF.md](PHASE3_HANDOFF.md)

## The bug class ("old UI interfering / panels invisible or not togglable")

Panels were never broken — they were opening **underneath full-screen overlays**:

| Offender | Was | Problem |
| --- | --- | --- |
| `TutorialGui` | DisplayOrder **999** + full-screen 50%-black dim across all 7 onboarding steps | Every panel below 999 (Settings 200, Crafting 25, Pouch 22…) opened *under the dim* → looked invisible/dead |
| `UIPolishGui` | DisplayOrder **999** | Sparkle labels floated above every modal |
| `ZundaWhimsicalOverlay` | no explicit DisplayOrder (0) | Scene FX competing at the UI layer |
| `ZundaCelOutline` | no explicit DisplayOrder (0) | Same |

## Canonical layer ladder (applied)

```
1000  PeaWheelGui            — radial menu, always top when open
 150  TutorialGui            — onboarding; panels (200+) now open ABOVE the dim
  90  UIPolishGui            — decorative sparkles under panels/modals
 100–300  Panels & modals    — Settings 200, Toast/Fishing 100, Zundarooms 110…
  10–60   HUD                — CompanionHUD 60, KeybindsGui 30, Minimap 10
   1–15   Scene FX           — SkyOverlay 1, WhimsicalOverlay 2, CelOutline 3,
                               ChromaticAberration 15
```

Rule: **scene FX < HUD < panels < tutorial-dim < PeaWheel.** New ScreenGuis must
set an explicit DisplayOrder from this ladder (never default 0, never 999).

Files changed: `TutorialController.client.lua` (999→150),
`UIPolishScript.client.lua` (999→90), `WhimsicalOverlay.lua` (→2 + IgnoreGuiInset),
`CelOutline.lua` (→3 + IgnoreGuiInset).

## Infinity Nikki polish backlog (next pass, not blocking)

The FX stack (gradient wash, lens flare, mist, magic circle, cel ink, aberration)
already carries the dreamy Nikki look. Remaining polish, in order of impact:

1. **Palette tokens** — several FX hardcode colors; route them through
   `UIConfig.GAME_COLORS` / AGENTS.md §7 pastels (green 160,210,150 · gold
   255,200,80 · pink 255,150,200 · mint 145,215,195) so weather/time recolors stay
   coherent.
2. **Tutorial dim softening** — swap the flat 50% black for a pastel radial
   vignette (mint→transparent) so onboarding feels cozy, not modal-gray.
3. **SkyOverlay crystal layers** — several ImageLabels have empty texture ids
   (render as faint white squares); assign real textures or remove the layers.
4. **Reduced-motion respect** — FX loops (flare pulse, mist drift, magic circle
   spin) should check `GuiService.ReducedMotionEnabled` like PeaWheel does.
5. **WaterFX fresnel loop** — per-glow `task.wait(0.016)` loops; consolidate into
   one Heartbeat-driven updater over a cached list (same pattern as the
   WireframeOutline fix).
6. **Emoji audit completion** — one tofu glyph remains in the HUD area (screenshot
   2026-07-23); sweep all UI text for unsupported emoji like the fixed 🫛.
7. **VN portrait assets** — upload zundamon emote frames, fill
   `VNPortraitConfig.speakerImages/tutorialMascot` to replace emoji portraits.
8. **Tool section modernization** — the old custom hotbar (`Custom Inventory`) is
   deprecated/destroyed; the default Roblox backpack is the functional tool bar.
   Next: a themed replacement hotbar (pastel slots, keybind chips 1–7) registered
   at HUD layer (~50), replacing the default backpack via
   `StarterGui:SetCoreGuiEnabled(Backpack, false)` only once feature-complete.
9. **Chef level pill + minimap refresh** — `ZundaHUD.ChefPill` and
   `MinimapGui.MinimapOuter` work but predate the Nikki pass: restyle with
   `UIConfig` pastels/CORNER_RADIUS/FONTS tokens, add level-up glow tween, and
   give the minimap a rounded mint frame + zone-name banner.
10. **Starter gift rewards are display-only** — `WelcomeStarterPackGui`'s claim
    button just hides the panel; no server grant exists. Wire a server-validated
    one-time grant (tickets/gold/apron) + persistence flag before monetization
    review, or label the popup as cosmetic preview.
