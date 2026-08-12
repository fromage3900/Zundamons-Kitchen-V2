#!/usr/bin/env python3
"""Cross-reference audit for gameplay configs. Runs in CI (see .github/workflows/ci.yml).

Catches the config-vs-config bug classes that static gates miss:
  * ScatterConfig variants not existing in ResourceVisualCatalog
  * ScatterConfig resourceTypes not resolvable in ResourceNodeRegistry
  * variantWeights length != variants length
  * MineableConfig.Mineables ids not registered as archetypes
  * ResourceVisualCatalog defaults pointing at unknown variants / disabled entries
  * AGENTS-listed production remotes never declared in src/

Exit code 0 = clean, 1 = violations (blocks CI).
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

issues = []


def catalog_variants() -> dict:
    """variant -> enabled bool"""
    text = (SRC / "shared/ConfigurationFiles/ResourceVisualCatalog.lua").read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'register\("([^"]+)",\s*"rbxassetid://(\d+)",\s*"(\w+)",\s*(true|false)\)', text):
        out[m.group(1)] = {
            "id": m.group(2),
            "type": m.group(3),
            "enabled": m.group(4) == "true",
        }
    return out


def catalog_defaults(text: str) -> dict:
    m = re.search(r"defaultsByArchetype:.*?=\s*\{(.*?)\n\}", text, re.DOTALL)
    if not m:
        return {}
    out = {}
    for k, v in re.findall(r'(\w+|\["[^"]+"\])\s*=\s*"([^"]+)"', m.group(1)):
        out[k.strip('"[]')] = v
    return out


def scatter_entries() -> list:
    text = (SRC / "shared/ConfigurationFiles/ScatterConfig.lua").read_text(encoding="utf-8")
    resource_types = re.findall(r'resourceType\s*=\s*"([^"]+)"', text)
    variants = re.findall(r'variants\s*=\s*\{(.*?)\}', text, re.DOTALL)
    weights = re.findall(r'variantWeights\s*=\s*\{(.*?)\}', text, re.DOTALL)
    names = re.findall(r'(\w+|\["[^"]+"\])\s*=\s*\{', text)
    node_names = [n.strip('"[]') for n in names if n.strip('"[]') not in {"biomes", "node_types", "exclusion_tags"}][:]
    entries = []
    for i, rt in enumerate(resource_types):
        vs = re.findall(r'"([^"]+)"', variants[i] if i < len(variants) else "")
        ws = re.findall(r'([\d.]+)', weights[i] if i < len(weights) else "")
        entries.append({"index": i, "resourceType": rt, "variants": vs, "weights": ws})
    return entries


def registry_ids() -> set:
    text = (SRC / "shared/ConfigurationFiles/ResourceNodeRegistry.lua").read_text(encoding="utf-8")
    ids = set()
    for m in re.finditer(r'\{\s*"(\w+)",\s*"(\w+)",\s*"((?:[A-Za-z]|\s)+)"\s*\}', text):
        ids.add(m.group(1))
        ids.add(m.group(3).strip())
    gather = (SRC / "shared/ConfigurationFiles/GatherConfig.lua").read_text(encoding="utf-8")
    m = re.search(r"clickResources\s*=\s*\{(.*?)\n\}", gather, re.DOTALL)
    if m:
        for k in re.findall(r'^\t(\w+|\["[^"]+"\])\s*=\s*\{', m.group(1), re.MULTILINE):
            ids.add(k.strip('"[]'))
    return ids


def mineable_ids() -> set:
    text = (SRC / "shared/ConfigurationFiles/MineableConfig.lua").read_text(encoding="utf-8")
    m = re.search(r"Mineables\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
    return {k.strip('"[]') for k in re.findall(r'^\t(\w+|\["[^"]+"\])\s*=\s*\{', m.group(1), re.MULTILINE)} if m else set()


def main() -> int:
    variants = catalog_variants()
    defaults = catalog_defaults((SRC / "shared/ConfigurationFiles/ResourceVisualCatalog.lua").read_text(encoding="utf-8"))

    # 1. Catalog self-consistency
    for variant, info in sorted(variants.items()):
        if not info["enabled"]:
            issues.append(f"ResourceVisualCatalog: '{variant}' is disabled — scatter/archtypes defaulting to it fall back to boxes")
    for arch, variant in sorted(defaults.items()):
        if variant not in variants:
            issues.append(f"ResourceVisualCatalog defaultsByArchetype: '{arch}' -> '{variant}' does not exist")
        elif not variants[variant]["enabled"]:
            issues.append(f"ResourceVisualCatalog defaultsByArchetype: '{arch}' -> '{variant}' is disabled")

    # 2. ScatterConfig vs catalog + registry
    registry = registry_ids()
    for e in scatter_entries():
        if e["resourceType"] not in registry:
            issues.append(f"ScatterConfig entry #{e['index']}: resourceType '{e['resourceType']}' not registered in ResourceNodeRegistry")
        for v in e["variants"]:
            if v not in variants:
                issues.append(f"ScatterConfig entry #{e['index']} ('{e['resourceType']}'): variant '{v}' not in ResourceVisualCatalog")
            elif not variants[v]["enabled"]:
                issues.append(f"ScatterConfig entry #{e['index']} ('{e['resourceType']}'): variant '{v}' is disabled in catalog")
        if len(e["variants"]) != len(e["weights"]):
            issues.append(
                f"ScatterConfig entry #{e['index']} ('{e['resourceType']}'): "
                f"{len(e['variants'])} variants vs {len(e['weights'])} weights"
            )

    # 3. MineableConfig ids vs registry
    for mid in sorted(mineable_ids()):
        if mid not in registry:
            issues.append(f"MineableConfig.Mineables: '{mid}' not registered in ResourceNodeRegistry")

    # 4. AGENTS-listed production remotes must be declared somewhere in src/
    required_remotes = [
        "ChallengeMode",
        "ChallengeModeStatus",
        "DailyChallenge",
        "DailyChallengeStatus",
        "ChefStatsUpdate",
        "StylePointsUpdate",
        "OutfitUnlock",
    ]
    all_src = "".join(
        p.read_text(encoding="utf-8", errors="ignore")
        for p in SRC.rglob("*")
        if p.is_file() and p.suffix in {".lua", ".luau"}
    )
    for remote in required_remotes:
        if f'"{remote}"' not in all_src:
            issues.append(f"Remote '{remote}' (AGENTS-listed) is never declared in src/")

    if issues:
        print(f"check_config_crossrefs: {len(issues)} violation(s)")
        for issue in issues:
            print(f"  - {issue}")
        return 1
    print("check_config_crossrefs: OK — catalog, scatter, registry, mineables, remotes in sync")
    return 0


if __name__ == "__main__":
    sys.exit(main())