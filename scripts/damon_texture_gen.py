#!/usr/bin/env python3
"""
Damon Texture Generator — Zundamon's Kitchen V2
================================================

Generates 512×512 PNG "damon card" textures for each companion using their
glow color, sparkle palette, emoji, type badge, and dex number.

Requires: Pillow  (pip install Pillow)

Usage:
    python scripts/damon_texture_gen.py --all              # all companions
    python scripts/damon_texture_gen.py --key zundamon     # single companion
    python scripts/damon_texture_gen.py --list             # list known keys

Output: scripts/damon_textures/<key>.png
"""

import argparse
import json
import math
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ── Pillow import guard ───────────────────────────────────────────────────────
try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("[ERROR] Pillow is not installed. Run: pip install Pillow")
    sys.exit(1)

# ── Output directory ──────────────────────────────────────────────────────────
SCRIPTS_DIR  = Path(__file__).parent
OUTPUT_DIR   = SCRIPTS_DIR / "damon_textures"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
OUTPUT_DIR.mkdir(exist_ok=True)

# ── Companion data (mirrors CompanionConfig.lua) ──────────────────────────────
# glow: (R, G, B) 0–255
# sparkles: list of (R, G, B)
# types: list of type strings (primary first)
# dex_number: int

COMPANIONS: Dict[str, Dict] = {
    "zundamon":     {"glow": (160, 210, 150), "sparkles": [(200, 230, 190), (140, 200, 130), (220, 255, 210)], "emoji": "🌱", "types": ["Pea", "Celestial"],   "dex": 1,  "rarity": "Legendary"},
    "ankomon":      {"glow": (220,  90,  90), "sparkles": [(240, 120, 120), (220,  80,  80), (255, 200, 200)], "emoji": "🥜", "types": ["Pea", "Fermented"],    "dex": 2,  "rarity": "Rare"},
    "cardamon":     {"glow": (240, 200,  80), "sparkles": [(255, 230, 140), (240, 200,  80), (255, 250, 200)], "emoji": "🍋", "types": ["Spice", "Blossom"],    "dex": 3,  "rarity": "Rare"},
    "antimon":      {"glow": (120, 220, 200), "sparkles": [(160, 240, 220), (120, 220, 200), (220, 255, 250)], "emoji": "🌿", "types": ["Pea", "Fermented"],    "dex": 4,  "rarity": "Rare"},
    "sakuradamon":  {"glow": (255, 180, 220), "sparkles": [(255, 200, 230), (255, 160, 210), (255, 230, 250)], "emoji": "🌸", "types": ["Blossom", "Celestial"],"dex": 5,  "rarity": "Rare"},
    "tantanmon":    {"glow": (255, 100,  60), "sparkles": [(255, 140, 100), (255,  60,  40), (255, 200, 100)], "emoji": "🌶️","types": ["Spice"],               "dex": 6,  "rarity": "Rare"},
    "dog":          {"glow": (255, 200, 150), "sparkles": [(255, 220, 180), (255, 190, 130), (255, 240, 200)], "emoji": "🐕", "types": ["Pea"],                 "dex": 7,  "rarity": "Common"},
    "cat":          {"glow": (255, 200, 200), "sparkles": [(255, 220, 220), (255, 180, 180), (255, 240, 230)], "emoji": "🐱", "types": ["Blossom", "Shadow"],   "dex": 8,  "rarity": "Common"},
    "parrot":       {"glow": (255, 180, 100), "sparkles": [(255, 220, 150), (255, 170,  80), (255, 240, 200)], "emoji": "🦜", "types": ["Blossom", "Celestial"],"dex": 9,  "rarity": "Common"},
    "sumimon":      {"glow": (110, 120, 140), "sparkles": [( 70,  75,  90), (140, 150, 170), (200, 210, 225)], "emoji": "🖌️","types": ["Ink", "Shadow"],       "dex": 10, "rarity": "Epic"},
    "kagamon":      {"glow": (200, 230, 255), "sparkles": [(230, 245, 255), (180, 215, 250), (255, 255, 255)], "emoji": "🪞", "types": ["Blossom", "Shadow"],   "dex": 11, "rarity": "Epic"},
    "suzurimon":    {"glow": (240, 210, 130), "sparkles": [(255, 230, 160), (220, 180,  90), (255, 245, 200)], "emoji": "🔔", "types": ["Ancient", "Fermented"],"dex": 12, "rarity": "Epic"},
    "wasabimon":    {"glow": (130, 220, 120), "sparkles": [(160, 240, 150), (100, 190,  90), (210, 255, 200)], "emoji": "🌿", "types": ["Spice", "Ancient"],    "dex": 13, "rarity": "Rare"},
    "yurimon":      {"glow": (245, 210, 230), "sparkles": [(255, 225, 240), (235, 180, 210), (255, 245, 250)], "emoji": "🪷", "types": ["Blossom", "Celestial"],"dex": 14, "rarity": "Rare"},
    "kinakomon":    {"glow": (240, 195, 110), "sparkles": [(255, 220, 140), (225, 175,  80), (255, 240, 190)], "emoji": "🌾", "types": ["Pea", "Fermented"],    "dex": 15, "rarity": "Rare"},
    "kuroyurimon":  {"glow": (150, 100, 190), "sparkles": [(180, 130, 220), (110,  60, 150), (220, 190, 245)], "emoji": "🥀", "types": ["Shadow", "Blossom"],   "dex": 16, "rarity": "Epic"},
    "matchamon":    {"glow": (120, 180, 100), "sparkles": [(150, 210, 130), ( 90, 150,  70), (200, 235, 180)], "emoji": "🍵", "types": ["Fermented", "Ancient"], "dex": 17, "rarity": "Rare"},
    "shisomon":     {"glow": (180, 110, 190), "sparkles": [(210, 140, 220), (150,  80, 160), (235, 195, 240)], "emoji": "🍃", "types": ["Pea", "Fermented"],    "dex": 18, "rarity": "Rare"},
    "karintomon":   {"glow": (255, 150,  70), "sparkles": [(255, 180, 100), (230, 110,  40), (255, 220, 160)], "emoji": "🏮", "types": ["Spice", "Celestial"],  "dex": 19, "rarity": "Rare"},
    "tsukimidamon": {"glow": (210, 220, 255), "sparkles": [(230, 235, 255), (170, 190, 245), (255, 250, 210)], "emoji": "🌕", "types": ["Celestial", "Shadow"],  "dex": 20, "rarity": "Rare"},
    "hoshidamon":   {"glow": (255, 175, 100), "sparkles": [(255, 200, 130), (235, 140,  70), (255, 230, 180)], "emoji": "☀️", "types": ["Fermented", "Celestial"],"dex": 21, "rarity": "Epic"},
    "kiritandamon": {"glow": (100, 200, 230), "sparkles": [(130, 220, 250), ( 80, 180, 210), (200, 240, 255)], "emoji": "📐", "types": ["Ancient", "Spice"],    "dex": 22, "rarity": "Legendary"},
    "itakodamon":   {"glow": (160, 120, 200), "sparkles": [(190, 150, 230), (130,  90, 170), (220, 200, 255)], "emoji": "🔮", "types": ["Ancient", "Shadow"],   "dex": 23, "rarity": "Legendary"},
    "zunkodamon":   {"glow": (220, 160,  80), "sparkles": [(255, 190, 110), (200, 140,  60), (255, 230, 180)], "emoji": "⚔️", "types": ["Spice", "Celestial"],  "dex": 24, "rarity": "Legendary"},
    "zunabunny":    {"glow": (200, 240, 190), "sparkles": [(220, 255, 210), (170, 230, 160), (240, 255, 235)], "emoji": "🐰", "types": ["Pea", "Celestial"],   "dex": 25, "rarity": "Epic"},
    "nanonadamon":  {"glow": (140, 220, 160), "sparkles": [(160, 240, 180), (120, 200, 140), (210, 255, 220)], "emoji": "🏹", "types": ["Ancient", "Pea"],     "dex": 26, "rarity": "Mythic"},
}

# Type badge colors
TYPE_COLORS: Dict[str, Tuple[int, int, int]] = {
    "Pea":       (160, 210, 150),
    "Spice":     (255, 120,  60),
    "Blossom":   (255, 180, 210),
    "Shadow":    (110,  80, 150),
    "Celestial": (200, 215, 255),
    "Fermented": (200, 170, 120),
    "Ancient":   (220, 195, 145),
    "Ink":       (100, 110, 130),
}

# Rarity badge colors
RARITY_COLORS: Dict[str, Tuple[int, int, int]] = {
    "Common":   (180, 180, 180),
    "Rare":     (100, 160, 255),
    "Epic":     (190, 100, 255),
    "Legendary":(255, 200,  60),
    "Mythic":   (255, 100, 160),
}


def _lerp_color(c1: Tuple[int, int, int], c2: Tuple[int, int, int], t: float) -> Tuple[int, int, int]:
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
    )


def _brighten(c: Tuple[int, int, int], factor: float = 1.3) -> Tuple[int, int, int]:
    return (min(255, int(c[0] * factor)), min(255, int(c[1] * factor)), min(255, int(c[2] * factor)))


def _darken(c: Tuple[int, int, int], factor: float = 0.6) -> Tuple[int, int, int]:
    return (int(c[0] * factor), int(c[1] * factor), int(c[2] * factor))


def generate_card(key: str, data: Dict) -> Image.Image:
    SIZE = 512
    img  = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    glow     = data["glow"]
    sparkles = data["sparkles"]
    types    = data["types"]
    emoji    = data["emoji"]
    dex_num  = data["dex"]
    rarity   = data["rarity"]

    bright = _brighten(glow, 1.4)
    dark   = _darken(glow, 0.55)

    # ── Background: radial gradient using concentric ellipses ────────────────
    cx, cy = SIZE // 2, SIZE // 2
    steps = 60
    for i in range(steps, 0, -1):
        t = i / steps
        r = int(cx * t * 1.42)
        c = _lerp_color(bright, dark, 1 - t)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*c, 255))

    # ── Subtle vignette border ────────────────────────────────────────────────
    for i in range(20):
        alpha = int(180 * (i / 20))
        draw.rectangle([i, i, SIZE - i, SIZE - i], outline=(0, 0, 0, alpha), width=1)

    # ── Sparkle dots ─────────────────────────────────────────────────────────
    import random
    rng = random.Random(sum(ord(c) for c in key))  # deterministic per key
    for _ in range(40):
        sx = rng.randint(20, SIZE - 20)
        sy = rng.randint(20, SIZE - 20)
        sr = rng.randint(2, 6)
        sc = sparkles[rng.randint(0, len(sparkles) - 1)]
        sa = rng.randint(120, 255)
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(*sc, sa))

    # ── Dex number badge (top-left) ───────────────────────────────────────────
    dex_badge_color = _darken(glow, 0.45)
    draw.rounded_rectangle([12, 12, 80, 44], radius=10, fill=(*dex_badge_color, 220))
    # Use default font — Pillow truetype would need font files; default is safe
    draw.text((46, 28), f"#{dex_num:03d}", fill=(255, 255, 255, 220), anchor="mm")

    # ── Rarity badge (top-right) ──────────────────────────────────────────────
    rc = RARITY_COLORS.get(rarity, (200, 200, 200))
    draw.rounded_rectangle([SIZE - 100, 12, SIZE - 12, 44], radius=10, fill=(*rc, 220))
    draw.text((SIZE - 56, 28), rarity.upper(), fill=(20, 20, 20, 230), anchor="mm")

    # ── Type badge(s) (bottom-left) ───────────────────────────────────────────
    badge_y = SIZE - 50
    badge_x = 12
    for type_name in types[:2]:
        tc = TYPE_COLORS.get(type_name, (180, 180, 180))
        badge_w = len(type_name) * 9 + 20
        draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_w, badge_y + 30], radius=8, fill=(*tc, 210))
        draw.text((badge_x + badge_w // 2, badge_y + 15), type_name.upper(), fill=(20, 20, 20, 240), anchor="mm")
        badge_x += badge_w + 6

    # ── Center: large emoji ───────────────────────────────────────────────────
    # Pillow's default font doesn't render emoji; we draw a placeholder circle
    # and label the key instead. Artists replace with hand-drawn art.
    cr = 110
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(*_brighten(glow, 1.6), 200))
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], outline=(*_darken(glow, 0.4), 255), width=4)
    draw.text((cx, cy - 12), emoji, fill=(255, 255, 255, 240), anchor="mm")
    draw.text((cx, cy + 22), key.upper(), fill=(255, 255, 255, 200), anchor="mm")

    # ── Soft glow overlay around center ──────────────────────────────────────
    glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    for radius in range(cr + 10, cr + 60, 4):
        alpha = max(0, 60 - (radius - cr) * 2)
        gd.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], outline=(*glow, alpha), width=3)
    img = Image.alpha_composite(img, glow_layer)

    # ── Final rounded-corner mask ─────────────────────────────────────────────
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE, SIZE], radius=40, fill=255)
    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    result.paste(img, mask=mask)

    return result


def load_manifest() -> Dict[str, str]:
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_manifest(manifest: Dict[str, str]):
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)


def generate_one(key: str) -> Path:
    data = COMPANIONS.get(key)
    if not data:
        raise ValueError(f"Unknown companion key: '{key}'. Use --list to see available keys.")
    img  = generate_card(key, data)
    out  = OUTPUT_DIR / f"{key}.png"
    img.save(str(out), "PNG")
    print(f"  [OK] {key:20s}  ->  {out.name}  ({img.size[0]}x{img.size[1]})")
    return out


def main():
    parser = argparse.ArgumentParser(description="Generate damon card textures")
    group  = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all",  action="store_true", help="Generate textures for all companions")
    group.add_argument("--key",  metavar="KEY",       help="Generate texture for a single companion")
    group.add_argument("--list", action="store_true", help="List all known companion keys")
    args = parser.parse_args()

    if args.list:
        print("Known companion keys:")
        for k, d in sorted(COMPANIONS.items(), key=lambda x: x[1]["dex"]):
            print(f"  #{d['dex']:03d}  {k:20s}  ({d['rarity']})")
        return

    manifest = load_manifest()

    if args.all:
        print(f"Generating textures for {len(COMPANIONS)} companions -> {OUTPUT_DIR}")
        for key in sorted(COMPANIONS.keys(), key=lambda k: COMPANIONS[k]["dex"]):
            path = generate_one(key)
            manifest[key] = manifest.get(key, "")  # preserve existing asset IDs
        save_manifest(manifest)
        print(f"\nDone. {len(COMPANIONS)} PNGs written to {OUTPUT_DIR}")
        print(f"Manifest: {MANIFEST_PATH}")
        print("\nNext steps:")
        print("  1. Upload:  python scripts/damon_texture_upload.py --all")
        print("  2. Emit:    python scripts/emit_damon_texture_config.py")
        print("  3. OR replace PNGs with hand-drawn art — see docs/TEXTURE_PIPELINE.md")
    else:
        print(f"Generating texture for: {args.key}")
        path = generate_one(args.key)
        manifest[args.key] = manifest.get(args.key, "")
        save_manifest(manifest)


if __name__ == "__main__":
    main()
