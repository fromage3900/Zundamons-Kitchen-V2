#!/usr/bin/env python3
"""
Dialogue Worker — Zundamon's Kitchen V2

Reads existing VNDialogueData.lua dialogue as research, uses Zundamon's persona
as a style template, and generates new companion/NPC dialogue via Ollama.

Output: Lua-formatted dialogue entries for VNDialogueData.lua

Usage:
    python scripts/ollama_dialogue_worker.py [--count 10] [--model gemma4:12b]
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

# Speakers from VNDialogueData.lua
SPEAKERS = {
    "zundamon": {"name": "Zundamon", "emoji": "🫛", "accent": "RGB(160, 210, 150)"},
    "zundapal": {"name": "Zundapal", "emoji": "🍡", "accent": "RGB(200, 230, 180)"},
    "zundacat": {"name": "Zundacat", "emoji": "🐱", "accent": "RGB(245, 194, 145)"},
    "zundabunny": {"name": "Zundabunny", "emoji": "🐰", "accent": "RGB(214, 187, 242)"},
    "tantanmon": {"name": "Tantanmon", "emoji": "🌶️", "accent": "RGB(239, 137, 111)"},
    "narrator": {"name": "", "emoji": "✨", "accent": "RGB(220, 200, 170)"},
    "elder": {"name": "Village Elder", "emoji": "🏮", "accent": "RGB(220, 180, 130)"},
    "ruins": {"name": "Ancient Voice", "emoji": "👁", "accent": "RGB(190, 170, 210)"},
    "chef": {"name": "Head Chef", "emoji": "🍳", "accent": "RGB(230, 185, 130)"},
    "ankomon": {"name": "Ankomon", "emoji": "🫘", "accent": "RGB(220, 150, 150)"},
    "cardamon": {"name": "Cardamon", "emoji": "🍋", "accent": "RGB(235, 205, 125)"},
    "antimon": {"name": "Antimon", "emoji": "🌿", "accent": "RGB(145, 215, 195)"},
    "sakuradamon": {"name": "Sakuradamon", "emoji": "🌸", "accent": "RGB(255, 180, 200)"},
}

# Time-of-day slots
TIME_SLOTS = ["morning", "afternoon", "evening", "night"]

# Level brackets
LEVEL_BRACKETS = ["level1_10", "level11_20", "level21_50"]

# Existing dialogue examples for context
EXISTING_DIALOGUE = {
    "zundapal_morning": [
        "Good morning, {player}~ ☀️",
        "Ready to cook up something wonderful today?",
        "I can already smell the kitchen from here! 🍳",
    ],
    "zundamon_culinary_5": [
        "10 PERFECT COOKS!!! DO YOU HAVE ANY IDEA WHAT THAT MEANS?!?! 🔥🔥🔥",
        "THE KITCHEN ITSELF WILL RECOGNIZE YOU!!! THE STOVE WILL BOW!!! THE SPATULAS WILL SALUTE!!! GO GO GO!!!",
    ],
    "ankomon_morning": [
        "Training begins at dawn, {player}.",
        "Every great chef needs discipline. ⚖️",
        "Shall we practice precision cooking? 🔥",
    ],
    "cardamon_morning": [
        "Breathe in the fresh aromas, {player}~",
        "Patience reveals the best flavors. 🧘",
    ],
    "antimon_morning": [
        "Time is ingredients, {player}! ⚡",
        "Let's cook at lightning speed!",
    ],
    "sakuradamon_morning": [
        "The sakura blossoms bloom with the seasons~ 🌸",
        "Seek rare ingredients for special recipes!",
    ],
}

SYSTEM_PROMPT = f"""
You are a dialogue generation assistant for the Roblox game "Zundamon's Kitchen V2".
{ZUNDAMON_PERSONA}

Your task is to generate new companion and NPC dialogue lines in the style of
the existing VNDialogueData.lua.

Dialogue format:
- Simple lines: "Dialogue text here"
- With player name: "Hello, {{player}}!"
- With emojis: "Cook something wonderful! 🍡✨"

Rules:
1. Each speaker has a distinct personality — match their style
2. Include {{player}} placeholder where appropriate
3. Use emojis frequently (food, nature, magical girl themed)
4. Apply the Infinity Nikki aesthetic: dreamy, pastel, magical girl, sparkling
5. Generate lines for time-of-day (morning/afternoon/evening/night)
6. Generate level-based dialogue (level1_10, level11_20, level21_50)
7. Include side dialogue triggers for new ingredients/recipes
8. Include guest type-specific dialogue for new guest types
9. Keep lines short (1-2 sentences max)
10. Output ONLY dialogue lines, no Lua table structure

Speaker personalities:
- zundamon: Enthusiastic, ALL CAPS, pea-themed, dramatic!!!
- zundapal: Sweet, supportive, uses ~ and emojis, encouraging
- zundacat: Playful, curious, cat-like, mischievous
- zundabunny: Energetic, optimistic, hop-themed, cheerful
- tantanmon: Spicy, fiery, energetic, festival-like
- elder: Wise, patient, uses proverbs, ancient knowledge
- chef: Strict, demanding, professional, high standards
- ankomon: Intense, protein-focused, training-oriented, bold
- cardamon: Calm, meditative, patience-focused, zen
- antimon: Fast-paced, impatient, speed-focused, energetic
- sakuradamon: Graceful, seasonal, blossom-themed, poetic
- narrator: Mysterious, descriptive, atmospheric
"""

DIALOGUE_PROMPT_TEMPLATE = """
Generate {count} new dialogue lines for Zundamon's Kitchen V2.

Existing dialogue for context:
{existing}

Speakers: {speakers}
Time slots: {time_slots}
Level brackets: {level_brackets}

Apply the Infinity Nikki aesthetic lens: dreamy, pastel, magical girl, sparkling
effects, fashion-forward themes. Think of the dialogue as magical girl transformation
sequences and stylish cooking moments.

Generate {count} dialogue lines. For each line, specify:
- Speaker key (e.g., zundamon, zundapal, ankomon)
- Context (e.g., morning, level1_10, side_dialogue)
- The dialogue text

Format each line as:
    [speaker:context] "Dialogue text here with {{player}} and emojis"

Include a mix of:
- Time-of-day greetings for all companions
- Level-based progression dialogue
- Side dialogue for new recipes/ingredients
- Guest type-specific lines for Infinity Nikki themed guests
- Challenge mode encouragement lines

Do NOT include Lua table structure. Just the dialogue lines.
"""


def generate_dialogue(client: OllamaClient, count: int) -> list:
    """Generate new dialogue using Ollama."""
    existing_str = "\n".join(
        "[%s:%s] \"%s\"" % (
            speaker.split("_")[0],
            "_".join(speaker.split("_")[1:]),
            line
        )
        for speaker, lines in EXISTING_DIALOGUE.items()
        for line in lines
    )

    prompt = DIALOGUE_PROMPT_TEMPLATE.format(
        count=count,
        existing=existing_str,
        speakers=", ".join(SPEAKERS.keys()),
        time_slots=", ".join(TIME_SLOTS),
        level_brackets=", ".join(LEVEL_BRACKETS),
    )

    response = client.generate(prompt, SYSTEM_PROMPT, temperature=0.8, max_tokens=4000)
    return parse_generated_dialogue(response)


def parse_generated_dialogue(text: str) -> list:
    """Parse LLM output into a list of dialogue entries."""
    entries = []
    # Format: [speaker:context] "dialogue text"
    pattern = r'\[(\w+):(\w+)\]\s*"([^"]*)"'
    for match in re.finditer(pattern, text):
        entries.append({
            "speaker": match.group(1),
            "context": match.group(2),
            "text": match.group(3),
        })
    return entries


def format_lua_output(entries: list) -> str:
    """Format dialogue entries as Lua for VNDialogueData.lua."""
    lines = []
    lines.append("\t-- ════════════════════════════════════════════════════════")
    lines.append("\t-- GENERATED DIALOGUE — Infinity Nikki aesthetic lens")
    lines.append("\t-- ════════════════════════════════════════════════════════")
    lines.append("")

    # Group by speaker and context
    by_speaker = {}
    for entry in entries:
        speaker = entry["speaker"]
        context = entry["context"]
        if speaker not in by_speaker:
            by_speaker[speaker] = {}
        if context not in by_speaker[speaker]:
            by_speaker[speaker][context] = []
        by_speaker[speaker][context].append(entry["text"])

    for speaker, contexts in by_speaker.items():
        for context, texts in contexts.items():
            lines.append("\t-- %s - %s" % (speaker, context))
            for text in texts:
                lines.append('\t"%s",' % text)
            lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate new dialogue via Ollama")
    parser.add_argument("--count", type=int, default=15, help="Number of dialogue lines to generate")
    parser.add_argument("--model", type=str, default=None, help="Ollama model to use")
    parser.add_argument("--output", type=str, default=None, help="Output file path")
    args = parser.parse_args()

    client = create_worker("dialogue", args.model)

    if not client.is_available():
        print("Ollama is not running. Start it with: ollama serve")
        sys.exit(1)

    print("Ollama connected. Model: %s" % client.model)
    print("Generating %d new dialogue lines..." % args.count)

    entries = generate_dialogue(client, args.count)

    if not entries:
        print("No dialogue generated. Try again.")
        sys.exit(1)

    print("Generated %d dialogue lines:" % len(entries))
    for e in entries:
        print("  [%s:%s] %s" % (e["speaker"], e["context"], e["text"][:60]))

    lua_output = format_lua_output(entries)

    OUTPUT_DIR.mkdir(exist_ok=True)
    output_file = OUTPUT_DIR / "generated_dialogue.lua"
    if args.output:
        output_file = Path(args.output)

    output_file.write_text(lua_output, encoding="utf-8")
    print("\nLua output saved to: %s" % output_file)
    print("\n--- Lua Output ---")
    print(lua_output)


if __name__ == "__main__":
    main()
