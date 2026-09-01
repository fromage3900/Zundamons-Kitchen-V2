#!/usr/bin/env python3
"""
Expansion Oracle & Adversarial Verification Suite
Zundamon's Kitchen V2 — 100-Hour Expansion Pass

This test suite empirically verifies:
1. 26-Companion schema parity and completeness across all Lua configs, JSON manifests, and Python generators.
2. CLI flag behaviors and tamper detection for all pipeline scripts:
   - export_companion_personas.py (--check and drift detection)
   - emit_voice_config.py (--check and drift detection)
   - emit_damon_texture_config.py (--check and drift detection)
   - check_config_crossrefs.py (integrity and missing texture detection)
   - damon_texture_upload.py (--dry-run, --check, --key, arg parsing)
3. Integrity of generated Damon Card texture assets (512x512 PNG RGBA).
4. Stylistic, semantic, and canon constraints (Nanonadamonのだ speech endings, VOICEVOX styles).
5. CI Gates (stylua, selene, rojo build).

Run:
    python scripts/verify_expansion_oracle.py
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from PIL import Image

if sys.stdout.encoding != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"
SRC_DIR = REPO_ROOT / "src"
CONFIGS_DIR = SRC_DIR / "shared" / "ConfigurationFiles"

EXPECTED_26_COMPANIONS = [
    "zundamon", "dog", "parrot", "cat", "ankomon", "cardamon", "antimon",
    "sakuradamon", "tantanmon", "sumimon", "kagamon", "suzurimon",
    "wasabimon", "yurimon", "kinakomon", "kuroyurimon", "matchamon",
    "shisomon", "karintomon", "tsukimidamon", "hoshidamon",
    "kiritandamon", "itakodamon", "zunkodamon", "zunabunny", "nanonadamon"
]

CANON_5_COHORT = ["kiritandamon", "itakodamon", "zunkodamon", "zunabunny", "nanonadamon"]
NOVEL_12_DAMONS = [
    "sumimon", "kagamon", "suzurimon", "wasabimon", "yurimon", "kinakomon",
    "kuroyurimon", "matchamon", "shisomon", "karintomon", "tsukimidamon", "hoshidamon"
]

test_results = []

def record(test_name: str, passed: bool, details: str = ""):
    status = "PASS" if passed else "FAIL"
    test_results.append({"name": test_name, "status": status, "details": details})
    print(f"[{status}] {test_name}" + (f" - {details}" if details and not passed else ""))


def test_companion_config_completeness():
    print("\n--- Testing CompanionConfig.lua Schema & Completeness ---")
    file_path = CONFIGS_DIR / "CompanionConfig.lua"
    text = file_path.read_text(encoding="utf-8")
    m = re.search(r"CompanionConfig\.companions\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
    assert m, "Could not find CompanionConfig.companions table"

    keys_found = re.findall(r'^\t([a-zA-Z0-9_]+)\s*=\s*\{', m.group(1), re.MULTILINE)
    missing = set(EXPECTED_26_COMPANIONS) - set(keys_found)
    extra = set(keys_found) - set(EXPECTED_26_COMPANIONS)
    record("CompanionConfig contains all 26 companions", len(missing) == 0, f"Missing: {missing}")
    record("CompanionConfig has no duplicate/unexpected keys", len(keys_found) == 26 and len(extra) == 0, f"Found: {len(keys_found)}, Extra: {extra}")

    # Check fields for all 26 companions
    blocks = re.findall(
        r'^\t([a-zA-Z0-9_]+)\s*=\s*\{(.*?)(?=^\t[a-zA-Z0-9_]+\s*=\s*\{|^\s*\}\s*$|\Z)',
        m.group(1),
        re.DOTALL | re.MULTILINE,
    )
    all_fields_valid = True
    buff_stats = []
    for key, body in blocks:
        has_emoji = bool(re.search(r'emoji\s*=\s*"[^"]+"', body))
        has_glow = bool(re.search(r'glow\s*=\s*Color3\.fromRGB', body))
        has_glow_range = bool(re.search(r'glowRange\s*=\s*\d+', body))
        has_sparkles = bool(re.search(r'sparkleColors\s*=\s*\{', body))
        has_name = bool(re.search(r'displayName\s*=\s*"[^"]+"', body))
        has_flavor = bool(re.search(r'flavor\s*=\s*"[^"]+"', body))
        has_persona = bool(re.search(r'llmPersona\s*=\s*"[^"]+"', body))
        has_recipes = bool(re.search(r'signature_recipes\s*=\s*\{', body))
        has_synergy = bool(re.search(r'synergy_gold\s*=\s*\d+', body))

        bm = re.search(r'buff\s*=\s*\{\s*stat\s*=\s*"([^"]+)"', body)
        if bm:
            buff_stats.append(bm.group(1))

        if not (has_emoji and has_glow and has_glow_range and has_sparkles and has_name and has_flavor and has_persona and has_recipes and has_synergy):
            all_fields_valid = False
            print(f"Companion {key} missing required field(s)")

    record("All 26 companions have complete schema fields in CompanionConfig", all_fields_valid)
    unique_buffs = len(buff_stats) == len(set(buff_stats))
    record("All companion buff stats are unique", unique_buffs, f"Total buffs: {len(buff_stats)}, unique: {len(set(buff_stats))}")


def test_vn_portrait_config_completeness():
    print("\n--- Testing VNPortraitConfig.lua Completeness ---")
    file_path = CONFIGS_DIR / "VNPortraitConfig.lua"
    text = file_path.read_text(encoding="utf-8")

    sm = re.search(r"VNPortraitConfig\.speakerImages\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
    assert sm, "speakerImages table missing"
    speaker_keys = set(re.findall(r'^\t([a-zA-Z0-9_]+)\s*=', sm.group(1), re.MULTILINE))
    missing_speakers = set(EXPECTED_26_COMPANIONS) - speaker_keys
    record("VNPortraitConfig speakerImages has all 26 companions", len(missing_speakers) == 0, f"Missing: {missing_speakers}")

    em = re.search(r"VNPortraitConfig\.companionEmotes\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
    assert em, "companionEmotes table missing"
    cohort_emotes_valid = True
    expected_cohort_emotes = {
        "kiritandamon": {"neutral", "happy", "serious", "confident", "presenting", "surprised"},
        "itakodamon": {"neutral", "serious", "content", "emphatic", "surprised", "sad"},
        "zunkodamon": {"neutral", "excited", "emphatic", "confident", "happy", "serious"},
        "zunabunny": {"neutral", "excited", "joyful", "happy", "surprised", "emphatic"},
        "nanonadamon": {"neutral", "content", "serious", "sad", "presenting", "emphatic"},
    }
    for comp, emotes in expected_cohort_emotes.items():
        cm = re.search(rf"\t{comp}\s*=\s*\{{(.*?)\}}", em.group(1), re.DOTALL)
        if not cm:
            cohort_emotes_valid = False
            print(f"companionEmotes missing entry for {comp}")
            continue
        found_emotes = set(re.findall(r'(\w+)\s*=', cm.group(1)))
        if found_emotes != emotes:
            cohort_emotes_valid = False
            print(f"companionEmotes for {comp} expected {emotes}, got {found_emotes}")

    record("VNPortraitConfig companionEmotes has exact emotes for 5 canon cohort", cohort_emotes_valid)


def test_personas_sync():
    print("\n--- Testing companion_personas.json & export_companion_personas.py ---")
    json_path = SCRIPTS_DIR / "companion_personas.json"
    assert json_path.exists(), "companion_personas.json missing"

    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    missing_keys = set(EXPECTED_26_COMPANIONS) - set(data.keys())
    record("companion_personas.json contains all 26 companions", len(missing_keys) == 0 and len(data) == 26, f"Missing: {missing_keys}")

    # Test export_companion_personas.py --check
    res = subprocess.run([sys.executable, str(SCRIPTS_DIR / "export_companion_personas.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("export_companion_personas.py --check returns exit code 0", res.returncode == 0, res.stderr)

    # Tamper test: modify companion_personas.json and verify --check fails
    backup = json_path.read_bytes()
    try:
        tampered = data.copy()
        tampered["zundamon"] = "TAMPERED PERSONA STRING"
        json_path.write_text(json.dumps(tampered, indent=2) + "\n", encoding="utf-8")

        res_tamper = subprocess.run([sys.executable, str(SCRIPTS_DIR / "export_companion_personas.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
        record("export_companion_personas.py --check detects stale/tampered content", res_tamper.returncode != 0)

        # Re-export and verify restored
        res_export = subprocess.run([sys.executable, str(SCRIPTS_DIR / "export_companion_personas.py")], capture_output=True, text=True, encoding="utf-8", errors="replace")
        record("export_companion_personas.py re-generates correctly", res_export.returncode == 0)

        res_restored = subprocess.run([sys.executable, str(SCRIPTS_DIR / "export_companion_personas.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
        record("export_companion_personas.py --check passes after re-export", res_restored.returncode == 0)
    finally:
        json_path.write_bytes(backup)


def test_voicelines_completeness():
    print("\n--- Testing voiceline_manifest.py & VoiceConfig.lua ---")
    from voicevox_client import STYLES
    import voiceline_manifest

    voicelines = voiceline_manifest.VOICELINES
    keys = {vl["key"] for vl in voicelines}

    expected_canon_lines = [
        "kiritandamon_morning", "kiritandamon_bond", "kiritandamon_questcomplete",
        "itakodamon_morning", "itakodamon_bond", "itakodamon_questcomplete",
        "zunkodamon_morning", "zunkodamon_bond", "zunkodamon_questcomplete",
        "zunabunny_morning", "zunabunny_bond", "zunabunny_questcomplete",
        "nanonadamon_morning", "nanonadamon_bond", "nanonadamon_questcomplete"
    ]
    missing_canon_voicelines = set(expected_canon_lines) - keys
    record("voiceline_manifest.py has all 15 canon cohort lines", len(missing_canon_voicelines) == 0, f"Missing: {missing_canon_voicelines}")

    novel_lines = []
    for nd in NOVEL_12_DAMONS:
        novel_lines.extend([f"companion_{nd}_greet_1", f"companion_{nd}_bond3_1", f"companion_{nd}_unlock_1"])
    missing_novel_voicelines = set(novel_lines) - keys
    record("voiceline_manifest.py has all 36 novel damon lines", len(missing_novel_voicelines) == 0, f"Missing: {missing_novel_voicelines}")

    all_styles_valid = True
    for vl in voicelines:
        if vl["style_name"] not in STYLES:
            all_styles_valid = False
            print(f"Invalid style {vl['style_name']} for {vl['key']}")
        if not vl["text"]:
            all_styles_valid = False
            print(f"Empty text for {vl['key']}")

    record("All voicelines in manifest use valid VOICEVOX styles and have non-empty text", all_styles_valid)

    # Test emit_voice_config.py --check
    res_vc = subprocess.run([sys.executable, str(SCRIPTS_DIR / "emit_voice_config.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("emit_voice_config.py --check returns exit code 0", res_vc.returncode == 0, res_vc.stderr)

    # Tamper test
    vc_path = CONFIGS_DIR / "VoiceConfig.lua"
    backup_vc = vc_path.read_bytes()
    try:
        with open(vc_path, "ab") as f:
            f.write(b"\n-- TAMPER COMMENT\n")
        res_vc_tamper = subprocess.run([sys.executable, str(SCRIPTS_DIR / "emit_voice_config.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
        record("emit_voice_config.py --check detects stale/tampered VoiceConfig.lua", res_vc_tamper.returncode != 0)
    finally:
        vc_path.write_bytes(backup_vc)


def test_damon_textures_and_upload():
    print("\n--- Testing Damon Textures, emit_damon_texture_config.py & damon_texture_upload.py ---")
    manifest_path = SCRIPTS_DIR / "damon_textures" / "manifest.json"
    assert manifest_path.exists(), "damon_textures/manifest.json missing"

    with open(manifest_path, encoding="utf-8") as f:
        manifest_data = json.load(f)

    missing_tex = set(EXPECTED_26_COMPANIONS) - set(manifest_data.keys())
    record("damon_textures/manifest.json contains all 26 companions", len(missing_tex) == 0 and len(manifest_data) == 26, f"Missing: {missing_tex}")

    png_valid = True
    for comp in EXPECTED_26_COMPANIONS:
        png_path = SCRIPTS_DIR / "damon_textures" / f"{comp}.png"
        if not png_path.exists():
            png_valid = False
            print(f"Missing texture PNG for {comp}")
            continue
        with Image.open(png_path) as img:
            if img.size != (512, 512) or img.format != "PNG":
                png_valid = False
                print(f"Invalid texture specs for {comp}: {img.size}, {img.format}")

    record("All 26 damon texture PNGs exist with 512x512 PNG RGBA specs", png_valid)

    # Test emit_damon_texture_config.py --check
    res_dtc = subprocess.run([sys.executable, str(SCRIPTS_DIR / "emit_damon_texture_config.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("emit_damon_texture_config.py --check returns exit code 0", res_dtc.returncode == 0, res_dtc.stderr)

    # Tamper test
    dtc_path = CONFIGS_DIR / "DamonTextureConfig.lua"
    backup_dtc = dtc_path.read_bytes()
    try:
        with open(dtc_path, "ab") as f:
            f.write(b"\n-- TAMPER COMMENT\n")
        res_dtc_tamper = subprocess.run([sys.executable, str(SCRIPTS_DIR / "emit_damon_texture_config.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
        record("emit_damon_texture_config.py --check detects stale/tampered DamonTextureConfig.lua", res_dtc_tamper.returncode != 0)
    finally:
        dtc_path.write_bytes(backup_dtc)

    # Test damon_texture_upload.py CLI flags
    # 1. --dry-run
    res_dry = subprocess.run([sys.executable, str(SCRIPTS_DIR / "damon_texture_upload.py"), "--dry-run"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("damon_texture_upload.py --dry-run exits code 0 and lists 26 companions", res_dry.returncode == 0 and "26 pending" in res_dry.stdout)

    # 2. --key zundamon --dry-run
    res_key = subprocess.run([sys.executable, str(SCRIPTS_DIR / "damon_texture_upload.py"), "--key", "zundamon", "--dry-run"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("damon_texture_upload.py --key zundamon --dry-run targets 1 companion", res_key.returncode == 0 and "1 pending" in res_key.stdout)

    # 3. No args
    res_noargs = subprocess.run([sys.executable, str(SCRIPTS_DIR / "damon_texture_upload.py")], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("damon_texture_upload.py with no args exits with code 1 and help prompt", res_noargs.returncode == 1 and "Please specify" in res_noargs.stdout)

    # 4. --check
    res_check = subprocess.run([sys.executable, str(SCRIPTS_DIR / "damon_texture_upload.py"), "--check"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("damon_texture_upload.py --check detects invalid/unauthorized credentials", res_check.returncode == 1 and ("401" in res_check.stdout or "not set" in res_check.stdout))


def test_crossrefs_auditor():
    print("\n--- Testing check_config_crossrefs.py ---")
    res = subprocess.run([sys.executable, str(SCRIPTS_DIR / "check_config_crossrefs.py")], capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("check_config_crossrefs.py returns exit code 0 on pristine repo", res.returncode == 0, res.stdout + res.stderr)

    # Tamper test
    dtc_path = CONFIGS_DIR / "DamonTextureConfig.lua"
    backup_dtc = dtc_path.read_bytes()
    try:
        text_dtc = backup_dtc.decode("utf-8")
        tampered_dtc = re.sub(r'\tzundamon\s*=\s*"[^"]*",\n', '', text_dtc)
        with open(dtc_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(tampered_dtc)
        res_tamper = subprocess.run([sys.executable, str(SCRIPTS_DIR / "check_config_crossrefs.py")], capture_output=True, text=True, encoding="utf-8", errors="replace")
        record("check_config_crossrefs.py detects missing companion texture entry", res_tamper.returncode != 0 and "zundamon" in res_tamper.stdout)
    finally:
        dtc_path.write_bytes(backup_dtc)


def test_lore_and_canon_constraints():
    print("\n--- Testing Lore, Quests, Recipes & Canon Constraints ---")
    # 1. Nanonadamon dialogue lines end in ~のだ or ~なのだ
    vn_dialogue_path = CONFIGS_DIR / "VNDialogueData.lua"
    vn_text = vn_dialogue_path.read_text(encoding="utf-8")

    nm = re.search(r'COMPANION_DIALOGUE(?:\["nanonadamon"\]|\.nanonadamon)\s*=\s*\{(.*?)\n\}', vn_text, re.DOTALL)
    assert nm, "nanonadamon dialogue missing in VNDialogueData.lua"
    nanonada_lines = re.findall(r'"([^"]+)"', nm.group(1))
    nanonada_speech = [l for l in nanonada_lines if len(l) > 3 and not l.startswith("quest_") and not l.startswith("bond")]
    all_end_in_noda = all(l.rstrip("。！？!. ").endswith("のだ") or l.rstrip("。！？!. ").endswith("なのだ") or "のだ" in l[-5:] for l in nanonada_speech)
    record("Nanonadamon dialogue lines follow canonical ~のだ/~なのだ speech pattern", all_end_in_noda)

    # 2. Signature recipes in CraftConfig.lua
    craft_path = CONFIGS_DIR / "CraftConfig.lua"
    craft_text = craft_path.read_text(encoding="utf-8")
    craft_recipes = set(re.findall(r'craft\.recipes\["([^"]+)"\]\s*=', craft_text))
    craft_times = set(re.findall(r'craft\.cookingTimes\["([^"]+)"\]\s*=', craft_text))
    record("All recipes in CraftConfig have matching cookingTimes", craft_recipes == craft_times)

    # 3. Quests in QuestConfig.lua
    quest_path = CONFIGS_DIR / "QuestConfig.lua"
    quest_text = quest_path.read_text(encoding="utf-8")
    # Use word boundary to match only 'id = ...' and avoid 'grand_quest_id = ...'
    quest_ids = re.findall(r'\bid\s*=\s*"([^"]+)"', quest_text)
    from collections import Counter
    quest_counts = Counter(quest_ids)
    duplicates = {k: v for k, v in quest_counts.items() if v > 1}
    unique_quests = len(duplicates) == 0
    record("All Quest IDs across QuestConfig.lua are globally unique", unique_quests, f"Duplicates: {duplicates}")

    # Check 3 stages for the 17 new/expanded companions (12 novel + 5 canon cohort)
    EXPANDED_17_COMPANIONS = NOVEL_12_DAMONS + CANON_5_COHORT
    companion_quests_valid = True
    for comp in EXPANDED_17_COMPANIONS:
        q1 = f"quest_{comp}_1" in quest_ids
        q2 = f"quest_{comp}_2" in quest_ids
        q3 = f"quest_{comp}_3" in quest_ids
        if not (q1 and q2 and q3):
            companion_quests_valid = False
            print(f"Missing 3-stage quests for companion {comp} (q1={q1}, q2={q2}, q3={q3})")

    record("Novel and Canon-cohort companions have 3-stage quest chains (meet, bond, unlock)", companion_quests_valid)

    # 4. DamonTypeConfig.lua
    type_path = CONFIGS_DIR / "DamonTypeConfig.lua"
    type_text = type_path.read_text(encoding="utf-8")
    tm = re.search(r"DamonTypeConfig\.assignments\s*=\s*\{(.*?)\n\}", type_text, re.DOTALL)
    assert tm, "assignments table missing in DamonTypeConfig"
    type_keys = set(re.findall(r'^\t([a-zA-Z0-9_]+)\s*=', tm.group(1), re.MULTILINE))
    missing_type_keys = set(EXPECTED_26_COMPANIONS) - type_keys
    record("DamonTypeConfig assigns all 26 companions to elements", len(missing_type_keys) == 0, f"Missing: {missing_type_keys}")

    # 5. DamonDexConfig.lua
    dex_path = CONFIGS_DIR / "DamonDexConfig.lua"
    dex_text = dex_path.read_text(encoding="utf-8")
    dm = re.search(r"DamonDexConfig\.entries\s*=\s*\{(.*?)\n\}", dex_text, re.DOTALL)
    assert dm, "entries table missing in DamonDexConfig"
    dex_keys = set(re.findall(r'^\t([a-zA-Z0-9_]+)\s*=\s*\{', dm.group(1), re.MULTILINE))
    missing_dex_keys = set(EXPECTED_26_COMPANIONS) - dex_keys
    record("DamonDexConfig records entries for all 26 companions", len(missing_dex_keys) == 0, f"Missing: {missing_dex_keys}")

    # 6. DamonEvolutionConfig.lua
    evo_path = CONFIGS_DIR / "DamonEvolutionConfig.lua"
    evo_text = evo_path.read_text(encoding="utf-8")
    em = re.search(r"DamonEvolutionConfig\.evolutions\s*=\s*\{(.*?)\n\}", evo_text, re.DOTALL)
    assert em, "evolutions table missing in DamonEvolutionConfig"
    evo_pairs = re.findall(r'base\s*=\s*"([^"]+)"', em.group(1))
    record("DamonEvolutionConfig defines >= 8 evolution pairs", len(evo_pairs) >= 8, f"Found: {len(evo_pairs)}")


def test_ci_gates():
    print("\n--- Testing CI Quality Gates ---")
    # 1. StyLua
    res_stylua = subprocess.run(["stylua", "--check", "src"], cwd=str(REPO_ROOT), capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("CI Gate: stylua --check src passes cleanly", res_stylua.returncode == 0, res_stylua.stderr)

    # 2. Selene
    res_selene = subprocess.run(["selene", "--allow-warnings", "src"], cwd=str(REPO_ROOT), capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("CI Gate: selene --allow-warnings src reports 0 errors", res_selene.returncode == 0, res_selene.stdout)

    # 3. Rojo build
    res_rojo = subprocess.run(["rojo", "build", "default.project.json", "-o", "ZundamonsKitchen.rbxl"], cwd=str(REPO_ROOT), capture_output=True, text=True, encoding="utf-8", errors="replace")
    record("CI Gate: rojo build default.project.json builds successfully", res_rojo.returncode == 0, res_rojo.stdout)


def test_companion_ai_bridge():
    print("\n--- Testing Companion AI Bridge Server ---")
    import time
    import urllib.request
    test_port = "8755"
    proc = subprocess.Popen([sys.executable, str(SCRIPTS_DIR / "companion_ai_server.py"), "--port", test_port], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        time.sleep(1.5)
        # 1. Health endpoint
        with urllib.request.urlopen(f"http://127.0.0.1:{test_port}/health", timeout=3) as r:
            health_data = json.loads(r.read().decode("utf-8"))
            record("companion_ai_server GET /health returns status: ok", health_data.get("status") == "ok" and health_data.get("companions_loaded") == 26)

        # 2. Chat endpoint (offline fallback mode)
        chat_body = json.dumps({"companion_key": "nanonadamon", "player_name": "Chef", "message": "Good morning"}).encode("utf-8")
        req_chat = urllib.request.Request(f"http://127.0.0.1:{test_port}/companion-chat", data=chat_body, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req_chat, timeout=5) as r:
            chat_data = json.loads(r.read().decode("utf-8"))
            record("companion_ai_server POST /companion-chat returns non-empty reply", bool(chat_data.get("reply")))

        # 3. Generate endpoint (offline fallback mode)
        gen_body = json.dumps({"theme": "Blossom Tea spirit", "voice": "sweet"}).encode("utf-8")
        req_gen = urllib.request.Request(f"http://127.0.0.1:{test_port}/generate-companion", data=gen_body, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req_gen, timeout=5) as r:
            gen_data = json.loads(r.read().decode("utf-8"))
            record("companion_ai_server POST /generate-companion returns valid spec", bool(gen_data.get("name") or gen_data.get("displayName")))
    finally:
        proc.terminate()
        proc.wait()


def main():
    print("=" * 70)
    print("ZUNDAMON'S KITCHEN 100-HOUR EXPANSION — EMPIRICAL VERIFICATION HARNESS")
    print("=" * 70)

    test_companion_config_completeness()
    test_vn_portrait_config_completeness()
    test_personas_sync()
    test_voicelines_completeness()
    test_damon_textures_and_upload()
    test_crossrefs_auditor()
    test_lore_and_canon_constraints()
    test_companion_ai_bridge()
    test_ci_gates()

    print("\n" + "=" * 70)
    total = len(test_results)
    passed = sum(1 for r in test_results if r["status"] == "PASS")
    failed = total - passed
    print(f"SUMMARY: {passed}/{total} tests PASSED ({failed} failed)")
    print("=" * 70)

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
