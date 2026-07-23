import sys
import os
import re
import subprocess
import json
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# Paths
ROOT_DIR = Path(r"g:\Zundamons-kItchen-V2")
COMPANION_CONFIG = ROOT_DIR / "src" / "shared" / "ConfigurationFiles" / "CompanionConfig.lua"
MARKETPLACE_CONFIG = ROOT_DIR / "src" / "shared" / "ConfigurationFiles" / "MarketplaceConfig.lua"
COMPANION_MANAGER = ROOT_DIR / "src" / "server" / "CompanionManager.server.lua"
COMPANION_HUD = ROOT_DIR / "src" / "client" / "CompanionHUD.client.lua"
COMPANION_SHOP_SERVER = ROOT_DIR / "src" / "server" / "CompanionShopServer.server.lua"
PREFLIGHT_SCRIPT = ROOT_DIR / "scripts" / "preflight_audit.py"

results = {
    "task1_companion_config": {"status": "FAIL", "details": []},
    "task2_preflight_audit": {"status": "FAIL", "details": []},
    "task3_edge_cases": {"status": "FAIL", "details": []},
    "task4_marketplace_id_alignment": {"status": "FAIL", "details": []}
}

print("=== STARTING EMPIRICAL VERIFICATION FOR MILESTONE 1 ===")

# ---------------------------------------------------------
# TASK 1: Programmatic Verification of CompanionConfig.lua
# ---------------------------------------------------------
print("\n--- TASK 1: Programmatic Verification of CompanionConfig.lua ---")

with open(COMPANION_CONFIG, "r", encoding="utf-8") as f:
    config_text = f.read()

target_companions = [
    "parrot", "dog", "cat", "ankomon", 
    "cardamon", "antimon", "sakuradamon", "tantanmon"
]
all_companions = target_companions + ["zundapal"]

comp_block_match = re.search(r"CompanionConfig\.companions\s*=\s*\{([\s\S]*?)\n\}", config_text)
if not comp_block_match:
    results["task1_companion_config"]["details"].append("ERROR: Could not locate CompanionConfig.companions block.")
else:
    comp_block = comp_block_match.group(1)
    top_keys = re.findall(r"^\t([a-zA-Z0-9_]+)\s*=\s*\{", comp_block, re.MULTILINE)
    print(f"Top-level companion keys in CompanionConfig.companions: {top_keys}")
    
    missing_target = [c for c in target_companions if c not in top_keys]
    if missing_target:
        results["task1_companion_config"]["details"].append(f"MISSING TARGET COMPANIONS: {missing_target}")
    else:
        results["task1_companion_config"]["details"].append(f"All 8 target companions present: {target_companions}")

    for comp in all_companions:
        pattern = rf"\t{comp}\s*=\s*\{{([\s\S]*?)\n\t\}},?"
        match = re.search(pattern, comp_block)

        if match:
            entry_str = match.group(1)
            emoji = re.search(r'emoji\s*=\s*"([^"]+)"', entry_str)
            glow = re.search(r'glow\s*=\s*Color3\.fromRGB\(([^)]+)\)', entry_str)
            glow_range = re.search(r'glowRange\s*=\s*(\d+)', entry_str)
            free = re.search(r'free\s*=\s*(true|false)', entry_str)
            price = re.search(r'price\s*=\s*(\d+)', entry_str)
            display_name = re.search(r'displayName\s*=\s*"([^"]+)"', entry_str)
            flavor = re.search(r'flavor\s*=\s*"([^"]+)"', entry_str)
            llm_persona = re.search(r'llmPersona\s*=\s*"([^"]+)"', entry_str)
            buff = re.search(r'buff\s*=\s*(nil|\{[^}]+\})', entry_str)

            attrs = {
                "emoji": emoji.group(1) if emoji else None,
                "glow": glow.group(1) if glow else None,
                "glowRange": int(glow_range.group(1)) if glow_range else None,
                "free": free.group(1) == "true" if free else None,
                "price": int(price.group(1)) if price else None,
                "displayName": display_name.group(1) if display_name else None,
                "flavor": flavor.group(1) if flavor else None,
                "llmPersona": llm_persona.group(1) if llm_persona else None,
                "has_buff": buff.group(1) != "nil" if buff else False
            }
            
            missing_attrs = [k for k, v in attrs.items() if v is None]
            if missing_attrs:
                results["task1_companion_config"]["details"].append(f"Companion '{comp}' missing attributes: {missing_attrs}")
            else:
                print(f"  [OK] {comp}: displayName='{attrs['displayName']}', free={attrs['free']}, price={attrs['price']}, buff={attrs['has_buff']}")
        else:
            results["task1_companion_config"]["details"].append(f"Failed to match block for companion '{comp}'")

    if len(missing_target) == 0 and all(c in top_keys for c in all_companions):
        results["task1_companion_config"]["status"] = "PASS"

# ---------------------------------------------------------
# TASK 2: Run python scripts/preflight_audit.py
# ---------------------------------------------------------
print("\n--- TASK 2: Running scripts/preflight_audit.py ---")
try:
    proc = subprocess.run([sys.executable, str(PREFLIGHT_SCRIPT)], capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=str(ROOT_DIR))
    print("Preflight audit stdout:\n", proc.stdout)
    if proc.returncode == 0 and "ALL PREFLIGHT AUDITS PASSED" in proc.stdout:
        results["task2_preflight_audit"]["status"] = "PASS"
        results["task2_preflight_audit"]["details"].append("preflight_audit.py passed cleanly with exit code 0.")
    else:
        results["task2_preflight_audit"]["details"].append(f"preflight_audit.py failed with exit code {proc.returncode}. Stderr: {proc.stderr}")
except Exception as e:
    results["task2_preflight_audit"]["details"].append(f"Exception running preflight_audit.py: {e}")

# ---------------------------------------------------------
# TASK 3: Edge Case Testing
# ---------------------------------------------------------
print("\n--- TASK 3: Testing Edge Cases ---")

# Edge Case 3A: Invalid key queried in CompanionConfig and code fallbacks
print("\n[Edge Case 3A]: Invalid Key Queries")
get_comp_match = re.search(r"function CompanionConfig\.getCompanion\(compType: string\)[\s\S]*?return CompanionConfig\.companions\[compType\] or CompanionConfig\.companions\.zundapal[\s\S]*?end", config_text)
if get_comp_match:
    print("  [OK] CompanionConfig.getCompanion handles invalid keys properly by falling back to CompanionConfig.companions.zundapal.")
else:
    results["task3_edge_cases"]["details"].append("WARNING: CompanionConfig.getCompanion fallback definition not found or different.")

# Check CompanionManager.server.lua line 173 fallback
with open(COMPANION_MANAGER, "r", encoding="utf-8") as f:
    cm_text = f.read()

cm_fallback_match = re.search(r"local def = COMPANIONS\[compType\] or COMPANIONS\.zundamon", cm_text)
if cm_fallback_match:
    bug_msg = "CRITICAL BUG: CompanionManager.server.lua line 173 fallback is 'COMPANIONS.zundamon', but CompanionConfig key is 'zundapal'! Indexing invalid key sets def=nil and CRASHES buildCompanion!"
    print("  [FAIL] " + bug_msg)
    results["task3_edge_cases"]["details"].append(bug_msg)

# Check CompanionHUD.client.lua line 63 fallback
with open(COMPANION_HUD, "r", encoding="utf-8") as f:
    ch_text = f.read()

ch_fallback_match = re.search(r"local def = COMPANIONS\[compType\] or COMPANIONS\.zundamon", ch_text)
if ch_fallback_match:
    bug_msg = "CRITICAL BUG: CompanionHUD.client.lua line 63 fallback is 'COMPANIONS.zundamon', but CompanionConfig key is 'zundapal'! Indexing invalid key sets def=nil and CRASHES HUD update!"
    print("  [FAIL] " + bug_msg)
    results["task3_edge_cases"]["details"].append(bug_msg)

# Edge Case 3B: Missing/nil player data in GetOwnedCompanions
print("\n[Edge Case 3B]: Missing/Nil Player Data in GetOwnedCompanions")
with open(COMPANION_SHOP_SERVER, "r", encoding="utf-8") as f:
    css_text = f.read()

get_owned_match = re.search(r"GetOwnedCompanions\.OnServerInvoke = function\(player\)([\s\S]*?)end", css_text)
if get_owned_match:
    code = get_owned_match.group(1)
    if "local data = PlayerDataService.get(player)" in code:
        if re.search(r"if data then[\s\S]*?owned\.__active =", code):
            warn_msg = "MINOR BUG: GetOwnedCompanions sets owned.__active inside 'if data then'. If PlayerDataService.get(player) returns nil, owned.__active is nil instead of falling back to 'zundapal'."
            print("  [WARN] " + warn_msg)
            results["task3_edge_cases"]["details"].append(warn_msg)
        else:
            print("  [OK] owned.__active fallback is set properly.")

if len(results["task3_edge_cases"]["details"]) == 0:
    results["task3_edge_cases"]["status"] = "PASS"
else:
    results["task3_edge_cases"]["status"] = "FAIL"

# ---------------------------------------------------------
# TASK 4: Verify ID Alignment across MarketplaceConfig
# ---------------------------------------------------------
print("\n--- TASK 4: MarketplaceConfig ID Alignment ---")
with open(MARKETPLACE_CONFIG, "r", encoding="utf-8") as f:
    mc_text = f.read()

products = {}
prod_matches = re.findall(r'\[(\d+)\]\s*=\s*\{\s*type\s*=\s*"([^"]+)",\s*key\s*=\s*"([^"]+)",\s*name\s*=\s*"([^"]+)"\s*\}', mc_text)
for pid, ptype, pkey, pname in prod_matches:
    products[int(pid)] = {"type": ptype, "key": pkey, "name": pname}

dev_product_ids = {}
dev_matches = re.findall(r'([a-zA-Z0-9_]+)\s*=\s*(\d+),', mc_text)
for ckey, pid in dev_matches:
    if ckey in ["cardamon", "antimon", "sakuradamon", "tantanmon"]:
        dev_product_ids[ckey] = int(pid)

store_companions = []
store_matches = re.findall(r'\{\s*id\s*=\s*(\d+)[^}]*key\s*=\s*"([^"]+)"', mc_text)
for pid, ckey in store_matches:
    store_companions.append({"id": int(pid), "key": ckey})

alignment_errors = []
paid_companions = ["cardamon", "antimon", "sakuradamon", "tantanmon"]

for comp in paid_companions:
    dev_pid = dev_product_ids.get(comp)
    if not dev_pid:
        alignment_errors.append(f"Companion '{comp}' missing from companionDevProductIds")
        continue

    prod_entry = products.get(dev_pid)
    if not prod_entry:
        alignment_errors.append(f"DevProduct ID {dev_pid} for companion '{comp}' not found in products table")
    elif prod_entry["key"] != comp or prod_entry["type"] != "companion":
        alignment_errors.append(f"Product ID {dev_pid} mismatch in products table: expected key '{comp}', type 'companion', got {prod_entry}")

    store_entry = next((item for item in store_companions if item["key"] == comp), None)
    if not store_entry:
        alignment_errors.append(f"Companion '{comp}' missing from storeDisplay.companions")
    elif store_entry["id"] != dev_pid:
        alignment_errors.append(f"ID mismatch for '{comp}': devProductId={dev_pid}, storeDisplay.id={store_entry['id']}")

if alignment_errors:
    print("❌ Marketplace ID Alignment Errors Found:")
    for err in alignment_errors:
        print("  - " + err)
        results["task4_marketplace_id_alignment"]["details"].append(err)
else:
    print("  [OK] All DevProduct IDs and keys perfectly aligned across products, companionDevProductIds, and storeDisplay.companions!")
    results["task4_marketplace_id_alignment"]["status"] = "PASS"

print("\n=== FINAL TEST RESULTS SUMMARY ===")
print(json.dumps(results, indent=2))
