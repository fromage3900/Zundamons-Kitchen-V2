import re
import os
import sys

REPO_ROOT = r"g:\Zundamons-kItchen-V2"

def verify_task_1():
    print("--- TASK 1: MarketplaceConfig Product Mapping ---")
    mconfig_path = os.path.join(REPO_ROOT, "src", "shared", "ConfigurationFiles", "MarketplaceConfig.lua")
    with open(mconfig_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract products table entries
    # [1111111101] = { type = "companion", key = "cardamon", name = "Cardamon Companion" },
    products_matches = re.findall(r'\[(\d+)\]\s*=\s*\{\s*type\s*=\s*"([^"]+)",\s*key\s*=\s*"([^"]+)",\s*name\s*=\s*"([^"]+)"\s*\}', content)
    
    product_ids = [int(p[0]) for p in products_matches]
    print(f"Found {len(product_ids)} products in MarketplaceConfig.products:")
    for pid, ptype, pkey, pname in products_matches:
        print(f"  ID {pid}: type={ptype}, key={pkey}, name={pname}")

    # Check 1: Unique product IDs
    duplicates = [pid for pid in set(product_ids) if product_ids.count(pid) > 1]
    assert len(duplicates) == 0, f"FAIL: Duplicate product IDs found in products: {duplicates}"
    print("  [PASS] All product IDs in MarketplaceConfig.products are unique!")

    # Check 2: companionDevProductIds table
    devprod_block = re.search(r'MarketplaceConfig\.companionDevProductIds\s*=\s*\{([^}]+)\}', content)
    assert devprod_block is not None, "FAIL: companionDevProductIds not found"
    devprod_matches = re.findall(r'([a-zA-Z0-9_]+)\s*=\s*(\d+)', devprod_block.group(1))
    
    devprod_dict = {k: int(v) for k, v in devprod_matches}
    print("companionDevProductIds mapping:", devprod_dict)

    expected_devprods = {
        "cardamon": 1111111101,
        "antimon": 1111111102,
        "sakuradamon": 1111111103,
        "tantanmon": 1111111104,
    }
    assert devprod_dict == expected_devprods, f"FAIL: companionDevProductIds mismatch. Expected {expected_devprods}, got {devprod_dict}"
    print("  [PASS] companionDevProductIds correctly mapped to canonical premium companions!")

    # Check 3: Check consistency between products catalog and companionDevProductIds
    for comp_key, pid in devprod_dict.items():
        matched = [p for p in products_matches if int(p[0]) == pid]
        assert len(matched) == 1, f"FAIL: product ID {pid} for {comp_key} not in products table"
        assert matched[0][2] == comp_key, f"FAIL: products key for ID {pid} is {matched[0][2]}, expected {comp_key}"
        assert matched[0][1] == "companion", f"FAIL: product type for ID {pid} is {matched[0][1]}, expected 'companion'"
    print("  [PASS] Products table and companionDevProductIds are perfectly aligned!")
    return True

def verify_task_2():
    print("\n--- TASK 2: CompanionShopScript TAB_ORDER Verification ---")
    comp_config_path = os.path.join(REPO_ROOT, "src", "shared", "ConfigurationFiles", "CompanionConfig.lua")
    shop_script_path = os.path.join(REPO_ROOT, "src", "client", "CompanionShopScript.client.lua")

    with open(comp_config_path, "r", encoding="utf-8") as f:
        comp_content = f.read()

    with open(shop_script_path, "r", encoding="utf-8") as f:
        shop_content = f.read()

    # Extract keys like zundapal = {, dog = {, etc. inside CompanionConfig.companions
    comp_block = re.search(r'CompanionConfig\.companions\s*=\s*\{([\s\S]+?)\n\}', comp_content)
    assert comp_block is not None, "FAIL: CompanionConfig.companions table not found"
    
    active_companions = re.findall(r'^\t([a-zA-Z0-9_]+)\s*=\s*\{', comp_block.group(1), re.MULTILINE)
    print(f"Active companions in CompanionConfig.lua ({len(active_companions)}): {active_companions}")

    # Extract TAB_ORDER from CompanionShopScript.client.lua
    tab_order_match = re.search(r'local\s+TAB_ORDER\s*=\s*\{([^}]+)\}', shop_content)
    assert tab_order_match is not None, "FAIL: TAB_ORDER not found in CompanionShopScript.client.lua"
    
    tab_order = re.findall(r'"([^"]+)"', tab_order_match.group(1))
    print(f"TAB_ORDER in CompanionShopScript.client.lua ({len(tab_order)}): {tab_order}")

    # Check 2a: No duplicates in TAB_ORDER
    duplicates = [k for k in set(tab_order) if tab_order.count(k) > 1]
    assert len(duplicates) == 0, f"FAIL: Duplicate companion keys in TAB_ORDER: {duplicates}"
    print("  [PASS] No duplicate entries in TAB_ORDER.")

    # Check 2b: All active companions in TAB_ORDER
    missing = set(active_companions) - set(tab_order)
    assert len(missing) == 0, f"FAIL: Active companions missing from TAB_ORDER: {missing}"
    print("  [PASS] TAB_ORDER contains all active companions.")

    # Check 2c: No obsolete entries in TAB_ORDER
    obsolete = set(tab_order) - set(active_companions)
    assert len(obsolete) == 0, f"FAIL: Obsolete entries found in TAB_ORDER: {obsolete}"
    print("  [PASS] No obsolete entries in TAB_ORDER.")

    return True

def verify_task_3():
    print("\n--- TASK 3: StoreScript FREE_COMPANIONS Match ---")
    comp_config_path = os.path.join(REPO_ROOT, "src", "shared", "ConfigurationFiles", "CompanionConfig.lua")
    store_script_path = os.path.join(REPO_ROOT, "src", "client", "StoreScript.client.lua")

    with open(comp_config_path, "r", encoding="utf-8") as f:
        comp_content = f.read()

    with open(store_script_path, "r", encoding="utf-8") as f:
        store_content = f.read()

    # Parse CompanionConfig.companions block line by line to split top-level companion definitions
    comp_block_match = re.search(r'CompanionConfig\.companions\s*=\s*\{([\s\S]+?)\n\}', comp_content)
    assert comp_block_match is not None, "FAIL: CompanionConfig.companions block not found"
    comp_block = comp_block_match.group(1)

    # Split by lines starting with '\tkey = {'
    sections = re.split(r'^\t([a-zA-Z0-9_]+)\s*=\s*\{', comp_block, flags=re.MULTILINE)
    
    free_comps_config = []
    # sections will be [preamble, key1, body1, key2, body2, ...]
    for i in range(1, len(sections), 2):
        key = sections[i]
        body = sections[i+1]
        if re.search(r'free\s*=\s*true', body):
            free_comps_config.append(key)

    print(f"Free companions in CompanionConfig.lua ({len(free_comps_config)}): {free_comps_config}")

    # Extract FREE_COMPANIONS from StoreScript.client.lua
    free_block = re.search(r'local\s+FREE_COMPANIONS\s*=\s*\{([\s\S]+?)\n\}', store_content)
    assert free_block is not None, "FAIL: FREE_COMPANIONS not found in StoreScript.client.lua"
    
    free_keys_store = re.findall(r'key\s*=\s*"([^"]+)"', free_block.group(1))
    print(f"FREE_COMPANIONS in StoreScript.client.lua ({len(free_keys_store)}): {free_keys_store}")

    # Check equality of sets
    assert set(free_comps_config) == set(free_keys_store), (
        f"FAIL: Mismatch between CompanionConfig free companions {free_comps_config} and StoreScript FREE_COMPANIONS {free_keys_store}"
    )
    print("  [PASS] StoreScript.client.lua FREE_COMPANIONS matches CompanionConfig free==true list perfectly!")
    return True

def verify_task_4():
    print("\n--- TASK 4: Legacy Keys Audit (zundacat, zundabunny) ---")
    src_dir = os.path.join(REPO_ROOT, "src")
    
    server_client_files = []
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith(".lua"):
                server_client_files.append(os.path.join(root, file))

    print(f"Audited {len(server_client_files)} Lua files under src/.")

    # Check shop/companion runtime files specifically
    shop_runtime_files = [
        os.path.join("src", "client", "CompanionShopScript.client.lua"),
        os.path.join("src", "client", "StoreScript.client.lua"),
        os.path.join("src", "server", "CompanionShopServer.server.lua"),
        os.path.join("src", "server", "CompanionManager.server.lua"),
        os.path.join("src", "shared", "ConfigurationFiles", "CompanionConfig.lua"),
        os.path.join("src", "shared", "ConfigurationFiles", "MarketplaceConfig.lua"),
    ]
    
    shop_legacy_bugs = []
    for rel_path in shop_runtime_files:
        full_path = os.path.join(REPO_ROOT, rel_path)
        with open(full_path, "r", encoding="utf-8") as f:
            c = f.read()
        for lk in ["zundacat", "zundabunny"]:
            if lk in c:
                shop_legacy_bugs.append((rel_path, lk))

    assert len(shop_legacy_bugs) == 0, f"FAIL: Legacy keys found in shop runtime files: {shop_legacy_bugs}"
    print("  [PASS] 0 legacy keys found in shop/companion runtime files (CompanionShopScript, StoreScript, CompanionShopServer, CompanionConfig, MarketplaceConfig)!")

    return True

def main():
    t1 = verify_task_1()
    t2 = verify_task_2()
    t3 = verify_task_3()
    t4 = verify_task_4()
    
    if t1 and t2 and t3 and t4:
        print("\n==========================================")
        print("ALL VERIFICATION CHECKS PASSED: VERIFIED")
        print("==========================================")

if __name__ == "__main__":
    main()
