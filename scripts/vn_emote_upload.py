#!/usr/bin/env python3
"""
vn_emote_upload.py — One-shot Zundamon VN emote converter + uploader.

Converts each zundamon_emote_<group><variant>.gif in site/assets to a static
PNG frame, uploads it to Roblox Open Cloud as a Decal, then writes the
returned rbxassetid://<id> into VNPortraitConfig.emoteImages under the matching
semantic mood key.

Why a static frame: Roblox ImageLabel cannot render animated GIFs. Each emote
GIF is 29 frames; we export the middle frame (frame 15) as the representative
expression.

Usage:
    ROBLOX_API_KEY=<key> python scripts/vn_emote_upload.py

Requires the ROBLOX_API_KEY env var (Open Cloud key with Asset:Read/Write for
the creator in upload_decal.py — see tools/asset-pipeline/upload-asset.js).
If the key is invalid the upload fails and the config is left untouched
(safe to re-run once the key is fixed). Existing (non-empty) config values are
skipped unless --overwrite is passed, so you can upload only the missing ones.

Pillow (PIL) is required:  pip install pillow
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / "site" / "assets"
CONFIG_PATH = (
    REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "VNPortraitConfig.lua"
)

# GIF basename -> semantic emote key (must match VNPortraitConfig.emoteImages).
EMOTE_MAP = {
    "zundamon_emote_1a": "neutral",
    "zundamon_emote_1b": "happy",
    "zundamon_emote_2a": "presenting",
    "zundamon_emote_2b": "presenting_happy",
    "zundamon_emote_3a": "surprised",
    "zundamon_emote_3b": "excited",
    "zundamon_emote_4a": "emphatic",
    "zundamon_emote_4b": "emphatic_happy",
    "zundamon_emote_5a": "joyful",
    "zundamon_emote_5b": "confident",
    "zundamon_emote_6a": "joyful_point",
    "zundamon_emote_6b": "confident_point",
    "zundamon_emote_7a": "content",
    "zundamon_emote_7b": "serious",
    "zundamon_emote_7c": "serious_point",
}

FRAME_IDX = 15  # middle frame of the 29-frame GIFs


def read_config_values() -> dict[str, str]:
    """Parse current emoteImages values out of VNPortraitConfig.lua."""
    text = CONFIG_PATH.read_text(encoding="utf-8")
    block = re.search(r"VNPortraitConfig\.emoteImages = \{(.*?)\n\}", text, re.S)
    values = {}
    if block:
        for key, val in re.findall(r'(\w+)\s*=\s*"([^"]*)"', block.group(1)):
            values[key] = val
    return values


def write_config_value(key: str, asset_id: str) -> None:
    text = CONFIG_PATH.read_text(encoding="utf-8")
    # Match the exact line:  <key> = "",   ->  <key> = "rbxassetid://<id>",
    pat = re.compile(r'(^\s*)' + re.escape(key) + r'\s*=\s*""\s*,', re.M)
    new_val = f'\\1{key} = "rbxassetid://{asset_id}",'
    new_text, n = pat.subn(new_val, text, count=1)
    if n != 1:
        print(f"  !! Could not locate config key '{key}'; skipping write.")
        return
    CONFIG_PATH.write_text(new_text, encoding="utf-8")
    print(f"  Wrote rbxassetid://{asset_id} -> emoteImages.{key}")


def convert_gif_to_png(gif_path: Path) -> Path:
    im = Image.open(gif_path)
    im.seek(FRAME_IDX)
    frame = im.convert("RGBA")
    tmp = Path(tempfile.gettempdir()) / f"{gif_path.stem}.png"
    frame.save(tmp, "PNG")
    return tmp


def main() -> None:
    api_key = os.environ.get("ROBLOX_API_KEY", "")
    if not api_key:
        print("ERROR: ROBLOX_API_KEY env var not set.")
        print("Set it, e.g.:  export ROBLOX_API_KEY='your-key-here'")
        sys.exit(1)

    overwrite = "--overwrite" in sys.argv
    current = read_config_values()

    missing = []
    for gif_stem, emote_key in EMOTE_MAP.items():
        if not overwrite and current.get(emote_key):
            print(f"  skip {gif_stem} -> {emote_key} (already set)")
            continue
        missing.append((gif_stem, emote_key))

    if not missing:
        print("No emotes need uploading (all configured). Done.")
        return

    print(f"Preparing {len(missing)} emote frames...")
    for gif_stem, emote_key in missing:
        gif = ASSETS_DIR / f"{gif_stem}.gif"
        if not gif.exists():
            print(f"  !! missing source {gif.name}; skipping")
            continue
        png = convert_gif_to_png(gif)
        print(f"  Uploading {gif.name} as Decal '{emote_key}'...")
        proc = subprocess.run(
            ["python", "tools/asset-pipeline/upload-asset.js",
             str(png), "Decal", f"Zundamon {emote_key}", "Zundamon VN emote"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
        out = proc.stdout + proc.stderr
        if proc.returncode != 0:
            print(f"  !! upload failed for {gif.name}:\n{out}")
            print("Config left unchanged. Fix the API key and re-run.")
            continue
        m = re.search(r"rbxassetid://(\d+)", out)
        if not m:
            print(f"  !! could not parse asset id from:\n{out}")
            continue
        write_config_value(emote_key, m.group(1))
        png.unlink(missing_ok=True)

    print("Done. Re-sync Rojo / republish for the portraits to appear in Studio.")


if __name__ == "__main__":
    main()
