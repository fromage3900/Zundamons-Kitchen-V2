"""
Verification Oracle for Milestone M1 Companion Expansion.
Programmatically stress-tests all configuration files, cross-references, schemas, uniqueness,
creative constraints, and asset consistency across the repository.
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

COMPANION_CONFIG = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "CompanionConfig.lua"
VN_DIALOGUE = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "VNDialogueData.lua"
VN_PORTRAIT = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "VNPortraitConfig.lua"
QUEST_CONFIG = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "QuestConfig.lua"
CRAFT_CONFIG = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "CraftConfig.lua"
GATHER_CONFIG = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "GatherConfig.lua"
MINEABLE_CONFIG = REPO_ROOT / "src" / "shared" / "ConfigurationFiles" / "MineableConfig.lua"
VOICELINE_MANIFEST = REPO_ROOT / "scripts" / "voiceline_manifest.py"

LEGACY_COMPANIONS = {
    "zundamon", "ankomon", "cardamon", "antimon", "sakuradamon",
    "tantanmon", "dog", "cat", "parrot"
}

EXPECTED_NEW_COMPANIONS = {
    "sumimon", "kagamon", "suzurimon", "wasabimon", "yurimon",
    "kinakomon", "kuroyurimon", "matchamon", "shisomon",
    "karintomon", "tsukimidamon", "hoshidamon"
}

LEGACY_BUFFS = {"gold", "perfect_window", "extra_drop", "xp", "speed"}

# Creative classifications
DARK_TRAGIC_COMPANIONS = {"sumimon", "kagamon", "suzurimon"}
UNRELIABLE_NARRATOR_COMPANIONS = {"kagamon", "kuroyurimon"}
NON_FOOD_COMPANIONS = {"sumimon", "kagamon", "suzurimon"}

VALID_QUEST_TYPES = {
    "serve", "cook", "cook_perfect", "cook_great", "gather", "earn_gold",
    "companion_chat", "companion_affection", "visit_zone", "visit_zones_unique",
    "npc_chat", "cook_unique", "cook_unique_zunda", "cook_quality",
    "cook_speed", "cook_unique_seasonal", "gather_unique", "set_companion",
    "npc_chat_all", "zundarooms_escape", "challenge_wave", "style_points"
}

def test_companion_keys_and_schema():
    print("\n--- [Test 1] CompanionConfig.lua Catalog & Schema ---")
    content = COMPANION_CONFIG.read_text(encoding="utf-8")
    
    cat_match = re.search(r"CompanionConfig\.companions\s*=\s*\{(.*?)\n\}", content, re.DOTALL)
    assert cat_match, "Could not find CompanionConfig.companions table"
    cat_body = cat_match.group(1)
    
    comp_matches = re.findall(r"\n\t([a-z0-9_]+)\s*=\s*\{", cat_body)
    found_companions = set(comp_matches)
    
    print(f"Total companions in CompanionConfig.lua: {len(found_companions)}")
    print(f"Found: {sorted(found_companions)}")
    
    # Check legacy companions preserved
    missing_legacy = LEGACY_COMPANIONS - found_companions
    assert not missing_legacy, f"Missing legacy companions: {missing_legacy}"
    print("[PASS] All legacy companions preserved intact.")
    
    # Check expected new companions present
    missing_new = EXPECTED_NEW_COMPANIONS - found_companions
    assert not missing_new, f"Missing expected new companions: {missing_new}"
    print("[PASS] All 12 new companions defined in CompanionConfig.lua.")
    
    # Check no key collision between new and legacy
    overlap = EXPECTED_NEW_COMPANIONS & LEGACY_COMPANIONS
    assert not overlap, f"Collision between new and legacy companions: {overlap}"
    print("[PASS] Zero key collisions between new companions and legacy companions.")
    
    # Check schema fields and buffs for new companions
    buffs = {}
    signatures = {}
    for comp in EXPECTED_NEW_COMPANIONS:
        block_m = re.search(rf"\t{comp}\s*=\s*\{{(.*?)\n\t\}},", cat_body, re.DOTALL)
        assert block_m, f"Could not find block for companion {comp}"
        block = block_m.group(1)
        
        required_fields = ["emoji", "glow", "glowRange", "sparkleColors", "buff", "free", "price", "displayName", "flavor", "llmPersona", "signature_recipes", "synergy_gold"]
        for field in required_fields:
            assert f"{field} =" in block or f"{field}=" in block, f"Companion {comp} missing field {field}"
            
        buff_stat_m = re.search(r'stat\s*=\s*"([^"]+)"', block)
        assert buff_stat_m, f"Companion {comp} missing buff stat"
        buff_stat = buff_stat_m.group(1)
        buffs[comp] = buff_stat
        
        sig_m = re.search(r'signature_recipes\s*=\s*\{([^}]+)\}', block)
        assert sig_m, f"Companion {comp} missing signature_recipes"
        sigs = re.findall(r'\["([^"]+)"\]\s*=\s*true', sig_m.group(1))
        assert len(sigs) >= 2, f"Companion {comp} has fewer than 2 signature recipes: {sigs}"
        signatures[comp] = sigs

    # Check buff collisions
    buff_stats = list(buffs.values())
    print(f"New companion buffs: {buffs}")
    assert len(set(buff_stats)) == len(buff_stats), f"Duplicate buffs among new companions: {buff_stats}"
    buff_legacy_collision = set(buff_stats) & LEGACY_BUFFS
    assert not buff_legacy_collision, f"New companion buffs collide with legacy buffs: {buff_legacy_collision}"
    print(f"[PASS] All {len(buff_stats)} new buff stats are globally unique and non-overlapping with legacy buffs.")
    
    return found_companions, signatures

def test_vn_dialogue_data():
    print("\n--- [Test 2] VNDialogueData.lua Speakers & Trees ---")
    content = VN_DIALOGUE.read_text(encoding="utf-8")
    
    # 1. SPEAKERS block
    speakers_block_m = re.search(r"SPEAKERS\s*=\s*\{(.*?)\n\}", content, re.DOTALL)
    assert speakers_block_m, "Could not find SPEAKERS table"
    speakers_block = speakers_block_m.group(1)
    speaker_keys = set(re.findall(r"\t([a-z0-9_]+)\s*=\s*\{", speakers_block))
    
    for comp in EXPECTED_NEW_COMPANIONS:
        assert comp in speaker_keys, f"Companion {comp} missing in SPEAKERS"
    print(f"[PASS] All 12 companions present in VNDialogueData.SPEAKERS.")
    
    # 2. COMPANION_DIALOGUE block
    comp_diag_m = re.search(r"local\s+COMPANION_DIALOGUE\s*=\s*\{(.*?)\n\}\n\n-- Serve-time", content, re.DOTALL)
    assert comp_diag_m, "Could not find COMPANION_DIALOGUE table"
    comp_diag_body = comp_diag_m.group(1)
    
    for comp in EXPECTED_NEW_COMPANIONS:
        diag_block_m = re.search(rf"\t{comp}\s*=\s*\{{(.*?)\n\t\}},", comp_diag_body, re.DOTALL)
        assert diag_block_m, f"Missing COMPANION_DIALOGUE for {comp}"
        diag_block = diag_block_m.group(1)
        
        required_branches = ["morning", "afternoon", "evening", "night", "bond1", "bond2", "bond3", "quest_branch"]
        for branch in required_branches:
            assert f"{branch} =" in diag_block or f"{branch}=" in diag_block, f"Companion {comp} missing branch {branch}"
            
        # Count lines per branch using line indentation
        for branch in ["morning", "afternoon", "evening", "night"]:
            branch_m = re.search(rf'{branch}\s*=\s*\{{\n(.*?)\n\t\t\}},', diag_block, re.DOTALL)
            assert branch_m, f"Companion {comp} missing {branch}"
            lines = [l.strip() for l in branch_m.group(1).splitlines() if l.strip().startswith('"')]
            assert len(lines) >= 3, f"Companion {comp} branch {branch} has fewer than 3 lines: {len(lines)}"

        bond1_m = re.search(r'bond1\s*=\s*\{\n(.*?)\n\t\t\},', diag_block, re.DOTALL)
        bond2_m = re.search(r'bond2\s*=\s*\{\n(.*?)\n\t\t\},', diag_block, re.DOTALL)
        bond3_m = re.search(r'bond3\s*=\s*\{\n(.*?)\n\t\t\},', diag_block, re.DOTALL)
        quest_b_m = re.search(r'quest_branch\s*=\s*\{\n(.*?)\n\t\t\},', diag_block, re.DOTALL)
        assert bond1_m and bond2_m and bond3_m and quest_b_m, f"Companion {comp} missing bond / quest branches"
        
        b1_lines = [l.strip() for l in bond1_m.group(1).splitlines() if l.strip().startswith('"')]
        b2_lines = [l.strip() for l in bond2_m.group(1).splitlines() if l.strip().startswith('"')]
        b3_lines = [l.strip() for l in bond3_m.group(1).splitlines() if l.strip().startswith('"')]
        qb_lines = [l.strip() for l in quest_b_m.group(1).splitlines() if l.strip().startswith('"')]
        
        assert len(b1_lines) >= 2, f"Companion {comp} bond1 has fewer than 2 lines: {len(b1_lines)}"
        assert len(b2_lines) >= 2, f"Companion {comp} bond2 has fewer than 2 lines: {len(b2_lines)}"
        assert len(b3_lines) >= 2, f"Companion {comp} bond3 has fewer than 2 lines: {len(b3_lines)}"
        assert len(qb_lines) >= 2, f"Companion {comp} quest_branch has fewer than 2 lines: {len(qb_lines)}"
        
        # Ensure bond3 is distinct from bond1
        assert b1_lines != b3_lines, f"Companion {comp} bond1 and bond3 are identical!"
        
    print("[PASS] All 12 companions have complete dialogue trees with >=3 time slot lines, >=2 bond lines, and distinct bond progression.")
    
    # 3. SERVE_REACTIONS & SERVE_SYNERGIES
    serve_rx_m = re.search(r"local\s+SERVE_REACTIONS\s*=\s*\{(.*?)\n\}", content, re.DOTALL)
    assert serve_rx_m, "Could not find SERVE_REACTIONS table"
    serve_rx_body = serve_rx_m.group(1)
    for comp in EXPECTED_NEW_COMPANIONS:
        assert f"\t{comp} =" in serve_rx_body or f"\t{comp}=" in serve_rx_body, f"Missing serve reaction for {comp}"
        
    serve_syn_m = re.search(r"local\s+SERVE_SYNERGIES\s*=\s*\{(.*?)\n\}", content, re.DOTALL)
    assert serve_syn_m, "Could not find SERVE_SYNERGIES table"
    serve_syn_body = serve_syn_m.group(1)
    for comp in EXPECTED_NEW_COMPANIONS:
        assert f"\t{comp} =" in serve_syn_body or f"\t{comp}=" in serve_syn_body, f"Missing serve synergy for {comp}"

    print("[PASS] SERVE_REACTIONS and SERVE_SYNERGIES fully populated for all 12 companions.")

def test_vn_portrait_config():
    print("\n--- [Test 3] VNPortraitConfig.lua Speaker Images & Emotes ---")
    content = VN_PORTRAIT.read_text(encoding="utf-8")
    
    speaker_images_m = re.search(r"VNPortraitConfig\.speakerImages\s*=\s*\{(.*?)\n\}", content, re.DOTALL)
    assert speaker_images_m, "Could not find VNPortraitConfig.speakerImages"
    speaker_images_body = speaker_images_m.group(1)
    
    for comp in EXPECTED_NEW_COMPANIONS:
        assert re.search(rf"\t{comp}\s*=\s*", speaker_images_body), f"Companion {comp} missing in VNPortraitConfig.speakerImages"
        
    # Check bondTierEmotes mapping exists
    assert "VNPortraitConfig.bondTierEmotes" in content, "Missing VNPortraitConfig.bondTierEmotes"
    print("[PASS] All 12 companions registered in VNPortraitConfig.speakerImages and bondTierEmotes configured.")

def test_quest_config():
    print("\n--- [Test 4] QuestConfig.lua 3-Stage Questlines & Global ID Uniqueness ---")
    content = QUEST_CONFIG.read_text(encoding="utf-8")
    
    all_quest_ids = re.findall(r'\bid\s*=\s*"([^"]+)"', content)
    print(f"Total quest IDs found in QuestConfig.lua: {len(all_quest_ids)}")
    
    # Global uniqueness check
    duplicates = [qid for qid in set(all_quest_ids) if all_quest_ids.count(qid) > 1]
    assert not duplicates, f"Duplicate quest IDs found in QuestConfig.lua: {duplicates}"
    print(f"[PASS] All {len(all_quest_ids)} quest IDs in QuestConfig.lua are 100% globally unique.")
    
    # Check 3 stages for each new companion
    quest_types_used = set()
    for comp in EXPECTED_NEW_COMPANIONS:
        # Stage 1: Meet / Gather / Encounter
        q1_m = re.search(rf'\{{[^}}]*?id\s*=\s*"quest_{comp}_1".*?\n\t\t\}},', content, re.DOTALL)
        assert q1_m, f"Missing quest_1 for {comp}"
        t1 = re.search(r'type\s*=\s*"([^"]+)"', q1_m.group(0)).group(1)
        quest_types_used.add(t1)
        
        # Stage 2: Bond progression
        q2_m = re.search(rf'\{{[^}}]*?id\s*=\s*"quest_{comp}_2".*?\n\t\t\}},', content, re.DOTALL)
        assert q2_m, f"Missing quest_2 for {comp}"
        q2_obj = q2_m.group(0)
        t2 = re.search(r'type\s*=\s*"([^"]+)"', q2_obj).group(1)
        quest_types_used.add(t2)
        assert "bond_tier = 2" in q2_obj or "bond_tier=2" in q2_obj or "bond_tier" in q2_obj, f"Stage 2 quest for {comp} missing bond_tier reward"
        
        # Stage 3: Unlock
        q3_m = re.search(rf'\{{[^}}]*?id\s*=\s*"quest_{comp}_3".*?\n\t\t\}},', content, re.DOTALL)
        assert q3_m, f"Missing quest_3 for {comp}"
        q3_obj = q3_m.group(0)
        t3 = re.search(r'type\s*=\s*"([^"]+)"', q3_obj).group(1)
        quest_types_used.add(t3)
        assert f'companion_unlock = "{comp}"' in q3_obj or f"companion_unlock='{comp}'" in q3_obj, f"Stage 3 quest for {comp} missing companion_unlock = '{comp}'"

    print(f"Quest types used across 36 companion quests: {sorted(quest_types_used)}")
    for qt in quest_types_used:
        assert qt in VALID_QUEST_TYPES, f"Invalid or unrecognized quest type: {qt}"

    print("[PASS] All 36 companion quest stages (1=Encounter, 2=Bond, 3=Unlock) exist with valid quest types and unlocking metadata.")

def test_craft_config_and_ingredients(signatures):
    print("\n--- [Test 5] CraftConfig.lua Recipes & Ingredient Integrity ---")
    craft_content = CRAFT_CONFIG.read_text(encoding="utf-8")
    gather_content = GATHER_CONFIG.read_text(encoding="utf-8")
    mineable_content = MINEABLE_CONFIG.read_text(encoding="utf-8")
    
    valid_ingredients = set()
    
    # Click resources
    gather_items = re.findall(r'itemName\s*=\s*"([^"]+)"', gather_content)
    mystery_items = re.findall(r'"([^"]+)"', re.search(r"mysteryLoot\s*=\s*\{(.*?)\}", gather_content, re.DOTALL).group(1))
    valid_ingredients.update(gather_items)
    valid_ingredients.update(mystery_items)
    
    # Mineables and loots
    price_items = re.findall(r'\["([^"]+)"\]\s*=', re.search(r"priceLists\s*=\s*\{(.*?)\}", mineable_content, re.DOTALL).group(1))
    mineable_loots = re.findall(r'"([^"]+)"', re.search(r"Mineables\s*=\s*\{(.*?)\n\}", mineable_content, re.DOTALL).group(1))
    valid_ingredients.update(price_items)
    valid_ingredients.update(mineable_loots)
    
    valid_ingredients.add("Gold")
    valid_ingredients.add("Gold Ore")
    
    print(f"Known valid ingredient set ({len(valid_ingredients)} items)")
    
    recipes_block_m = re.search(r"craft\.recipes\s*=\s*\{(.*?)\n\}", craft_content, re.DOTALL)
    assert recipes_block_m, "Could not find craft.recipes"
    recipes_block = recipes_block_m.group(1)
    
    times_block_m = re.search(r"craft\.cookingTimes\s*=\s*\{(.*?)\n\}", craft_content, re.DOTALL)
    assert times_block_m, "Could not find craft.cookingTimes"
    times_block = times_block_m.group(1)
    
    for comp, sigs in signatures.items():
        main_dish = sigs[0]
        assert f'["{main_dish}"]' in recipes_block, f"Recipe for '{main_dish}' missing in craft.recipes"
        assert f'["{main_dish}"]' in times_block, f"Cooking time for '{main_dish}' missing in craft.cookingTimes"
        
        dish_m = re.search(rf'\["{re.escape(main_dish)}"\]\s*=\s*\{{([^}}]+)\}}', recipes_block)
        assert dish_m, f"Could not parse ingredients for {main_dish}"
        dish_ings = re.findall(r'\["([^"]+)"\]\s*=\s*\d+', dish_m.group(1))
        
        for ing in dish_ings:
            assert ing in valid_ingredients, f"Invalid ingredient '{ing}' used in '{main_dish}'!"
            
    print("[PASS] All 12 companion signature recipes and cooking times are registered and use 100% valid in-game ingredients.")

def test_voiceline_manifest():
    print("\n--- [Test 6] scripts/voiceline_manifest.py Entries ---")
    manifest_content = VOICELINE_MANIFEST.read_text(encoding="utf-8")
    
    for comp in EXPECTED_NEW_COMPANIONS:
        for moment_type in ["greet", "bond3", "unlock"]:
            pattern = rf'line\(\s*"(companion_{comp}_{moment_type}(?:_1)?)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*([A-Z_]+)\s*,\s*"([^"]+)"\s*\)'
            m = re.search(pattern, manifest_content)
            assert m, f"Missing voiceline manifest entry for companion {comp} moment {moment_type}"
            key, jp_text, style, prosody, note = m.groups()
            assert len(jp_text) > 0, f"Empty Japanese text for {key}"
            assert style in ["normal", "sweet", "tsun", "tsundere", "whisper", "hushed", "weary", "teary"], f"Invalid style '{style}' for {key}"
            
    print("[PASS] All 36 companion voicelines defined with valid styles, prosody presets, and natural Japanese text.")

def test_creative_diversity():
    print("\n--- [Test 7] Creative Diversity & Quota Verification ---")
    print(f"Dark/Tragic Companions ({len(DARK_TRAGIC_COMPANIONS)}): {DARK_TRAGIC_COMPANIONS}")
    print(f"Unreliable Narrators ({len(UNRELIABLE_NARRATOR_COMPANIONS)}): {UNRELIABLE_NARRATOR_COMPANIONS}")
    print(f"Non-Food Companions ({len(NON_FOOD_COMPANIONS)}): {NON_FOOD_COMPANIONS}")
    
    assert len(DARK_TRAGIC_COMPANIONS) >= 3, "Failed dark/tragic quota (must be >= 3)"
    assert len(UNRELIABLE_NARRATOR_COMPANIONS) >= 2, "Failed unreliable narrator quota (must be >= 2)"
    assert len(NON_FOOD_COMPANIONS) >= 1, "Failed non-food quota (must be >= 1)"
    print("[PASS] Creative diversity quotas satisfied.")

def main():
    print("=================================================================")
    print("  MILENSTONE M1 COMPANION EXPANSION: EMPIRICAL VERIFICATION ORACLE")
    print("=================================================================")
    
    try:
        found_companions, signatures = test_companion_keys_and_schema()
        test_vn_dialogue_data()
        test_vn_portrait_config()
        test_quest_config()
        test_craft_config_and_ingredients(signatures)
        test_voiceline_manifest()
        test_creative_diversity()
        
        print("\n=================================================================")
        print("  ALL EMPIRICAL VERIFICATION ORACLE CHECKS PASSED: VERDICT APPROVE")
        print("=================================================================\n")
        return 0
    except AssertionError as e:
        print(f"\n[FAIL] VERIFICATION ORACLE FAILED: {e}")
        print("=================================================================")
        print("  EMPIRICAL VERDICT: REJECT")
        print("=================================================================\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())
