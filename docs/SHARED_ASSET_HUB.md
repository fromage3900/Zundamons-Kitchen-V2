# Shared Asset Hub — Server-Replicated Storage as Source of Truth

> How Zundamon's Kitchen treats **ReplicatedStorage** as the runtime hub for
> shared content, git as the durable hub for source control, and what both must
> contain so the long-term working state is unbreakable.

## Why this doc exists

The game has three content owners (Rojo-authored code, Studio-authored level
geometry, and Wally packages). Without a written convention, new systems pick
random homes and the place + repo drift apart. This document pins the hub
contract: **everything shared and sharable flows through ReplicatedStorage**;
everything durable flows through **git via Rojo**.

## The ReplicatedStorage hub (runtime source of truth)

| Child | Owner | Content | Sync policy |
|---|---|---|---|
| `ConfigurationFiles` | Rojo | Gameplay/UI config, loot tables, dialogue, ClientGuiBootstrap | `$path` from `src/shared/ConfigurationFiles` |
| `Shared/Config` + `Shared/Modules` | Rojo | NPC config, UI assets, architecture loader | `$path` from `src/shared/Shared/*` |
| `components` | Rojo | Matter components (cooking, fishing, companion) | `$path` from `src/shared/components` |
| `Models` | Hybrid | Reusable models; keep `$ignoreUnknownInstances: true` | `$path` from `src/shared/Models` + Studio additions |
| `Meshes` | Rojo | Repository-held meshes | `$path` from `src/shared/Meshes` |
| `RemoteEvents` / `RemoteFunctions` / `RewardEvents` / `ToolRemotes` | Rojo | Every remote as `.model.json` | `$path` from `src/shared/*` |
| `AssetRegistry` | Rojo | Asset ID single source of truth | `src/shared/AssetRegistry.lua` |
| `QuestConfig`, `DataSchema`, `Loot`, `Packages` | Rojo | Canonical modules + Wally | `$path`/`Packages` |

Clients read from this hub only. State writes flow **client → remote →
server adapter → service**; clients never decide rewards or mutate hub data.

## MaterialService as the material hub

`MaterialService` holds the persistent `MaterialVariant`s used by the Zunda
material pipeline (see [src/Plugins/README.md](../src/Plugins/README.md)).
`MaterialService` is **outside the Rojo sync tree** (`default.project.json`
maps `ReplicatedStorage`, `Workspace`, `ServerScriptService`, `StarterPlayer`,
`Lighting`, `ServerStorage` — not `MaterialService`), so Rojo never wipes it;
variants persist with the `.rbxl` automatically (level geometry in `Workspace`/`Models`
uses `$ignoreUnknownInstances` for the same reason). The canonical **values** live in
git at `src/Plugins/ZundaPalette.lua`; Studio and git must agree (edit the module,
then re-run the plugin's Register — idempotent, updates in place — to copy into the place).

### Palette Mapping & Drift Audit (2026-08-25, AAA pass)

SSOT is `src/Plugins/ZundaPalette.lua` (AGENTS.md §7). Every Color3 in
`UIConfig.lua`, `SkyConfig.lua`, `PostProcessing.lua`, and `site/style.css` was audited
against it; drift is `max(|RΔ|,|GΔ|,|BΔ|)`. Drift >10 on a palette-affiliated token was normalized;
tokens in a separate semantic domain (dark theme, wood, rarity, atmospheric sky, weather fog)
are intentionally distinct and documented as such.

**Canonical palette (SSOT hex):**

| Variant | Hex | RGB |
|---|---|---|
| ZundaGreen | `#a0d296` | 160,210,150 |
| ZundaGold | `#ffc850` | 255,200,80 |
| ZundaPink | `#ff96c8` | 255,150,200 |
| ZundaMint | `#91d7c3` | 145,215,195 |
| MochiCream | `#fff5eb` | 255,245,235 |
| EdamameDeep | `#5a8c5a` | 90,140,90 |

**UIConfig.lua drift (normalized):**

| Token | Before | After | Δ vs SSOT | Action |
|---|---|---|---|---|
| `COLORS.Primary` | 100,200,80 | **160,210,150** | 70→0 | Aligned to ZundaGreen (was legacy dark green) |
| `COLORS.Glow` (EFFECTS) | 100,200,80 | **160,210,150** | 70→0 | Aligned to ZundaGreen |
| `COLORS.MochiCream` | 241,248,233 `#f1f8e9` | **255,245,235 `#fff5eb`** | 14→0 | Unified with SSOT & `KitchenCream` |
| `COLORS.KitchenCream` | 252,248,240 | **255,245,235 `#fff5eb`** | 5→0 | Unified to MochiCream SSOT |
| `COLORS.ZundamonMint` | *missing* | **145,215,195 `#91d7c3`** | — | Added (was gap) |
| `COLORS.EdamameDeep` | *missing* | **90,140,90 `#5a8c5a`** | — | Added |

**UIConfig intentionally distinct (documented, not normalized — Δ>10 vs nearest palette but separate domain):**

| Token | Value | Nearest palette | Δ | Why distinct |
|---|---|---|---|---|
| `ZundaDark` 46,125,50 `#2e7d32` | vs EdamameDeep 90,140,90 | 44 | Web brand deep edamame for contrast/readability (bridges `site/style.css --zunda-deep`) |
| `ZundaPrimary` 76,175,80 `#4caf50` | vs ZundaGreen 160,210,150 | 84 | Web brand fresh green (bridges `--zunda-base`) |
| `Sprout` 139,195,74 `#8bc34a` | vs ZundaGreen | 76 | Web bright sprout (`--zunda-leaf`) |
| `MintCanvas` 232,245,233 `#e8f5e9` | vs ZundaMint 145,215,195 | 99 | Web canvas tint (`--zunda-light` old) — now separate from palette, see CSS |
| `PrimaryDark` 60,140,50 | vs EdamameDeep 90,140,90 | 40 | Button pressed state — intentionally darker than SSOT |
| `LeafGreen`/`PeaGreen` 143,201,143 | vs ZundaGreen | 17 | Nature tone — intentional sage variant, not brand green |
| `Rarity*`, `Wood*`, `Background` etc | — | — | Semantic tokens — not palette, never compared |

**site/style.css tokens:**

| Token | Before | After | Δ | Action |
|---|---|---|---|---|
| `--zunda-light` | `#f1f8e9` 241,248,233 | **`#fff5eb` 255,245,235** | 14→0 | Aligned to MochiCream SSOT |
| `--zunda-soft` `#a5d6a7`, `--zunda-leaf` `#8bc34a`, `--zunda-base` `#4caf50`, `--zunda-deep` `#2e7d32` | — | kept | 17–84 | Web brand greens — intentionally darker than pastel; documented as separate domain (keep). New `--palette-*` vars expose SSOT hex for palette-exact use. |

**SkyConfig / PostProcessing (separate atmospheric domain — not palette drift):**

| File | Token | Value / Note |
|---|---|---|
| `SkyConfig.atmosphere.haze` | **5.0 → 4.5** | 5.0 washed silhouettes; 4.5 retains softness now that skybox alternates Purple/Blue per-face to break faceting (was haze-softened). 2K cubemap upgrade allows 3.0. |
| `SkyConfig.sky.skybox_lf` | **Purple→Blue** `129075…→119372…` | Was 129075 (Purple) drift vs `DayNightSky` day.lf Blue; now alternating mix (day.lf Blue) — fixes “squares in sky” faceting without relying on haze. `DayNightSky` morning.lf also Blue now. |
| `SkyConfig keyframes` (14) | verified | Smoothstep lerp, exposure -0.50→0.12, density 0.26–0.48, fog 75→1400 — smooth, no pops. |
| `PostProcessing bloomAtmo` | 0.08 kept, Threshold 0.55→**0.60**, Size 30→**28** | Only specular peaks bloom (Nikki refs). |
| `PostProcessing bloomSun` | 0.04→**0.03**, Size 24→**22**, Threshold 0.55→**0.60** | Sun disk whisper glow. |
| `PostProcessing SunRays` | 0.05→**0.035**, Spread 0.90→**0.85** | Nikki shafts whisper-thin. |
| `PostProcessing colorCorrection` | Contrast 0.04→**0.03**, Saturation 0.10→**0.12** | Retains pastel fold detail, nudged to weather_cc 0.13–0.16 range. |
| `PostProcessing DoF` | Far 0.08→**0.05**, Near 0.02→**0.015**, Radius 25→**28** | Distant pagoda less creamy, duo stays sharp. |

UIConfig/CSS now reference SSOT via hex comments and (CSS) `--palette-*` vars; do not change `ZundaPalette.lua` values directly — edit that file and re-Register.

## Git hub (durable source of truth)

- Rojo-owned: everything under `src/` mapped by `default.project.json`.
- Studio-owned: level content under Workspace/ServerStorage (git does NOT hold
  it; the built `ZundamonsKitchen.rbxl` artifact is the shareable snapshot).
- Wally: `Packages/` + `ServerPackages/` are gitignored; `wally.toml` is the
  durable dependency manifest.
- Built artifacts: CI uploads `ZundamonsKitchen.rbxl` + `sourcemap.json`
  (90-day `rojo-build` artifact; `vX.Y.Z` tag → GitHub Release).

## Authoring rules

1. New shared config → `src/shared/ConfigurationFiles/` with a `default.project.json` entry.
2. New remote → `src/shared/RemoteEvents|RemoteFunctions|RewardEvents/` as a
   `.model.json`; server ownership in an adapter/service, never ad-hoc.
3. New reusable visual asset → `src/shared/Models/` or `src/shared/Meshes/` (repo) or
   Studio place via ignore-unknown (level-owned).
4. New MaterialVariant → add to `src/Plugins/ZundaPalette.lua`, let the material
   plugin register it (or paste its Export Config snippet).
5. Never `git add -A`; keep owner source assets (`crucialassets/`, `.blend*`,
   generated builds) out of commits.

## Playtest feedback flow

`docs/PLAYTEST_NOTES.md` is the intake hub; see README "Live playtest notes".