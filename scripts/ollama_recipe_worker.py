#!/usr/bin/env python3
"""
Recipe Worker — Zundamon's Kitchen V2

Reads existing CraftConfig.lua recipes as research, uses Zundamon's persona
as a style template, and generates new recipes via Ollama.

Output: Lua-formatted recipe entries for CraftConfig.lua

Usage:
    python scripts/ollama_recipe_worker.py [--count 5] [--model deepseek-coder:6.7b]
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

# Add scripts directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))
from ollama_client import OllamaClient, ZUNDAMON_PERSONA, LuaFormatter, create_worker

# ─── Project Context ──────────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).parent.parent
CRAFT_CONFIG_PATH = PROJECT_ROOT / "src" / "shared" / "ConfigurationFiles" / "CraftConfig.lua"
QUEST_CONFIG_PATH = PROJECT_ROOT / "src" / "shared" / "ConfigurationFiles" / "QuestConfig.lua"
COMPANION_CONFIG_PATH = PROJECT_ROOT / "src" / "shared" / "ConfigurationFiles" / "CompanionConfig.lua"
OUTPUT_DIR = PROJECT_ROOT / "scripts" / "ollama_output"

# Existing ingredients in the project
KNOWN_INGREDIENTS = [
    "Zunda Pea", "Edamame Pod", "Sweet Pea", "Pea Flower",
    "Zunda Leaf", "Zunda Berry", "Zunda Mushroom", "Zunda Root", "Zunda Flower",
    "Apple", "Wheat", "Gold", "Wood", "Wood Log", "Rock", "Iron Ore",
]

# Existing recipes for context
EXISTING_RECIPES = {
    "Apple Pie": {"Apple": 3, "Wheat": 5},
    "Bread": {"Wheat": 10},
    "Zunda Bread": {"Wheat": 15, "Apple": 2},
    "Royal Stew": {"Wheat": 8, "Apple": 5, "Gold": 1},
    "Zunda Mochi": {"Zunda Pea": 5, "Wheat": 8},
    "Edamame Snack": {"Edamame Pod": 3, "Zunda Leaf": 2},
    "Fancy Pie": {"Apple": 7, "Wheat": 12, "Gold": 2},
    "Zundamon's Banquet": {"Wheat": 20, "Apple": 10, "Gold": 3},
    "Sweet Pea Cake": {"Sweet Pea": 4, "Wheat": 10, "Zunda Pea": 3},
    "Pea Flower Tea": {"Pea Flower": 5, "Zunda Leaf": 3},
    "Ultimate Feast": {"Wheat": 30, "Apple": 20, "Gold": 5},
    "Zunda Paradise": {"Zunda Pea": 15, "Edamame Pod": 10, "Sweet Pea": 5, "Pea Flower": 3},
    "Antimon's Speed Soup": {"Zunda Mushroom": 4, "Zunda Leaf": 3},
    "Cardamon's Calm Cup": {"Pea Flower": 3, "Zunda Leaf": 2, "Sweet Pea": 1},
    "Seasonal Salad": {"Zunda Berry": 3, "Zunda Leaf": 2},
    "Sakuradamon's Blossom Bites": {"Pea Flower": 4, "Zunda Berry": 3},
    "Warm Winter Stew": {"Zunda Root": 3, "Zunda Mushroom": 2, "Gold": 1},
    "Ankomon's Protein Punch": {"Edamame Pod": 5, "Zunda Pea": 3, "Gold": 1},
    "Golden Harvest Platter": {"Apple": 5, "Wheat": 8, "Gold": 2, "Sweet Pea": 3},
}

# Companion names for companion-themed recipes
COMPANIONS = [
    "Ankomon", "Cardamon", "Antimon", "Sakuradamon",
    "Zundapal", "Zundacat", "Zundabunny", "Tantanmon",
]

# ─── Prompt Templates ─────────────────────────────────────────────────────────

SYSTEM_PROMPT = f"""
You are a Lua code generation assistant for the Roblox game "Zundamon's Kitchen V2".
{ZUNDAMON_PERSONA}

Your task is to generate new cooking recipes in the EXACT format used by CraftConfig.lua.

The CraftConfig.lua format for recipes is:
    ["Recipe Name"] = {{["Ingredient1"] = amount1, ["Ingredient2"] = amount2}},

Rules:
1. Use ONLY these ingredients: {", ".join(KNOWN_INGREDIENTS)}
2. Recipe names should follow Zundamon's dramatic naming style
3. Each recipe should use 2-5 ingredients
4. Ingredient amounts should be 1-30 (higher for common, lower for rare)
5. Generate recipes that fit the game's cozy cooking theme
6. Include companion-themed recipes (e.g., "Ankomon's Protein Punch")
7. Include seasonal/Zunda-themed recipes with dramatic flair
8. Output ONLY the Lua table entries, no extra text

Example output format:
    ["Tantanmon's Spice Cake"] = {{["Zunda Pea"] = 4, ["Sweet Pea"] = 2, ["Zunda Berry"] = 1}},
    ["Zundacat's Midnight Mousse"] = {{["Zunda Mushroom"] = 3, ["Zunda Leaf"] = 5}},
"""

RECIPE_PROMPT_TEMPLATE = """
Generate {count} new cooking recipes for Zundamon's Kitchen V2.

Existing recipes for context:
{existing}

Known ingredients: {ingredients}

Companions to theme recipes around: {companions}

Apply the Infinity Nikki aesthetic lens: think dreamy, magical girl, fashion-forward
cooking with pastel colors, sparkling effects, and stylish presentation.

Generate {count} recipes. Each recipe name should be dramatic and thematic.
Output in this EXACT Lua format (one per line):
    ["Recipe Name"] = {{["Ingredient"] = amount, ["Ingredient"] = amount}},

Do NOT include cooking times, difficulty, or any other fields — just the recipe
ingredient tables. Do NOT include markdown code fences.
"""


def read_existing_config() -> str:
    """Read the existing CraftConfig.lua for context."""
    if CRAFT_CONFIG_PATH.exists():
        return CRAFT_CONFIG_PATH.read_text(encoding="utf-8")
    return ""


def parse_generated_recipes(text: str) -> dict:
    """Parse LLM output into a dictionary of recipe_name -> {ingredient: amount}."""
    recipes = {}
    # Match Lua table entries like: ["Recipe Name"] = {["Ingredient"] = amount, ...},
    pattern = r'\["([^"]+)"\]\s*=\s*\{([^}]+)\}'
    for match in re.finditer(pattern, text):
        name = match.group(1)
        ingredients_str = match.group(2)
        ingredients = {}
        for ing_match in re.finditer(r'\["([^"]+)"\]\s*=\s*(\d+)', ingredients_str):
            ingredients[ing_match.group(1)] = int(ing_match.group(2))
        if ingredients:
            recipes[name] = ingredients
    return recipes


def _format_existing_recipe(name: str, ingredients: dict) -> str:
    """Format a single existing recipe as a Lua line for the prompt."""
    parts = []
    for ing, amt in ingredients.items():
        parts.append('["%s"] = %d' % (ing, amt))
    return '    ["%s"] = {%s},' % (name, ", ".join(parts))


def generate_recipes(client: OllamaClient, count: int) -> dict:
    """Generate new recipes using Ollama."""
    existing_lines = [
        _format_existing_recipe(name, ings)
        for name, ings in list(EXISTING_RECIPES.items())[:8]
    ]
    existing_str = "\n".join(existing_lines)

    prompt = RECIPE_PROMPT_TEMPLATE.format(
        count=count,
        existing=existing_str,
        ingredients=", ".join(KNOWN_INGREDIENTS),
        companions=", ".join(COMPANIONS),
    )

    response = client.generate(prompt, SYSTEM_PROMPT, temperature=0.7, max_tokens=3000)
    return parse_generated_recipes(response)


def format_lua_output(recipes: dict) -> str:
    """Format recipes as Lua table entries for CraftConfig.lua."""
    lines = []
    lines.append("\t-- ════════════════════════════════════════════════════════")
    lines.append("\t-- GENERATED RECIPES — Infinity Nikki aesthetic lens")
    lines.append("\t-- ════════════════════════════════════════════════════════")
    lines.append("")
    for name, ingredients in recipes.items():
        ing_str = ", ".join(f'["{ing}"] = {amt}' for ing, amt in ingredients.items())
        lines.append(f'\t["{name}"] = {{{ing_str}}},')
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate new cooking recipes via Ollama")
    parser.add_argument("--count", type=int, default=8, help="Number of recipes to generate")
    parser.add_argument("--model", type=str, default=None, help="Ollama model to use")
    parser.add_argument("--output", type=str, default=None, help="Output file path")
    args = parser.parse_args()

    client = create_worker("code", args.model)

    if not client.is_available():
        print("✗ Ollama is not running. Start it with: ollama serve")
        sys.exit(1)

    print(f"✓ Ollama connected. Model: {client.model}")
    print(f"Generating {args.count} new recipes...")

    recipes = generate_recipes(client, args.count)

    if not recipes:
        print("✗ No recipes generated. Try again or adjust the prompt.")
        sys.exit(1)

    print(f"✓ Generated {len(recipes)} recipes:")
    for name, ingredients in recipes.items():
        ing_str = ", ".join(f"{amt}x {ing}" for ing, amt in ingredients.items())
        print(f"  - {name}: {ing_str}")

    lua_output = format_lua_output(recipes)

    # Save to output directory
    OUTPUT_DIR.mkdir(exist_ok=True)
    output_file = OUTPUT_DIR / "generated_recipes.lua"
    if args.output:
        output_file = Path(args.output)

    output_file.write_text(lua_output, encoding="utf-8")
    print(f"\n✓ Lua output saved to: {output_file}")
    print(f"\n--- Lua Output ---")
    print(lua_output)


if __name__ == "__main__":
    main()
