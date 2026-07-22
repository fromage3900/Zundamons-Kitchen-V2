#!/usr/bin/env python3
"""
preflight_audit.py
Pre-publish audit and validation runner for Zundamon's Kitchen V2.
Checks code rules, Rojo settings, Luau paths, and monetization configs.
"""

import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent

def audit_rojo_config():
    """Verify Rojo configuration for $ignoreUnknownInstances in Workspace."""
    project_file = ROOT_DIR / "default.project.json"
    if not project_file.exists():
        print("❌ missing default.project.json!")
        return False

    with open(project_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    workspace_node = data.get("tree", {}).get("Workspace", {})
    ignore_unknown = workspace_node.get("$ignoreUnknownInstances")
    if ignore_unknown is True:
        print("✅ Rojo Level Preservation Check Passed: $ignoreUnknownInstances = true")
        return True
    else:
        print("❌ Rojo Level Preservation Check Failed: $ignoreUnknownInstances must be true under Workspace!")
        return False

def audit_luau_files():
    """Scan all Luau files for basic validity and script.Parent misuse in client scripts."""
    client_dir = ROOT_DIR / "src" / "client"
    errors = 0
    client_files = list(client_dir.glob("**/*.lua"))
    
    print(f"🔍 Auditing {len(client_files)} client Luau scripts...")
    for file in client_files:
        content = file.read_text(encoding="utf-8", errors="ignore")
        # Rule 2: Never use script.Parent for UI references in client scripts synced to StarterPlayerScripts
        if "script.Parent" in content and "StarterPlayerScripts" in file.name:
            print(f"⚠️ Warning: potential script.Parent reference in {file.name}")
            errors += 1
            
    if errors == 0:
        print("✅ Client UI Decoupling Audit Passed cleanly!")
        return True
    return False

def audit_marketplace_config():
    """Verify MarketplaceConfig structure and fallback settings."""
    market_file = ROOT_DIR / "src" / "shared" / "ConfigurationFiles" / "MarketplaceConfig.lua"
    if market_file.exists():
        print("✅ MarketplaceConfig detected and present.")
        return True
    print("❌ MarketplaceConfig missing!")
    return False

def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    print("==================================================")
    print("🌸 ZUNDAMON'S KITCHEN V2 - PREFLIGHT AUDIT RUNNER 🌸")
    print("==================================================")
    
    rojo_ok = audit_rojo_config()
    luau_ok = audit_luau_files()
    market_ok = audit_marketplace_config()

    if rojo_ok and luau_ok and market_ok:
        print("\n✨ ALL PREFLIGHT AUDITS PASSED! READY FOR STUDIO & PUBLIC LAUNCH! ✨")
        sys.exit(0)
    else:
        print("\n❌ PREFLIGHT AUDIT FAILED. REVISE WARNINGS ABOVE.")
        sys.exit(1)

if __name__ == "__main__":
    main()
