# Zundamon Kitchen UI/UX Overhaul Plan

## Product direction

Create a calm, instantly readable cozy-game interface that combines Infinity Nikki-style softness and emotional presentation with the website's Zunda-OS interaction clarity. The Roblox HUD should borrow the website's pea palette, clear active/inactive states, compact taskbar logic, and consistent window hierarchy without copying its literal Windows 95 chrome.

The current production HUD remains the rollback baseline. Implement the overhaul on `codex/expanded-gameplay-experiments`, behind `UIConfig.UseHudV2`, and cherry-pick only after runtime acceptance.

## Design token bridge

Map the Gemini website schema into `UIConfig`, then require every V2 component to consume those tokens:

| Website token | Roblox token | Intended use |
| --- | --- | --- |
| `--zunda-dark #2e7d32` | `ZundaDark` | Primary text, selected states, strong outlines |
| `--zunda-primary #4caf50` | `ZundaPrimary` | Confirm actions and progress |
| `--zunda-light #8bc34a` | `Sprout` | Highlights and positive feedback |
| `--zunda-bg #e8f5e9` | `MintCanvas` | Light panel surfaces |
| `--zunda-accent #c8e6c9` | `PeaAccent` | Resting buttons and secondary cards |
| `--zunda-pastel #f1f8e9` | `MochiCream` | Content backgrounds |
| website light/dark bevels | `SurfaceHighlight` / `SurfaceShadow` | Subtle two-tone depth, not heavy retro borders |
| website taskbar | `ActionDock` | Bottom-right/center action access |
| website start menu | `PeaWheel` | Contextual radial menu |

Typography hierarchy:

- Fredoka One: logo moments, companion names, major celebrations only.
- Gotham Semibold: headings, buttons, counters, navigation.
- Gotham: dialogue, descriptions, quest copy, tooltips.
- Roboto Mono: developer/admin information only; never ordinary player UI.
- Minimum body text 16 px desktop and 18 px touch; avoid `TextScaled` on paragraphs.

## Target information architecture

### Persistent HUD

- Top-left: one Chef Journey capsule containing tier, level, XP, gold, and a small active-companion portrait. Remove the duplicated level/progress badges currently occupying the same region.
- Top-center: contextual objective ribbon. Show the active tutorial/quest step only; collapse to a pea icon when no urgent objective exists.
- Top-right: compact circular minimap with time/weather integrated into its footer. Daily quest becomes a small badge on the objective ribbon instead of a separate large panel.
- Bottom-center: Roblox tool hotbar remains unobstructed.
- Bottom-right: three primary controls only—Pouch, Pea Wheel, and Context/Interact. Settings and secondary panels move into the wheel.
- Center: reserve for interaction prompts, cooking/fishing gameplay, and short reward feedback. Never open permanent panels here automatically.

### Modal ownership

Only one large modal may be open at once. Introduce `UIRouter` as the client authority for `open`, `close`, `toggle`, focus, Escape/back behavior, and modal priority. Existing pouch, crafting, materials, quests, compendium, shop, settings, and companion panels register adapters with the router; they do not inspect each other's GUI trees.

## Pea Wheel radial menu

The Pea Wheel replaces the seven-icon action strip while preserving keyboard shortcuts.

Initial eight slices:

1. `🎒 Pouch`
2. `🍳 Cook`
3. `📜 Quests`
4. `📖 Collection`
5. `🧺 Materials`
6. `🗺️ Map`
7. `🌸 Companions`
8. `⚙ Settings`

Interaction rules:

- Desktop: tap `Tab` to toggle, or hold `Tab`, point, and release to select.
- Gamepad: hold left bumper, select with thumbstick, release to confirm; B cancels.
- Touch: tap a 56 px pea button, then tap a minimum 64 px slice; tap outside to close.
- Center hub shows `🫛`, current selection name, and its bound key.
- Selected slice grows slightly, brightens, and shows one short description. No particle burst while merely navigating.
- Disabled/unavailable actions remain visible with a reason such as “Meet the Chef Master first.”
- Pie actions dispatch through a canonical `UIActionRegistry`; the wheel never directly searches unrelated GUI descendants.

## Component architecture

Add these client-owned modules:

- `UIActionRegistry`: canonical action ID, label, icon, keyboard/gamepad/touch binding, availability, and callback adapter.
- `UIRouter`: modal exclusivity, focus stack, Escape/back, respawn restoration, and input capture.
- `HudV2Controller`: consumes only replicated player-state projections and contextual objective state.
- `PeaWheelController`: input state machine and action dispatch.
- `components/`: `ChefJourneyCapsule`, `ObjectiveRibbon`, `MinimapCard`, `ActionDock`, `PeaWheel`, `CozyModalShell`, `ToastStack`, and `Tooltip`.

React is appropriate for these new declarative surfaces. Gameplay state remains outside UI React trees; controllers subscribe to projections and pass read-only props. Existing panels can remain imperative behind adapters during migration.

## Phased implementation

### Phase UI-0 — Inventory and contracts

Dependencies: none.

- Catalogue every visible HUD element, owning script, remote/projection, shortcut, and duplicate.
- Resolve shortcut conflicts (`Inventory (I)` versus the current backquote binding, `Materials (M)` versus Map `M`, and the shop comment/key mismatch).
- Define `UIActionRegistry`, `UIRouter` interface, V2 feature flag, safe-area and device-class helpers.

Exit: one authoritative action/binding table; screenshots at 1920×1080, 1366×768, mobile landscape, and gamepad prompt mode.

Commit: `docs(ui): inventory hud ownership and input contracts`.

### Phase UI-1 — Tokens and reusable shell

Dependencies: UI-0.

- Extend `UIConfig` with the website token bridge, semantic text/surface states, spacing, safe areas, focus rings, reduced-motion values, and touch sizes.
- Build Storybook-style Roblox stories for the core components.
- Update `UIFrills` to decorate only opted-in V2 shells; it must never become a second layout owner.

Exit: contrast/readability review, consistent typography, and no component hardcodes outside approved exceptions.

Rollback: disable `UseHudV2`.

Commit: `feat(ui): establish zunda pea design system`.

### Phase UI-2 — Pea Wheel vertical slice

Dependencies: UI-0 and UI-1.

- Implement wheel geometry, pointer/thumbstick selection, touch mode, tooltips, cancellation, and action dispatch.
- Initially map only Pouch, Quests, Map, and Settings; retain the current dock as fallback.
- Add input tests for rapid open/close, modal already open, respawn, chat focus, cooking input, and gamepad disconnect.

Exit: all four actions work on mouse, keyboard, touch, and gamepad with one dispatch each and no leaked connections.

Commit: `feat(ui): add accessible pea wheel navigation`.

### Phase UI-3 — HUD consolidation

Dependencies: UI-2 and canonical player-state projection.

- Replace duplicate level badges with `ChefJourneyCapsule`.
- Combine daily quest/tutorial/active quest into `ObjectiveRibbon` with priority rules.
- Restyle and resize minimap; update at sensible frequencies instead of every Heartbeat where possible.
- Replace the seven-button strip with ActionDock + Pea Wheel after parity is proven.
- Route reward popups into a bounded toast/float lane so they never cover VN, fishing, or cooking.

Exit: harvest-cook-serve loop is readable without opening a panel; no overlapping safe zones at target resolutions.

Commit: `feat(ui): consolidate production hud hierarchy`.

### Phase UI-4 — Modal migration and cozy polish

Dependencies: UI-1 and `UIRouter`.

- Wrap Pouch, Crafting, Quests, Materials, Compendium, Companion Boutique, and Settings in `CozyModalShell` one at a time.
- Add clear titles, one primary action, consistent close/back affordance, empty/loading/error states, and contextual help.
- Preserve the working VN composition but add optional model portrait slots, speaker-specific accents, and clear advance/skip cues.
- Use motion for hierarchy: 120–250 ms fades/slides, restrained Back easing for celebrations, and reduced-motion equivalents.

Exit: one-modal rule, Escape/B/back consistency, respawn safety, and no automatic modal at join.

Commit per panel; never migrate all panels in one commit.

### Phase UI-5 — Production gates

Dependencies: UI-2 through UI-4.

- Run StyLua, Selene, Rojo build, path/remote validation, and UI stories independently.
- Studio smoke at four viewport/device modes.
- Verify fresh join, respawn, rejoin, ten rapid wheel toggles, every wheel action, VN during HUD activity, cooking/fishing input isolation, and modal exclusivity.
- Compare before/after screenshots and measure time-to-open for Pouch, Quest, Map, and Companion panels.

Exit: no core-loop regression, no duplicated listeners/rewards, no inaccessible text, and owner approval of screenshots. Enable V2 only in a dedicated release commit.

## UX acceptance criteria

- A first-time player can identify level, gold, current objective, map, pouch, and interaction affordance within five seconds.
- A returning player reaches any secondary panel in two actions or one remembered shortcut.
- No more than three persistent HUD clusters compete for attention.
- No modal opens automatically at spawn.
- Keyboard, touch, and gamepad expose equivalent actions and cancellation.
- Icons always include text in expanded states/tooltips; color is never the sole status signal.
- Body copy remains readable at 1366×768 and mobile landscape without `TextScaled` distortion.
- The interface retains emotional softness—pea greens, mochi cream, blush accents, gentle motion—while active/pressed/focused states remain unmistakable.

## Explicit non-goals

- Do not rewrite gameplay services, remotes, persistence, or ECS for this UI project.
- Do not copy the website's terminal/CRT styling into ordinary gameplay HUD.
- Do not remove existing panels until their routed replacement passes parity.
- Do not enable monetization as part of visual polish.
- Do not merge the experimental branch wholesale into production.
