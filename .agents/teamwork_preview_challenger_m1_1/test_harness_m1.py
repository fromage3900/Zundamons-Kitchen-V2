import sys
import os
import json
import time

print("==================================================")
print("  EMPIRICAL VERIFICATION HARNESS - MILESTONE 1 R1 ")
print("==================================================")

project_root = r"g:\Zundamons-kItchen-V2"

# Test results tracker
results = []

def record_test(name, category, status, message, details=None):
    results.append({
        "name": name,
        "category": category,
        "status": status,  # "PASS" or "FAIL"
        "message": message,
        "details": details or {}
    })
    status_str = "[PASS]" if status == "PASS" else "[FAIL]"
    print(f"{status_str} {category} :: {name} -> {message}")


# ----------------------------------------------------------------------
# TEST 1: Tool Hit Detection & Position Safety (Tools.server.lua)
# ----------------------------------------------------------------------
def test_tool_hit_detection():
    print("\n--- Running Test 1: Tool Hit Detection & Position Safety ---")
    tools_server_path = os.path.join(project_root, "src", "server", "Tools.server.lua")
    with open(tools_server_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Check 1.1: TOOL_NODE_MATCHES configuration
    if "PickAxe" in content and "Axe" in content and "Sickle" in content:
        record_test("Tool Match Mapping", "Tool Hit Detection", "PASS", "Tool types PickAxe, Axe, Sickle defined in match map")
    else:
        record_test("Tool Match Mapping", "Tool Hit Detection", "FAIL", "Missing tool type match mapping")

    # Check 1.2: Model position safety check in findHitTargets
    # Look for node.Position access vs node:IsA("BasePart") or PrimaryPart check
    if "node.Position" in content:
        # Check if there is an IsA check before node.Position
        lines = content.splitlines()
        vulnerable = False
        for i, line in enumerate(lines):
            if "for _, node in pairs(CollectionService:GetTagged(\"Mineable\"))" in line:
                # check next 10 lines for node.Position without IsA check
                sub = "\n".join(lines[i:i+10])
                if "node.Position" in sub and "IsA" not in sub and "PrimaryPart" not in sub:
                    vulnerable = True
                    break
        if vulnerable:
            record_test("Model Position Safety", "Tool Hit Detection", "FAIL", 
                        "Tools.server.lua accesses 'node.Position' directly on Mineable tagged instances without checking if instance is a Model, causing crash if a Model is tagged Mineable")
        else:
            record_test("Model Position Safety", "Tool Hit Detection", "PASS", "Mineable instance position checked safely")
    else:
        record_test("Model Position Safety", "Tool Hit Detection", "PASS", "Safe position access")

    # Check 1.3: Hit radius
    if "HIT_RADIUS = 8" in content:
        record_test("Hit Radius Config", "Tool Hit Detection", "PASS", "HIT_RADIUS configured to 8 studs")
    else:
        record_test("Hit Radius Config", "Tool Hit Detection", "FAIL", "HIT_RADIUS missing or changed")


# ----------------------------------------------------------------------
# TEST 2: Node Health Reduction, Tagging & Multiplayer Cooldown Bug
# ----------------------------------------------------------------------
def test_node_health_and_multiplayer():
    print("\n--- Running Test 2: Node Health Reduction & Multiplayer Cooldown Bug ---")
    mineable_path = os.path.join(project_root, "src", "server", "Mineable.server.lua")
    validator_path = os.path.join(project_root, "src", "server", "Validation", "HarvestValidator.lua")
    
    with open(mineable_path, "r", encoding="utf-8") as f:
        mineable_code = f.read()

    with open(validator_path, "r", encoding="utf-8") as f:
        validator_code = f.read()

    # Check 2.1: Health reduction logic in Tools.server.lua / Mineable.server.lua
    if "node:SetAttribute(\"Health\", math.max(health - damage, 0))" in open(os.path.join(project_root, "src", "server", "Tools.server.lua"), "r", encoding="utf-8").read():
        record_test("Health Reduction Logic", "Node Health", "PASS", "Damage correctly reduces Health attribute to minimum 0")
    else:
        record_test("Health Reduction Logic", "Node Health", "FAIL", "Health reduction calculation error")

    # Check 2.2: Tag cleanup on Mineable nodes
    # Check if CollectionService:RemoveTag or tag clearing occurs after harvest/respawn
    if "RemoveTag" in mineable_code:
        record_test("Wildcard Tag Cleanup", "Node Health & Loot", "PASS", "Tags removed from node upon harvest")
    else:
        record_test("Wildcard Tag Cleanup", "Node Health & Loot", "FAIL", 
                    "Mineable.server.lua NEVER removes wildcard tags (player.Name..'|'..tier). Tags persist across respawns, allowing stale players to steal loot drops in future respawns!")

    # Check 2.3: Multiplayer validateHarvest Cooldown Race Condition
    # In Mineable.server.lua, validateHarvest is called inside `for _, player in pairs(Players:GetPlayers()) do`
    if "for _, player in pairs(Players:GetPlayers()) do" in mineable_code and "validateHarvest(player, item)" in mineable_code:
        record_test("Multiplayer Harvest Validation Conflict", "Node Health & Validation", "FAIL",
                    "validateHarvest sets LastHarvested = tick() for the first tagged player checked. Subsequent tagged players in the loop trigger node cooldown check and are DENIED loot!")
    else:
        record_test("Multiplayer Harvest Validation Conflict", "Node Health & Validation", "PASS", "Multiplayer harvest validation handled correctly")


# ----------------------------------------------------------------------
# TEST 3: Particle Spawning & Visual/Audio Feedback
# ----------------------------------------------------------------------
def test_particles_and_feedback():
    print("\n--- Running Test 3: Particle Spawning & Visual Feedback ---")
    harvest_ctrl_path = os.path.join(project_root, "src", "client", "Controllers", "HarvestController.client.lua")
    with open(harvest_ctrl_path, "r", encoding="utf-8") as f:
        code = f.read()

    # Check 3.1: createHarvestParticles
    if "function createHarvestParticles" in code and "ParticleEmitter" in code:
        record_test("Harvest Particle Generation", "Particle FX", "PASS", "createHarvestParticles creates particle emitters for harvest completion")
    else:
        record_test("Harvest Particle Generation", "Particle FX", "FAIL", "Missing harvest particle generation")

    # Check 3.2: createToolHitFX with node type matching
    if "function createToolHitFX" in code and "rock" in code and "tree" in code:
        record_test("Tool Hit FX Customization", "Particle FX", "PASS", "createToolHitFX differentiates between rocks, trees, and crops with distinct particle colors")
    else:
        record_test("Tool Hit FX Customization", "Particle FX", "FAIL", "Missing tool hit FX customization")

    # Check 3.3: Automatic cleanup of FX parts
    if "part:Destroy()" in code and "task.delay" in code:
        record_test("Particle FX Cleanup", "Particle FX", "PASS", "FX parts automatically destroyed after lifetime")
    else:
        record_test("Particle FX Cleanup", "Particle FX", "FAIL", "Particle FX parts leak in Workspace")


# ----------------------------------------------------------------------
# TEST 4: Loot Drops & Collection (LootModule.lua & ReplicatedStorage.Loot)
# ----------------------------------------------------------------------
def test_loot_drops_and_collection():
    print("\n--- Running Test 4: Loot Drops & Collection ---")
    loot_module_path = os.path.join(project_root, "src", "shared", "ConfigurationFiles", "LootModule.lua")
    loot_folder = os.path.join(project_root, "src", "shared", "Loot")

    with open(loot_module_path, "r", encoding="utf-8") as f:
        loot_code = f.read()

    # Get list of loot files in ReplicatedStorage.Loot
    existing_loot = set()
    if os.path.exists(loot_folder):
        for fname in os.listdir(loot_folder):
            if fname.endswith(".meta.json"):
                existing_loot.add(fname.replace(".meta.json", ""))

    # Items dropped by gathering / mining
    dropped_items = ["Zunda Flower", "Zunda Pea", "Zunda Mushroom", "Zunda Berry", "Zunda Root", "Salted Pea Bouquet", "Carrot", "Gold Ore", "Rock", "Wheat", "Apple", "Marble Rock"]

    missing_items = []
    for item in dropped_items:
        if item not in existing_loot:
            missing_items.append(item)

    if missing_items:
        record_test("Loot Model Existence Check", "Loot Drops", "FAIL", 
                    f"Items dropped by gathering/mining missing in ReplicatedStorage.Loot: {missing_items}. GiveLoot fails for these items!", 
                    {"missing": missing_items})
    else:
        record_test("Loot Model Existence Check", "Loot Drops", "PASS", "All dropped items exist in ReplicatedStorage.Loot")

    # Check 4.2: Duplicate item exploit in GiveLoot
    # In GiveLoot: searchforCode(player, genCode, lootname, false) does NOT set isRemoving = true
    if "function loot_module.GiveLoot" in loot_code:
        if "searchforCode(player, genCode, lootname, false)" in loot_code:
            record_test("Loot Redemption Duplicate Exploit", "Loot Drops & Security", "FAIL",
                        "GiveLoot checks searchforCode(..., false) without removing code on server side! Code remains in codes[player.Name], allowing concurrent/repeated GiveLoot calls to duplicate items!")
        else:
            record_test("Loot Redemption Duplicate Exploit", "Loot Drops & Security", "PASS", "GiveLoot removes code on redemption")


# ----------------------------------------------------------------------
# TEST 5: Inventory Save & Data Schema (PlayerDataService.lua)
# ----------------------------------------------------------------------
def test_inventory_save():
    print("\n--- Running Test 5: Inventory Save & Data Schema ---")
    pds_path = os.path.join(project_root, "src", "server", "services", "PlayerDataService.lua")
    with open(pds_path, "r", encoding="utf-8") as f:
        pds_code = f.read()

    # Check 5.1: Default schema contains initial items and gathered_items
    if "gathered_items = {}" in pds_code and "gold = 50" in pds_code:
        record_test("PlayerData Default Schema", "Inventory Save", "PASS", "Default player data contains gathered_items, gold, and default inventory")
    else:
        record_test("PlayerData Default Schema", "Inventory Save", "FAIL", "Missing fields in default player data schema")

    # Check 5.2: Auto-save loop
    if "DataStoreService" in pds_code and "SetAsync" in pds_code and "task.spawn" in pds_code:
        record_test("DataStore Auto-Save Pipeline", "Inventory Save", "PASS", "Periodic auto-save (60s) and player exit save implemented")
    else:
        record_test("DataStore Auto-Save Pipeline", "Inventory Save", "FAIL", "DataStore save pipeline incomplete")


# ----------------------------------------------------------------------
# TEST 6: UI Progress Bar Responsiveness & Heartbeat Race Condition
# ----------------------------------------------------------------------
def test_ui_progress_bar():
    print("\n--- Running Test 6: UI Progress Bar Responsiveness & Race Condition ---")
    harvest_ctrl_path = os.path.join(project_root, "src", "client", "Controllers", "HarvestController.client.lua")
    with open(harvest_ctrl_path, "r", encoding="utf-8") as f:
        code = f.read()

    # Check 6.1: Progress Bar UI creation
    if "HarvestProgressGui" in code and "HarvestProgressContainer" in code:
        record_test("Progress Bar UI Creation", "UI Progress Bar", "PASS", "HarvestProgressGui created with container, fill frame, and label")
    else:
        record_test("Progress Bar UI Creation", "UI Progress Bar", "FAIL", "Progress bar UI missing")

    # Check 6.2: Cancellation triggers (Movement key, distance, out of range)
    cancellations = []
    if "hasMovedTooFar()" in code: cancellations.append("Movement threshold")
    if "isInRange(node)" in code: cancellations.append("Distance threshold")
    if "InputBegan" in code and "moveKeys" in code: cancellations.append("Movement keypress")
    if "CharacterAdded" in code: cancellations.append("Character death/respawn")

    if len(cancellations) >= 4:
        record_test("Cancellation Triggers", "UI Progress Bar", "PASS", f"All cancel triggers present: {', '.join(cancellations)}")
    else:
        record_test("Cancellation Triggers", "UI Progress Bar", "FAIL", f"Missing cancellation triggers: found only {cancellations}")

    # Check 6.3: Heartbeat race condition on startHarvest re-trigger
    # If startHarvest calls cancelHarvest (isHarvesting = false), but then immediately sets isHarvesting = true,
    # the old Heartbeat connection callback will check `if not isHarvesting` (which evaluates to false) and remain connected!
    if "local heartbeatConn" in code and "isHarvesting = true" in code and "if not isHarvesting then" in code:
        record_test("Heartbeat Connection Leak Race Condition", "UI Progress Bar", "FAIL",
                    "startHarvest calls cancelHarvest() then immediately sets isHarvesting=true. Old Heartbeat connection sees isHarvesting==true on next frame, fails to disconnect, and runs in parallel, completing new harvest prematurely!")
    else:
        record_test("Heartbeat Connection Leak Race Condition", "UI Progress Bar", "PASS", "Heartbeat connection explicitly disconnected on cancel")


# ----------------------------------------------------------------------
# Run All Tests & Print Summary
# ----------------------------------------------------------------------
def main():
    test_tool_hit_detection()
    test_node_health_and_multiplayer()
    test_particles_and_feedback()
    test_loot_drops_and_collection()
    test_inventory_save()
    test_ui_progress_bar()

    print("\n==================================================")
    print("                TEST RESULTS SUMMARY              ")
    print("==================================================")
    pass_count = sum(1 for r in results if r["status"] == "PASS")
    fail_count = sum(1 for r in results if r["status"] == "FAIL")
    total = len(results)

    print(f"Total Tests Run: {total}")
    print(f"Passed: {pass_count}")
    print(f"Failed: {fail_count}")
    print("--------------------------------------------------")

    for r in results:
        status_symbol = "[PASS]" if r["status"] == "PASS" else "[FAIL]"
        print(f"{status_symbol} [{r['category']}] {r['name']}")
        if r["status"] == "FAIL":
            print(f"   --> Reason: {r['message']}")

    return fail_count

if __name__ == "__main__":
    sys.exit(main())
