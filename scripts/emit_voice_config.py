#!/usr/bin/env python3
"""
VoiceConfig Emitter — Zundamon's Kitchen V2

Generates `src/shared/ConfigurationFiles/VoiceConfig.lua` from
`voicevox_output/manifest.json`.

VoiceConfig is GENERATED — do not hand-edit it. Change the line script in
`voiceline_manifest.py`, re-run the worker + uploader, then re-run this.

Clips without an `asset_id` yet (not uploaded, or mid-moderation) are emitted as
commented-out placeholders, so the file always builds and the runtime simply has
fewer variants to pick from until the upload lands.

Usage:
    python scripts/emit_voice_config.py
    python scripts/emit_voice_config.py --check   # non-zero if stale
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, "voicevox_output", "manifest.json")
TARGET = os.path.join(HERE, "..", "src", "shared", "ConfigurationFiles", "VoiceConfig.lua")

# Per-moment cooldown in seconds. VO spam is the main failure mode for character
# voice: a line that fires on every serve during a rush becomes grating within a
# minute. High-frequency moments get long cooldowns, ceremonial ones get none.
COOLDOWNS = {
    "cook_start": 8.0,
    "cook_perfect": 4.0,
    "cook_good": 10.0,
    "cook_miss": 6.0,
    "guest_served": 5.0,
    "guest_left": 8.0,
    "coin_earn": 15.0,
    "companion_greeting": 30.0,
    "companion_pet": 2.0,
    "companion_buff": 10.0,
    "quest_complete": 0.0,
    "level_up": 0.0,
    "tier_up": 0.0,
    "challenge_start": 0.0,
    "wave_complete": 0.0,
    "daily_claim": 0.0,
    "idle_whisper": 45.0,
    "idle_weary": 90.0,
}

HEADER = """--!strict
-- [[ModuleScript] VoiceConfig]]
-- Zundamon character voice (VO) bank — GENERATED FILE, DO NOT HAND-EDIT.
--
-- Source of truth: scripts/voiceline_manifest.py
-- Regenerate:      python scripts/voicevox_voiceline_worker.py
--                  python scripts/upload_audio.py
--                  python scripts/emit_voice_config.py
--
-- Attribution (see CREDITS.md): VOICEVOX:ずんだもん
-- Zundamon character rights: SSS LLC (https://zunko.jp)
--
-- Lines are Japanese by design: VOICEVOX synthesizes Japanese only, and Zundamon
-- is canonically Japanese-voiced. UI text stays English.
--
-- Each moment holds several variants; the runtime picks at random so repeated
-- actions don't replay one identical clip. Cooldowns throttle high-frequency
-- moments — see ZundaSoundController.playVoice.

local VoiceConfig = {}

-- Master switch + volume. Voice sits above UI SFX in the mix but below music
-- stingers, so it reads as character presence rather than narration.
VoiceConfig.Enabled = true
VoiceConfig.MasterVolume = 0.8

-- Minimum seconds between two plays of the same moment. 0 = always play.
VoiceConfig.Cooldowns = {
"""


def lua_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def stylua_format(text: str) -> str:
    """Run the generated source through StyLua.

    The repo gates on `stylua --check src`, so a generated file that isn't
    StyLua-clean would break CI on every regeneration. Formatting here keeps the
    emitter's output gate-compliant by construction. If StyLua isn't installed we
    return the text unchanged rather than failing -- generation still works, the
    gate just catches it later.
    """
    if not shutil.which("stylua"):
        print("WARNING: stylua not on PATH — emitting unformatted (gate may fail)")
        return text

    tmp_dir = tempfile.mkdtemp()
    tmp = os.path.join(tmp_dir, "VoiceConfig.lua")
    try:
        with open(tmp, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        # Point StyLua at the repo config so temp-dir formatting matches src/.
        proc = subprocess.run(
            ["stylua", "--config-path", os.path.join(HERE, "..", "stylua.toml"), tmp],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            print(f"WARNING: stylua failed ({proc.stderr.strip()[:160]}) — emitting raw")
            return text
        with open(tmp, encoding="utf-8", newline="") as f:
            return f.read().replace("\r\n", "\n")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="exit non-zero if the target is missing or stale")
    args = ap.parse_args()

    if not os.path.exists(MANIFEST):
        print(f"ERROR: {MANIFEST} not found. Run voicevox_voiceline_worker.py first.")
        return 1

    with open(MANIFEST, encoding="utf-8") as f:
        clips = json.load(f)["clips"]

    moments: dict = {}
    for c in clips:
        moments.setdefault(c["moment"], []).append(c)

    out = [HEADER]
    for moment in sorted(moments):
        out.append(f"\t{moment} = {COOLDOWNS.get(moment, 0.0)},\n")
    out.append("}\n\n")

    resolved = sum(1 for c in clips if c.get("asset_id"))
    out.append(f"-- {resolved}/{len(clips)} clips uploaded. Pending clips are listed\n")
    out.append("-- as comments and simply aren't picked until they resolve.\n")
    out.append("VoiceConfig.Moments = {\n")

    for moment in sorted(moments):
        entries = moments[moment]
        out.append(f"\t{moment} = {{\n")
        for c in entries:
            comment = f"-- {c['text']} [{c['style_name']}, {c['duration']}s]"
            if c.get("asset_id"):
                out.append(f'\t\t"rbxassetid://{c["asset_id"]}", {comment}\n')
            else:
                out.append(f'\t\t-- PENDING UPLOAD: {c["key"]} {comment}\n')
        out.append("\t},\n")
    out.append("}\n\n")

    out.append("""-- Pick a random variant for `moment`, or nil if none are available yet.
function VoiceConfig.pick(moment: string): string?
	local variants = VoiceConfig.Moments[moment]
	if not variants or #variants == 0 then
		return nil
	end
	return variants[math.random(1, #variants)]
end

-- Cooldown for `moment` (0 when unthrottled).
function VoiceConfig.getCooldown(moment: string): number
	return VoiceConfig.Cooldowns[moment] or 0
end

return VoiceConfig
""")

    text = stylua_format("".join(out))
    target = os.path.normpath(TARGET)

    if args.check:
        if not os.path.exists(target):
            print("STALE: VoiceConfig.lua does not exist")
            return 1
        with open(target, encoding="utf-8", newline="") as f:
            if f.read().replace("\r\n", "\n") != text:
                print("STALE: VoiceConfig.lua differs from manifest — re-run emitter")
                return 1
        print("VoiceConfig.lua is up to date")
        return 0

    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)

    print(f"wrote {target}")
    print(f"  {len(moments)} moments, {len(clips)} clips, {resolved} with asset IDs")
    if resolved < len(clips):
        print(f"  {len(clips) - resolved} pending upload (emitted as comments)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
