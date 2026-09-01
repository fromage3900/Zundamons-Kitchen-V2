# Texture Pipeline — Zundamon's Kitchen V2

> Complete guide for generating, uploading, and wiring damon companion card textures.

---

## What Is a "Damon Card"?

Every companion has a 512×512 PNG "damon card" — a programmatically generated texture used in:
- The DamonDex collection UI
- Companion selection panels
- Gacha pull results
- Future trading card cosmetics

The generated cards are **placeholders by design** — they use the companion's glow color, type badge, rarity badge, and dex number. Artists can replace any PNG with hand-drawn art following the same output path.

---

## Pipeline Overview

```
scripts/damon_texture_gen.py        (generates PNGs)
        │
        ▼
scripts/damon_textures/<key>.png    (512×512, ready for upload or artist replacement)
        │
scripts/damon_texture_upload.py     (uploads via Roblox Open Cloud API)
        │
        ▼
scripts/damon_textures/manifest.json  (maps key → rbxassetid)
        │
scripts/emit_damon_texture_config.py  (reads manifest → emits Lua)
        │
        ▼
src/shared/ConfigurationFiles/DamonTextureConfig.lua  (DO NOT hand-edit)
```

---

## Step 1: Generate Textures

```bash
# All companions:
python scripts/damon_texture_gen.py --all

# Single companion:
python scripts/damon_texture_gen.py --key sumimon

# List all known keys:
python scripts/damon_texture_gen.py --list
```

**Requirements**: `pip install Pillow`

Output goes to `scripts/damon_textures/`. Each PNG is exactly 512×512.

---

## Step 2: (Optional) Replace with Hand-Drawn Art

To replace a generated card with hand-painted art:

1. Paint your artwork at **512×512 pixels**, RGBA PNG
2. Save it to `scripts/damon_textures/<companion_key>.png` (overwriting the generated card)
3. The upload and emit steps are identical — the pipeline doesn't care whether the PNG was generated or painted

### What an artist needs to know

- **Canvas**: 512×512 px, RGBA (transparent corners work fine — the game clips to a rounded rect)
- **Color brief per companion**: See [`DamonTypeConfig.lua`](../src/shared/ConfigurationFiles/DamonTypeConfig.lua) for each companion's `types`, and [`CompanionConfig.lua`](../src/shared/ConfigurationFiles/CompanionConfig.lua) for their `glow` Color3 and `sparkleColors`
- **Aesthetic**: Pastel Infinity Nikki style — soft lighting, glowing outlines, a central character silhouette, and a small type badge in one corner
- **Safe zone**: Keep key content in the central 400×400 px area; the outer 56px may be obscured by rounded corners
- **Naming**: File MUST be named exactly `<companion_key>.png` (e.g. `sumimon.png`, `zundamon.png`)

### Companion visual briefs

| Key | Primary color | Type | Personality cue |
|---|---|---|---|
| zundamon | Zunda green (160, 210, 150) | Pea | Fluffy, edamame ears, energetic |
| sumimon | Slate ink (110, 120, 140) | Ink | Brushstroke silhouette, ink drips |
| kagamon | Crystal blue (200, 230, 255) | Blossom/Shadow | Mirror fragments, hidden cracks |
| suzurimon | Bronze gold (240, 210, 130) | Ancient | Cracked bell, water drips |
| kuroyurimon | Deep violet (150, 100, 190) | Shadow | Gothic lily, hidden bookworm |
| tsukimidamon | Silver-blue (210, 220, 255) | Celestial | Moon crescent, dreamlike |
| matchamon | Matcha green (120, 180, 100) | Fermented | Tea bowl, steam, stillness |
| karintomon | Festival orange (255, 150, 70) | Spice | Fireworks, lantern light |

---

## Step 3: Upload to Roblox

```bash
# Set env vars first:
$env:ROBLOX_OPEN_CLOUD_API_KEY = "your-api-key"
$env:ROBLOX_CREATOR_USER_ID = "your-user-id"

# Upload all (resumable — safe to re-run):
python scripts/damon_texture_upload.py --all

# Upload single:
python scripts/damon_texture_upload.py --key sumimon
```

The script writes asset IDs back to `manifest.json`. Re-running skips already-uploaded entries.

**Note**: Uploaded assets go through Roblox moderation (typically < 1 hour). The asset ID is available immediately but the texture may not render until moderation passes.

---

## Step 4: Emit the Lua Config

```bash
python scripts/emit_damon_texture_config.py
```

This reads `manifest.json` and generates `DamonTextureConfig.lua`. **Never hand-edit this file.**

To check if the file is up to date (CI):
```bash
python scripts/emit_damon_texture_config.py --check
```

---

## Adding a New Companion to the Pipeline

1. Add the companion's glow, sparkles, emoji, types, dex number, and rarity to `COMPANIONS` in `scripts/damon_texture_gen.py`
2. Run `python scripts/damon_texture_gen.py --key <newkey>` to generate the PNG
3. Upload: `python scripts/damon_texture_upload.py --key <newkey>`
4. Emit: `python scripts/emit_damon_texture_config.py`
5. The CI `check_config_crossrefs.py` will flag any companion in `CompanionConfig.lua` that is missing from `DamonTextureConfig.lua`

---

## Visual Elements of the Generated Card

| Element | Location | Source |
|---|---|---|
| Background gradient | Full card | Companion's `glow` color (center bright, edges dark) |
| Sparkle dots | Scattered, 40 total | Companion's `sparkleColors` palette (deterministic) |
| Dex badge `#001` | Top-left | `dex` number |
| Rarity badge | Top-right | `rarity` (Common / Rare / Epic / Legendary / Mythic) |
| Type badge(s) | Bottom-left | First 2 types from `types` list |
| Center glow circle | Center | Companion's glow color + emoji label |
| Rounded corners | Card edge | 40px radius mask |

---

## CI Integration

`check_config_crossrefs.py` verifies that every key in `CompanionConfig.companions` has a corresponding entry in `DamonTextureConfig.textures`.

To run manually:
```bash
python scripts/check_config_crossrefs.py
```

If a companion is added to `CompanionConfig` without being added to the texture pipeline, CI fails with a clear error.
