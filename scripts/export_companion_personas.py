#!/usr/bin/env python3
"""
Export Companion Personas — Zundamon's Kitchen V2
=================================================

Extracts `llmPersona` entries from src/shared/ConfigurationFiles/CompanionConfig.lua
and exports them to scripts/companion_personas.json for use by companion_ai_server.py.

Usage:
    python scripts/export_companion_personas.py           # export JSON
    python scripts/export_companion_personas.py --check   # CI mode: fail if stale
"""

import argparse
import json
import re
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPTS_DIR.parent
COMPANION_CONFIG = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "CompanionConfig.lua"
OUTPUT_JSON = SCRIPTS_DIR / "companion_personas.json"


def extract_personas() -> dict:
    if not COMPANION_CONFIG.exists():
        print(f"[ERROR] {COMPANION_CONFIG} does not exist.")
        sys.exit(1)

    text = COMPANION_CONFIG.read_text(encoding="utf-8")
    m = re.search(r"CompanionConfig\.companions\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
    if not m:
        print("[ERROR] Could not find CompanionConfig.companions table in CompanionConfig.lua")
        sys.exit(1)

    # In CompanionConfig.lua, top-level companion definitions are indented with 1 tab: \t<key> = {
    blocks = re.findall(
        r'^\t([a-zA-Z0-9_]+)\s*=\s*\{(.*?)(?=^\t[a-zA-Z0-9_]+\s*=\s*\{|^\s*\}\s*$|\Z)',
        m.group(1),
        re.DOTALL | re.MULTILINE,
    )

    personas = {}
    for key, body in blocks:
        pm = re.search(r'llmPersona\s*=\s*"([^"]+)"', body)
        if pm:
            personas[key] = pm.group(1)
        else:
            print(f"[WARN] No llmPersona found for companion key '{key}'")

    return dict(sorted(personas.items()))


def main():
    parser = argparse.ArgumentParser(description="Export companion personas from CompanionConfig.lua to JSON")
    parser.add_argument("--check", action="store_true", help="CI mode: verify JSON is up to date without modifying disk")
    args = parser.parse_args()

    personas = extract_personas()
    expected_content = json.dumps(personas, ensure_ascii=False, indent=2) + "\n"

    if args.check:
        if not OUTPUT_JSON.exists():
            print(f"[FAIL] {OUTPUT_JSON.name} does not exist. Run: python scripts/export_companion_personas.py")
            sys.exit(1)
        current_content = OUTPUT_JSON.read_text(encoding="utf-8").replace("\r\n", "\n")
        if current_content != expected_content:
            print(f"[FAIL] {OUTPUT_JSON.name} is stale. Run: python scripts/export_companion_personas.py")
            sys.exit(1)
        print(f"[OK] {OUTPUT_JSON.name} is up to date ({len(personas)} personas).")
    else:
        OUTPUT_JSON.write_text(expected_content, encoding="utf-8")
        print(f"[OK] Written {len(personas)} personas to {OUTPUT_JSON}")


if __name__ == "__main__":
    main()
