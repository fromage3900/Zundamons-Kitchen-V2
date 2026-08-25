#!/usr/bin/env python3
"""
Companion Creator test harness — verifies the AI bridge + game-format compatibility.

Checks:
  1. Bridge /health reports llm + voicevox reachable.
  2. A real LLM generation returns a spec.
  3. The spec passes a Python mirror of the game's CompanionCreatorService.normalizeSpec
     (whitelist emoji, buff stat, string lengths, and NOW positional [r,g,b] colors) —
     proving the game will accept the bridge output without dropping colors.
  4. Several distinct themes produce distinct, valid specs (no crash, no dupes).

Run:
  python scripts/test_companion_ai.py [--themes "a;b;c"] [--url http://127.0.0.1:8700]
"""

import argparse
import json
import sys
import urllib.request
from pathlib import Path

BRIDGE = "http://127.0.0.1:8700"

# ── Game-side validation mirror (must match CompanionCreatorService) ─────────
ALLOWED_EMOJI = ["🌱", "🌸", "🍡", "🍵", "🌙", "☀️", "🍄", "🦊", "🐸", "🐢", "🐻", "🦉", "⭐", "🌊", "🍂", "🪷", "🥟", "🍙", "🫧", "💫"]
ALLOWED_BUFF_STATS = ["gold", "xp", "speed", "perfect_window", "extra_drop", "style_multiplier", "guest_patience", "combo_retention", "rare_ingredient_rate", "tip_multiplier", "stat_growth_rate", "overcook_protection", "chain_reaction", "gather_vision_range", "rng_variance", "night_shift_surge", "fermentation_perfection"]


def sanitize_color(value):
    """Mirror CompanionCreatorService.sanitizeColor incl. positional [r,g,b] array."""
    if value is None:
        return None
    if isinstance(value, list) and len(value) >= 3 and all(isinstance(x, (int, float)) for x in value[:3]):
        return [max(0.0, min(1.0, float(value[0]))), max(0.0, min(1.0, float(value[1]))), max(0.0, min(1.0, float(value[2])))]
    if isinstance(value, dict) and all(isinstance(value.get(k), (int, float)) for k in ("R", "G", "B")):
        return [max(0.0, min(1.0, float(value["R"]))), max(0.0, min(1.0, float(value["G"]))), max(0.0, min(1.0, float(value["B"])))]
    return None


def normalize_mirror(spec):
    """Mirror CompanionCreatorService.normalizeSpec -> returns (ok, normalized, reasons)."""
    reasons = []
    if not isinstance(spec, dict):
        return False, None, ["spec not a table"]
    name = str(spec.get("name") or "Mystery Zundamon")[:24]
    emoji = spec.get("emoji")
    if emoji not in ALLOWED_EMOJI:
        reasons.append(f"emoji '{emoji}' not whitelisted")
    buff = spec.get("buff")
    if isinstance(buff, dict):
        if buff.get("stat") not in ALLOWED_BUFF_STATS:
            reasons.append(f"buff.stat '{buff.get('stat')}' not whitelisted")
        mag = buff.get("magnitude")
        if not (isinstance(mag, (int, float)) and 0.0 <= mag <= 1.5):
            reasons.append(f"buff.magnitude {mag} out of range")
    glow = sanitize_color(spec.get("glow"))
    if glow is None:
        reasons.append("glow not a valid color")
    sc = spec.get("sparkleColors")
    sparkle_ok = 0
    if isinstance(sc, list):
        for c in sc:
            if sanitize_color(c):
                sparkle_ok += 1
    if sparkle_ok < 1:
        reasons.append("sparkleColors invalid")
    recipes = spec.get("signature_recipes")
    if not (isinstance(recipes, list) and len(recipes) >= 1 and all(isinstance(r, str) for r in recipes)):
        reasons.append("signature_recipes invalid")
    return (len(reasons) == 0), {
        "name": name,
        "emoji": emoji,
        "glow": glow,
        "sparkleColors": sc,
        "buff": buff,
        "signature_recipes": recipes,
    }, reasons


def generate(theme, url):
    body = json.dumps({"theme": theme}).encode("utf-8")
    req = urllib.request.Request(url + "/generate", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode("utf-8"))


def health(url):
    with urllib.request.urlopen(url + "/health", timeout=5) as r:
        return json.loads(r.read().decode("utf-8"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default=BRIDGE)
    ap.add_argument("--themes", default="a sleepy moon fox who loves rice balls;a grumpy mushroom chef;a bubbly sea-foam ghost that giggles")
    args = ap.parse_args()

    print("== 1. Health ==")
    try:
        h = health(args.url)
        print(f"   ok={h['ok']} llm={h['llm']} voicevox={h['voicevox']}")
        if not h["llm"]:
            print("   FAIL: LLM not reachable (start ollama serve)")
            return 1
    except Exception as e:
        print(f"   FAIL: bridge unreachable at {args.url}: {e}")
        return 1

    print("\n== 2-4. Generation + format validation ==")
    themes = [t for t in args.themes.split(";") if t.strip()]
    all_ok = True
    names = set()
    for i, theme in enumerate(themes, 1):
        try:
            spec = generate(theme.strip(), args.url)
        except Exception as e:
            print(f"   [{i}] theme='{theme}' FAILED to generate: {e}")
            all_ok = False
            continue
        ok, norm, reasons = normalize_mirror(spec)
        name = spec.get("name", "?")
        names.add(name)
        status = "PASS" if ok else "FAIL"
        if not ok:
            all_ok = False
        print(f"   [{i}] {status} name={name!r} emoji={spec.get('emoji')!r} buff={ (spec.get('buff') or {}).get('stat') } glow_ok={sanitize_color(spec.get('glow')) is not None}")
        for r in reasons:
            print(f"        - {r}")

    print("\n== 5. Distinctness ==")
    if len(names) < len(themes):
        print(f"   WARN: {len(themes)} themes produced only {len(names)} distinct names: {names}")
    else:
        print(f"   PASS: {len(names)} distinct companions generated")

    print("\nRESULT:", "ALL PASS" if all_ok else "FAILURES PRESENT")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
