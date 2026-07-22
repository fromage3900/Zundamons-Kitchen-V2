#!/usr/bin/env python3
"""
Zundamon's Kitchen V2 — Autonomous Marketing & Social Media Content Engine
Generates authentic, cute, and personable social media content in Zundamon's signature voice nanoda! 🫛✨

Supports: X/Twitter, TikTok/Shorts Scripts, Discord Webhooks, Roblox Group Shouts, and DevForum Posts.
"""

import os
import sys
import json
import argparse
import random
from datetime import datetime

# Force UTF-8 stdout for Windows terminals
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


# Zundamon Persona & Tone Specs
ZUNDAMON_PERSONA = {
    "name": "Zundamon (ずんだもん)",
    "catchphrases": ["nanoda! 🫛✨", "nanoda! 🌸", "nanoda! 🍡", "nanoda! 🔥"],
    "emojis": ["🫛", "🍡", "✨", "🌸", "🍳", "🥤", "🍵", "💖", "🟢"],
    "greeting_prefix": [
        "Good morning, chefs nanoda! 🫛✨",
        "Attention all Zunda Village cooks nanoda! 🍡",
        "Fresh mochi alert nanoda! 🌸",
        "Zundamon is here with big kitchen news nanoda! 🍳"
    ],
    "hashtags": "#ZundamonsKitchen #Roblox #RobloxDev #CozyGames #Zundamon #RobloxCooking"
}

# Template Pool for X / Twitter Posts
TWITTER_TEMPLATES = [
    {
        "category": "daily_greeting",
        "text": "Good morning, chefs! {greeting} Did you know that stirring edamame paste counter-clockwise makes Zunda Mochi 20% softer? Try it in the kitchen today {catchphrase}\n\n🎮 Play on Roblox: https://fromage3900.github.io/Zundamons-Kitchen-V2/\n\n{hashtags}"
    },
    {
        "category": "promo_code",
        "text": "🎁 EXCLUSIVE CODE DROP NANODA! 🫛✨\nType code '{code}' in Zundamon's Kitchen on Roblox to get +{gold} Gold and rare Zunda treats!\n\nRedeem here or on our website:\n👉 https://fromage3900.github.io/Zundamons-Kitchen-V2/\n\n{hashtags}"
    },
    {
        "category": "rhythm_challenge",
        "text": "🍳 RHYTHM COOKING CHALLENGE! Can you get an S-Rank on '{recipe}' today nanoda? 🍡\nLand 50 Perfect notes in a row and show Zundamon your high score screenshot!\n\n{hashtags}"
    },
    {
        "category": "companion_spotlight",
        "text": "🌸 COMPANION SPOTLIGHT: Sakuradamon!\nDid you know Sakuradamon grants +25% Chef XP while following you in Zunda Village? Bond with your spirit companions today {catchphrase}\n\n{hashtags}"
    }
]

# Template Pool for TikTok / YouTube Shorts Video Scripts
TIKTOK_SCRIPTS = [
    {
        "title": "3 Secret Tips to Master Zundamon's Kitchen on Roblox",
        "hook_visual": "Zundamon wearing a chef hat jumping on top of a giant Zunda Mochi dish in Roblox Studio.",
        "audio_track": "Upbeat Cozy Lo-Fi Anime Cooking Beat",
        "voiceover": "Here are 3 secrets to becoming a Master Chef in Zundamon's Kitchen nanoda! 1: Equip Sakuradamon for 25% extra XP! 2: Use code ZUNDAMOCHI2026 for free gold! 3: Tap along to the rhythm beat for S-Rank dishes nanoda!",
        "on_screen_text": "🫛 3 Secrets to Master Zundamon's Kitchen on Roblox! 🍡\n1. Equip Sakuradamon (+25% XP)\n2. Redeem 'ZUNDAMOCHI2026'\n3. Hit S-Rank Rhythm Combos!",
        "caption": "Become the ultimate chef in Zundamon's Kitchen V2 on Roblox nanoda! 🫛✨ Link in bio to play! #Roblox #ZundamonsKitchen #CozyGames #RobloxDev #Zundamon"
    },
    {
        "title": "POV: Making S-Rank Edamame Parfait with Zundamon",
        "hook_visual": "Fast-paced rhythm minigame gameplay with glowing PERFECT combo effects.",
        "audio_track": "Catchy 8-bit Synth Rhythm Beat",
        "voiceover": "Nailing every single beat on the Edamame Parfait recipe nanoda! Look at those Perfect combos! S-Rank dish completed! Come cook with Zundamon on Roblox!",
        "on_screen_text": "🍳 S-RANK PERFECT COMBO! 🍨\nRecipe: Edamame Parfait\nGold Reward: +300 Gold 🪙",
        "caption": "Can you beat my rhythm combo score in Zundamon's Kitchen nanoda? 🫛✨ Play free on Roblox now! #Roblox #RobloxGames #RobloxStudio #Zundamon"
    }
]

# Active Promo Codes Pool
PROMO_CODES = [
    {"code": "ZUNDAMOCHI2026", "gold": 500, "item": "10x Fresh Zunda Mochi"},
    {"code": "SOUPSEASON", "gold": 1000, "item": "5x Wild Mushroom Pack"},
    {"code": "HYBRIDECS", "gold": 250, "item": "Matter ECS Developer Badge"},
    {"code": "KAWAIIZUNDA", "gold": 750, "item": "Sakura Chef Apron"}
]

RECIPES = ["Zunda Mochi", "Edamame Parfait", "Zunda Shake", "Triple Color Dango", "Zunda Tempura Udon"]

def generate_twitter_post():
    template = random.choice(TWITTER_TEMPLATES)
    greeting = random.choice(ZUNDAMON_PERSONA["greeting_prefix"])
    catchphrase = random.choice(ZUNDAMON_PERSONA["catchphrases"])
    code_data = random.choice(PROMO_CODES)
    recipe = random.choice(RECIPES)
    
    text = template["text"].format(
        greeting=greeting,
        catchphrase=catchphrase,
        code=code_data["code"],
        gold=code_data["gold"],
        recipe=recipe,
        hashtags=ZUNDAMON_PERSONA["hashtags"]
    )
    return {
        "platform": "X / Twitter",
        "category": template["category"],
        "content": text
    }

def generate_tiktok_script():
    script = random.choice(TIKTOK_SCRIPTS)
    return {
        "platform": "TikTok / YouTube Shorts",
        "title": script["title"],
        "visual_hook": script["hook_visual"],
        "audio_track": script["audio_track"],
        "voiceover_script": script["voiceover"],
        "on_screen_text": script["on_screen_text"],
        "caption": script["caption"]
    }

def generate_discord_embed():
    code_data = random.choice(PROMO_CODES)
    return {
        "platform": "Discord Webhook",
        "embed": {
            "title": "🫛 Zundamon's Kitchen V2 — Community Update nanoda!",
            "description": f"Zundamon has dropped a new promo code for all cozy chefs! Type **`{code_data['code']}`** in-game or on our website to claim **+{code_data['gold']} Gold** and **{code_data['item']}**!",
            "color": 5025616, # Zunda green hex #4caf50
            "fields": [
                {"name": "🎮 Play on Roblox", "value": "[Click Here to Play](https://www.roblox.com/)", "inline": True},
                {"name": "💻 Web Dashboard", "value": "[Open Zunda-OS](https://fromage3900.github.io/Zundamons-Kitchen-V2/)", "inline": True}
            ],
            "footer": {"text": "Zundamon's Kitchen V2 · Hybrid ECS v2.4.0 · 100% Wholesome"}
        }
    }

def main():
    parser = argparse.ArgumentParser(description="Zundamon Autonomous Marketing Content Generator")
    parser.add_argument("--platform", choices=["twitter", "tiktok", "discord", "all"], default="all", help="Platform to generate content for")
    parser.add_argument("--count", type=int, default=1, help="Number of content packs to generate")
    parser.add_argument("--out", type=str, help="Optional output JSON file path")
    args = parser.parse_args()

    results = []

    for i in range(args.count):
        pack = {
            "timestamp": datetime.now().isoformat(),
            "pack_id": i + 1,
            "persona": ZUNDAMON_PERSONA["name"]
        }

        if args.platform in ["twitter", "all"]:
            pack["twitter"] = generate_twitter_post()
        if args.platform in ["tiktok", "all"]:
            pack["tiktok"] = generate_tiktok_script()
        if args.platform in ["discord", "all"]:
            pack["discord"] = generate_discord_embed()

        results.append(pack)

    output_str = json.dumps(results, indent=2, ensure_ascii=False)
    print(output_str)

    if args.out:
        os.makedirs(os.path.dirname(args.out) or '.', exist_ok=True)
        with open(args.out, 'w', encoding='utf-8') as f:
            f.write(output_str)
        print(f"\n✅ Content pack saved to {args.out}")

if __name__ == "__main__":
    main()
