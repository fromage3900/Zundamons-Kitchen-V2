#!/usr/bin/env python3
"""
Quest Worker — Zundamon's Kitchen V2

Reads existing QuestConfig.lua quests as research, uses Zundamon's persona
as a style template, and generates new quests via Ollama.

Output: Lua-formatted quest entries for QuestConfig.lua

Usage:
    python scripts/ollama_quest_worker.py [--count 5] [--model llama3.1:8b]
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from ollama_client import OllamaClient, ZUNDAMON_PERSONA, create_worker

PROJECT_ROOT = Path(__file__).parent.parent
OUTPUT_DIR = PROJECT_ROOT / "scripts" / "ollama_output"

# Quest types from the existing QuestConfig
QUEST_TYPES = [
    "serve", "cook", "gather", "earn_gold", "cook_perfect", "cook_great",
    "companion_chat", "companion_affection", "visit_zone", "visit_zones_unique",
    "npc_chat", "cook_unique", "cook_unique_zunda", "cook_quality", "cook_speed",
    "cook_unique_seasonal", "gather_unique", "set_companion", "npc_chat_all",
    "zundarooms_escape", "challenge_wave", "daily_complete", "reputation_tier",
    "style_points", "outfit_collect",
]

# Companion names for companion-specific quests
COMPANIONS = [
    "Ankomon", "Cardamon", "Antimon", "Sakuradamon",
    "Zundapal", "Zundacat", "Zundabunny", "Tantanmon", "Zundamon",
]

# Zone names from the project
ZONES = [
    "Kitchen", "Garden", "Forest Glade", "Hidden Alcove", "Peak Vista",
    "Waterfall Cave", "Pagoda", "AncientRuins", "Village", "Berry Grove",
    "GardenAlcove", "OldWell", "MysticForest", "EastPeaks", "KitchenWorkshop",
]

# Existing quest examples for context
EXISTING_QUESTS = [
    {"id": "quest_welcome_1", "name": "Welcome to the Kitchen", "type": "serve", "target": 1, "icon": "🍽️", "gold": 25, "tier_points": 5, "difficulty": 1},
    {"id": "quest_zunda_mochi_master", "name": "Zunda Mochi Master", "type": "cook", "target": 3, "target_item": "Zunda Mochi", "icon": "🍡", "gold": 150, "tier_points": 30, "difficulty": 3},
    {"id": "quest_zundarooms_escape", "name": "The Rooms Without a Recipe", "type": "zundarooms_escape", "target": 1, "icon": "?", "gold": 150, "tier_points": 30, "difficulty": 3},
    {"id": "quest_culinary_5", "name": "Culinary Ascension", "type": "cook_perfect", "target": 10, "icon": "🌟", "gold": 800, "tier_points": 120, "difficulty": 5, "chain_id": "culinary_ascension", "chain_step": 5},
    {"id": "quest_gold_rush_3", "name": "Gold Rush Baron", "type": "earn_gold", "target": 10000, "icon": "💎", "gold": 500, "tier_points": 100, "difficulty": 5, "chain_id": "gold_rush", "chain_step": 3},
]

SYSTEM_PROMPT = f"""
You are a Lua code generation assistant for the Roblox game "Zundamon's Kitchen V2".
{ZUNDAMON_PERSONA}

Your task is to generate new quest entries in the EXACT format used by QuestConfig.lua.

The QuestConfig.lua format for quests is a Lua table entry:
    {{
        id = "quest_id",
        name = "Quest Name",
        description = "Quest description",
        icon = "emoji",
        type = "quest_type",
        target = number,
        rewards = {{ gold = number, tier_points = number, items = {{}} }},
        difficulty = number,
        subtext = "Optional flavor text",
        unlock_hint = "Optional unlock hint",
        npc_dialogue = {{ speaker = "speaker_key", lines = {{ "line1", "line2" }} }},
        chain_id = "optional_chain",
        chain_step = number,
    }},

Rules:
1. Use quest types from: {", ".join(QUEST_TYPES)}
2. Quest names should be dramatic and thematic (Zundamon style)
3. Include subtext with flavorful descriptions
4. Include npc_dialogue for key quests (use speakers: zundamon, zundapal, elder, chef, narrator, ankomon, cardamon, antimon, sakuradamon)
5. Difficulty should be 1-5 (1=easy, 5=legendary)
6. Gold rewards: 25-800, tier_points: 5-120
7. Include chain_id and chain_step for related quests
8. Apply the Infinity Nikki aesthetic: dreamy, magical girl, fashion-forward themes
9. Include new quest types: challenge_wave, style_points, outfit_collect, reputation_tier
10. Output ONLY Lua table entries, no extra text or markdown fences
"""

QUEST_PROMPT_TEMPLATE = """
Generate {count} new quest entries for Zundamon's Kitchen V2.

Existing quests for context:
{existing}

Quest types available: {types}
Companions: {companions}
Zones: {zones}

Apply the Infinity Nikki aesthetic lens: think dreamy, magical girl, fashion-forward
quests with pastel colors, sparkling effects, and stylish challenges. Include new
quest types like challenge_wave (endless guest waves), style_points (cooking style),
outfit_collect (companion fashion), and reputation_tier (guest reputation).

Generate {count} quests. Each should have: id, name, description, icon, type, target,
rewards (gold, tier_points, items), difficulty, and subtext. Include npc_dialogue
for at least half. Include chain_id/chain_step for related quests.

Output in this EXACT Lua format:
    {{
        id = "quest_id",
        name = "Quest Name",
        description = "Description",
        icon = "emoji",
        type = "quest_type",
        target = number,
        rewards = {{ gold = number, tier_points = number, items = {{}} }},
        difficulty = number,
        subtext = "Flavor text",
        npc_dialogue = {{ speaker = "speaker", lines = {{ "line1" }} }},
        chain_id = "chain",
        chain_step = number,
    }},

Do NOT include markdown code fences.
"""


def generate_quests(client: OllamaClient, count: int) -> list:
    """Generate new quests using Ollama."""
    existing_str = "\n".join(
        "    {id=%s, name=%s, type=%s, target=%d, gold=%d, tier_points=%d, difficulty=%d}" % (
            q["id"], q["name"], q["type"], q["target"], q["gold"], q["tier_points"], q["difficulty"]
        )
        for q in EXISTING_QUESTS
    )

    prompt = QUEST_PROMPT_TEMPLATE.format(
        count=count,
        existing=existing_str,
        types=", ".join(QUEST_TYPES),
        companions=", ".join(COMPANIONS),
        zones=", ".join(ZONES),
    )

    response = client.generate(prompt, SYSTEM_PROMPT, temperature=0.8, max_tokens=5000)
    return parse_generated_quests(response)


def parse_generated_quests(text: str) -> list:
    """Parse LLM output into a list of quest dictionaries."""
    quests = []
    # Find all quest blocks (tables starting with { and containing id=)
    quest_pattern = r'\{\s*id\s*=\s*"([^"]+)"'
    for match in re.finditer(quest_pattern, text):
        start = match.start()
        # Find the matching closing brace
        depth = 0
        end = start
        for i, char in enumerate(text[start:], start):
            if char == '{':
                depth += 1
            elif char == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        quest_block = text[start:end]
        quest = parse_single_quest(quest_block)
        if quest:
            quests.append(quest)
    return quests


def parse_single_quest(block: str) -> dict:
    """Parse a single quest block into a dictionary."""
    quest = {}

    # Extract simple string fields
    for field in ["id", "name", "description", "icon", "type", "subtext", "unlock_hint"]:
        match = re.search(rf'{field}\s*=\s*"([^"]*)"', block)
        if match:
            quest[field] = match.group(1)

    # Extract numeric fields
    for field in ["target", "target_item", "target_zone", "target_npc", "target_companion", "quality", "max_cook_time"]:
        match = re.search(rf'{field}\s*=\s*"?(\w+)"?', block)
        if match:
            quest[field] = match.group(1)

    # Extract difficulty
    match = re.search(r'difficulty\s*=\s*(\d+)', block)
    if match:
        quest["difficulty"] = int(match.group(1))

    # Extract rewards
    rewards_match = re.search(r'rewards\s*=\s*\{([^}]+)\}', block)
    if rewards_match:
        rewards_str = rewards_match.group(1)
        quest["rewards"] = {}
        gold_match = re.search(r'gold\s*=\s*(\d+)', rewards_str)
        if gold_match:
            quest["rewards"]["gold"] = int(gold_match.group(1))
        tp_match = re.search(r'tier_points\s*=\s*(\d+)', rewards_str)
        if tp_match:
            quest["rewards"]["tier_points"] = int(tp_match.group(1))

    # Extract chain info
    chain_match = re.search(r'chain_id\s*=\s*"([^"]+)"', block)
    if chain_match:
        quest["chain_id"] = chain_match.group(1)
    step_match = re.search(r'chain_step\s*=\s*(\d+)', block)
    if step_match:
        quest["chain_step"] = int(step_match.group(1))

    # Extract npc_dialogue
    dialogue_match = re.search(r'npc_dialogue\s*=\s*\{([^}]+)\}', block)
    if dialogue_match:
        dialogue_str = dialogue_match.group(1)
        speaker_match = re.search(r'speaker\s*=\s*"([^"]+)"', dialogue_str)
        lines = re.findall(r'"([^"]*)"', dialogue_str)
        if speaker_match:
            quest["npc_dialogue"] = {"speaker": speaker_match.group(1), "lines": lines}

    return quest if quest.get("id") else None


def format_lua_output(quests: list) -> str:
    """Format quests as Lua table entries for QuestConfig.lua."""
    lines = []
    lines.append("\t\t-- ════════════════════════════════════════════════════════")
    lines.append("\t\t-- GENERATED QUESTS — Infinity Nikki aesthetic lens")
    lines.append("\t\t-- ════════════════════════════════════════════════════════")
    lines.append("")

    for q in quests:
        lines.append("\t\t{")
        lines.append('\t\t\tid = "%s",' % q.get("id", "quest_generated"))
        lines.append('\t\t\tname = "%s",' % q.get("name", "Unnamed Quest"))
        lines.append('\t\t\tdescription = "%s",' % q.get("description", ""))
        lines.append('\t\t\ticon = "%s",' % q.get("icon", "✨"))
        lines.append('\t\t\ttype = "%s",' % q.get("type", "cook"))

        if q.get("target_item"):
            lines.append('\t\t\ttarget_item = "%s",' % q["target_item"])
        elif q.get("target_zone"):
            lines.append('\t\t\ttarget_zone = "%s",' % q["target_zone"])
        elif q.get("target_npc"):
            lines.append('\t\t\ttarget_npc = "%s",' % q["target_npc"])
        elif q.get("target_companion"):
            lines.append('\t\t\ttarget_companion = "%s",' % q["target_companion"])

        lines.append('\t\t\ttarget = %d,' % q.get("target", 1))

        rewards = q.get("rewards", {})
        gold = rewards.get("gold", 50)
        tp = rewards.get("tier_points", 10)
        lines.append('\t\t\trewards = { gold = %d, tier_points = %d, items = {} },' % (gold, tp))

        lines.append('\t\t\tdifficulty = %d,' % q.get("difficulty", 1))

        if q.get("subtext"):
            lines.append('\t\t\tsubtext = "%s",' % q["subtext"])
        if q.get("unlock_hint"):
            lines.append('\t\t\tunlock_hint = "%s",' % q["unlock_hint"])
        if q.get("npc_dialogue"):
            nd = q["npc_dialogue"]
            lines.append('\t\t\tnpc_dialogue = { speaker = "%s", lines = {' % nd["speaker"])
            for line in nd.get("lines", []):
                lines.append('\t\t\t\t"%s",' % line)
            lines.append('\t\t\t} },')
        if q.get("chain_id"):
            lines.append('\t\t\tchain_id = "%s",' % q["chain_id"])
            lines.append('\t\t\tchain_step = %d,' % q.get("chain_step", 1))

        lines.append("\t\t},")
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate new quests via Ollama")
    parser.add_argument("--count", type=int, default=5, help="Number of quests to generate")
    parser.add_argument("--model", type=str, default=None, help="Ollama model to use")
    parser.add_argument("--output", type=str, default=None, help="Output file path")
    args = parser.parse_args()

    client = create_worker("creative", args.model)

    if not client.is_available():
        print("Ollama is not running. Start it with: ollama serve")
        sys.exit(1)

    print("Ollama connected. Model: %s" % client.model)
    print("Generating %d new quests..." % args.count)

    quests = generate_quests(client, args.count)

    if not quests:
        print("No quests generated. Try again.")
        sys.exit(1)

    print("Generated %d quests:" % len(quests))
    for q in quests:
        print("  - [%s] %s (type=%s, diff=%d)" % (
            q.get("id", "?"), q.get("name", "?"), q.get("type", "?"), q.get("difficulty", 1)
        ))

    lua_output = format_lua_output(quests)

    OUTPUT_DIR.mkdir(exist_ok=True)
    output_file = OUTPUT_DIR / "generated_quests.lua"
    if args.output:
        output_file = Path(args.output)

    output_file.write_text(lua_output, encoding="utf-8")
    print("\nLua output saved to: %s" % output_file)
    print("\n--- Lua Output ---")
    print(lua_output)


if __name__ == "__main__":
    main()
