#!/usr/bin/env python3
"""
VOICEVOX API Client — Zundamon's Kitchen V2 Voiceline Generation

Provides a reusable client for synthesizing Zundamon (ずんだもん) speech via the
local VOICEVOX engine REST API. Used by the voiceline worker to produce the
game's character VO bank.

The engine ships with the VOICEVOX desktop app at:
    %LOCALAPPDATA%\\Programs\\VOICEVOX\\vv-engine\\run.exe

Start it with:
    python scripts/voicevox_client.py --serve

Attribution requirement (see CREDITS.md):
    Zundamon's voice model is provided by VOICEVOX. Any work shipping this audio
    must credit "VOICEVOX:ずんだもん". Character rights: SSS LLC (https://zunko.jp).

Usage:
    from voicevox_client import VoicevoxClient, STYLES
    client = VoicevoxClient()
    client.synthesize("こんにちはなのだ！", STYLES["normal"], "out/hello.wav")
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Optional

# ─── Configuration ───────────────────────────────────────────────────────────

VOICEVOX_HOST = os.environ.get("VOICEVOX_HOST", "http://127.0.0.1:50021")
DEFAULT_TIMEOUT = 60  # seconds — synthesis of a short line is fast, but cold
# start after engine boot can take a few seconds on first request.

ENGINE_PATH = os.path.expandvars(
    r"%LOCALAPPDATA%\Programs\VOICEVOX\vv-engine\run.exe"
)

# ─── Zundamon Style IDs ──────────────────────────────────────────────────────
# Verified against the local engine (VOICEVOX 0.25.2, speaker "ずんだもん").
# Style choice is the main expressive lever we have — pick per game moment.

STYLES = {
    "normal": 3,  # ノーマル   — default lines, greetings, neutral barks
    "sweet": 1,  # あまあま   — rewards, level-up, praise (warm, high)
    "tsun": 7,  # ツンツン   — cook fail, impatience (sharp, clipped)
    "tsundere": 7,  # alias for tsun
    "sexy": 5,  # セクシー   — unused; kept for completeness
    "whisper": 22,  # ささやき   — ASMR-cozy ambient lines
    "hushed": 38,  # ヒソヒソ   — ASMR, quieter still than ささやき
    "weary": 75,  # ヘロヘロ   — low stamina, end of a long shift
    "teary": 76,  # なみだめ   — guest leaves unserved, failure beats
}


class VoicevoxError(RuntimeError):
    """Raised when the engine is unreachable or rejects a synthesis request."""


class VoicevoxClient:
    """Thin wrapper over the VOICEVOX engine's two-step synthesis API."""

    def __init__(self, host: str = VOICEVOX_HOST, timeout: int = DEFAULT_TIMEOUT):
        self.host = host.rstrip("/")
        self.timeout = timeout

    # ── engine lifecycle ─────────────────────────────────────────────────

    def is_up(self) -> bool:
        """Return True if the engine answers /version."""
        try:
            with urllib.request.urlopen(f"{self.host}/version", timeout=5) as r:
                return r.status == 200
        except Exception:
            return False

    def version(self) -> Optional[str]:
        try:
            with urllib.request.urlopen(f"{self.host}/version", timeout=5) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception:
            return None

    def ensure_up(self, autostart: bool = True, wait: int = 40) -> None:
        """Verify the engine is reachable, optionally booting it first.

        The engine takes ~10s to become ready on a cold start, so we poll rather
        than sleeping a fixed amount.
        """
        if self.is_up():
            return
        if not autostart:
            raise VoicevoxError(
                f"VOICEVOX engine not reachable at {self.host}. "
                f"Start it with: python scripts/voicevox_client.py --serve"
            )
        if not os.path.exists(ENGINE_PATH):
            raise VoicevoxError(
                f"VOICEVOX engine binary not found at {ENGINE_PATH}. "
                f"Install VOICEVOX or set VOICEVOX_HOST to a running engine."
            )
        subprocess.Popen(
            [ENGINE_PATH, "--host", "127.0.0.1", "--port", "50021"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        for _ in range(wait):
            if self.is_up():
                return
            time.sleep(1)
        raise VoicevoxError(f"VOICEVOX engine did not come up within {wait}s.")

    # ── synthesis ────────────────────────────────────────────────────────

    def audio_query(self, text: str, speaker: int) -> dict:
        """Step 1: build the prosody query object for `text`."""
        qs = urllib.parse.urlencode({"text": text, "speaker": speaker})
        req = urllib.request.Request(f"{self.host}/audio_query?{qs}", method="POST")
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as r:
                return json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raise VoicevoxError(
                f"audio_query failed ({e.code}) for text={text!r}: "
                f"{e.read().decode('utf-8', 'replace')[:200]}"
            ) from e

    def synthesis(self, query: dict, speaker: int) -> bytes:
        """Step 2: render the query object to WAV bytes."""
        qs = urllib.parse.urlencode({"speaker": speaker})
        req = urllib.request.Request(
            f"{self.host}/synthesis?{qs}",
            data=json.dumps(query).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            raise VoicevoxError(
                f"synthesis failed ({e.code}): "
                f"{e.read().decode('utf-8', 'replace')[:200]}"
            ) from e

    def synthesize(
        self,
        text: str,
        speaker: int,
        out_path: str,
        speed: float = 1.0,
        pitch: float = 0.0,
        intonation: float = 1.0,
        volume: float = 1.0,
    ) -> str:
        """Synthesize `text` to a WAV file at `out_path`. Returns the path.

        speed/pitch/intonation/volume map to VOICEVOX's speedScale, pitchScale,
        intonationScale and volumeScale respectively. Defaults are the engine's
        own neutral values.
        """
        query = self.audio_query(text, speaker)
        query["speedScale"] = speed
        query["pitchScale"] = pitch
        query["intonationScale"] = intonation
        query["volumeScale"] = volume
        wav = self.synthesis(query, speaker)

        os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
        with open(out_path, "wb") as f:
            f.write(wav)
        return out_path


# ─── CLI ─────────────────────────────────────────────────────────────────────


def main() -> int:
    ap = argparse.ArgumentParser(description="VOICEVOX engine helper")
    ap.add_argument("--serve", action="store_true", help="boot the engine and wait")
    ap.add_argument("--check", action="store_true", help="report engine status")
    ap.add_argument("--say", metavar="TEXT", help="synthesize one line to a file")
    ap.add_argument("--style", default="normal", choices=sorted(STYLES))
    ap.add_argument("--out", default="scripts/voicevox_output/test.wav")
    args = ap.parse_args()

    client = VoicevoxClient()

    if args.check:
        up = client.is_up()
        print(f"engine: {'UP' if up else 'DOWN'} @ {client.host}")
        if up:
            print(f"version: {client.version()}")
        return 0 if up else 1

    if args.serve:
        client.ensure_up()
        print(f"engine UP @ {client.host} (version {client.version()})")
        return 0

    if args.say:
        client.ensure_up()
        path = client.synthesize(args.say, STYLES[args.style], args.out)
        print(f"wrote {path}")
        return 0

    ap.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
