#!/usr/bin/env python3
"""
Zundamon Voiceline Worker — Zundamon's Kitchen V2

Renders every entry in `voiceline_manifest.VOICELINES` to a WAV via the local
VOICEVOX engine, then emits a `manifest.json` describing what was produced.

The JSON is the handoff to the upload step (`upload_audio.py`), which fills in
Roblox asset IDs and produces `VoiceConfig.lua`.

Usage:
    python scripts/voicevox_voiceline_worker.py                 # generate all
    python scripts/voicevox_voiceline_worker.py --only cook_    # prefix filter
    python scripts/voicevox_voiceline_worker.py --force         # re-render
    python scripts/voicevox_voiceline_worker.py --list          # dry run

Output: scripts/voicevox_output/*.wav + manifest.json
"""

import argparse
import json
import os
import subprocess
import sys
import wave

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from voiceline_manifest import VOICELINES, groups  # noqa: E402
from voicevox_client import VoicevoxClient, VoicevoxError  # noqa: E402

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voicevox_output")

# Clips fire mid-gameplay; anything longer than this talks over the next action.
# Ceremonial beats (level_up, guest_left) and ambient ASMR lines are allowed to
# exceed it — the warning is a prompt to check, not a hard failure.
LONG_CLIP_WARN_SECONDS = 2.5

# Roblox accepts only MP3/OGG for audio uploads — WAV is rejected. We keep the
# VOICEVOX WAV as the lossless master and derive an MP3 for upload.
MP3_BITRATE = "128k"


def wav_duration(path: str) -> float:
    try:
        with wave.open(path, "rb") as w:
            return w.getnframes() / float(w.getframerate())
    except Exception:
        return 0.0


def to_mp3(wav_path: str, force: bool = False) -> str | None:
    """Derive an upload-ready MP3 next to `wav_path`. Returns the MP3 path."""
    mp3_path = os.path.splitext(wav_path)[0] + ".mp3"
    if os.path.exists(mp3_path) and not force:
        return mp3_path
    proc = subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
         "-codec:a", "libmp3lame", "-b:a", MP3_BITRATE, "-ac", "1", mp3_path],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        print(f"  mp3 FAIL {os.path.basename(wav_path)}: {proc.stderr.strip()[:160]}")
        return None
    return mp3_path


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate Zundamon voicelines")
    ap.add_argument("--only", help="only keys starting with this prefix")
    ap.add_argument("--force", action="store_true", help="re-render existing files")
    ap.add_argument("--list", action="store_true", help="show the script and exit")
    ap.add_argument("--out", default=OUT_DIR, help="output directory")
    ap.add_argument("--no-mp3", action="store_true",
                    help="skip MP3 derivation (WAV cannot be uploaded to Roblox)")
    args = ap.parse_args()

    entries = VOICELINES
    if args.only:
        entries = [e for e in entries if e["key"].startswith(args.only)]
        if not entries:
            print(f"no lines match prefix {args.only!r}")
            return 1

    if args.list:
        g = groups()
        print(f"{len(VOICELINES)} lines across {len(g)} moments")
        for e in entries:
            print(f"  {e['key']:24s} [{e['style_name']:8s}] {e['text']}")
        return 0

    client = VoicevoxClient()
    try:
        client.ensure_up()
    except VoicevoxError as e:
        print(f"ERROR: {e}")
        return 1

    os.makedirs(args.out, exist_ok=True)

    produced, skipped, failed, long_clips = [], 0, 0, []

    for e in entries:
        path = os.path.join(args.out, f"{e['key']}.wav")

        if os.path.exists(path) and not args.force:
            skipped += 1
            rec = {**_meta(e), "file": os.path.basename(path),
                   "duration": round(wav_duration(path), 2)}
            if not args.no_mp3:
                m = to_mp3(path, force=args.force)
                if m:
                    rec["mp3"] = os.path.basename(m)
            produced.append(rec)
            continue

        try:
            client.synthesize(
                e["text"], e["style"], path,
                speed=e["speed"], pitch=e["pitch"],
                intonation=e["intonation"], volume=e["volume"],
            )
        except VoicevoxError as err:
            print(f"  FAIL {e['key']}: {err}")
            failed += 1
            continue

        dur = wav_duration(path)
        if dur > LONG_CLIP_WARN_SECONDS:
            long_clips.append((e["key"], dur))
        rec = {**_meta(e), "file": os.path.basename(path),
               "duration": round(dur, 2)}
        if not args.no_mp3:
            m = to_mp3(path, force=True)
            if m:
                rec["mp3"] = os.path.basename(m)
        produced.append(rec)
        print(f"  ok   {e['key']:24s} [{e['style_name']:8s}] {dur:.2f}s  {e['text']}")

    manifest_path = os.path.join(args.out, "manifest.json")
    # Merge into any existing manifest rather than replacing it. A filtered run
    # (--only) must not drop the clips it didn't touch, and an upload run may
    # already have resolved asset IDs we need to preserve.
    existing = {}
    if os.path.exists(manifest_path):
        try:
            with open(manifest_path, encoding="utf-8") as f:
                existing = {c["key"]: c for c in json.load(f).get("clips", [])}
        except Exception:
            pass

    for clip in produced:
        prior = existing.get(clip["key"], {})
        if prior.get("asset_id"):
            clip["asset_id"] = prior["asset_id"]
        existing[clip["key"]] = clip

    # Emit in manifest order so the file stays diff-stable across runs.
    order = {e["key"]: i for i, e in enumerate(VOICELINES)}
    merged = sorted(existing.values(), key=lambda c: order.get(c["key"], 1 << 30))

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(
            {"source": "VOICEVOX", "speaker": "ずんだもん",
             "attribution": "VOICEVOX:ずんだもん — character rights SSS LLC",
             "clips": merged},
            f, ensure_ascii=False, indent=2,
        )

    print(f"\n{len(produced)} clips ({skipped} reused, {failed} failed) -> {args.out}")
    print(f"manifest: {manifest_path}")
    if long_clips:
        print(f"\nWARNING: {len(long_clips)} clip(s) over {LONG_CLIP_WARN_SECONDS}s "
              f"— these may talk over the next action:")
        for k, d in long_clips:
            print(f"  {k}  {d:.2f}s")
    return 1 if failed else 0


def _meta(e: dict) -> dict:
    return {
        "key": e["key"],
        "moment": e["key"].rsplit("_", 1)[0],
        "text": e["text"],
        "style": e["style"],
        "style_name": e["style_name"],
        "note": e["note"],
    }


if __name__ == "__main__":
    sys.exit(main())
