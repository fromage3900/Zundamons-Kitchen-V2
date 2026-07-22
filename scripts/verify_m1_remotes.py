#!/usr/bin/env python3
import os
import re

SRC_DIR = r"g:\Zundamons-kItchen-V2\src"

def check_remotes():
    print("=== EMPIRICAL STRESS TEST FOR MILESTONE 1 REMOTES ===")
    
    files_to_check = []
    for root, _, files in os.walk(SRC_DIR):
        for f in files:
            if f.endswith(".lua"):
                files_to_check.append(os.path.join(root, f))
                
    remote_creations = {}
    remote_fires = {}
    remote_listens = {}
    
    for path in files_to_check:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
            rel_path = os.path.relpath(path, SRC_DIR)
            
            # Check ShowVNDialogue
            if "ShowVNDialogue" in content:
                print(f"[ShowVNDialogue] Found reference in {rel_path}")
            # Check GiveLoot / sellLoot
            if "GiveLoot" in content or "sellLoot" in content:
                print(f"[GiveLoot/sellLoot] Found reference in {rel_path}")
            # Check ChefStatsUpdate / StylePointsUpdate / OutfitUnlock
            for rName in ["ChefStatsUpdate", "StylePointsUpdate", "OutfitUnlock"]:
                if rName in content:
                    print(f"[{rName}] Found reference in {rel_path}")
                    if "FireClient" in content or "FireAllClients" in content:
                        print(f"  -> FIRED in {rel_path}")

if __name__ == "__main__":
    check_remotes()
