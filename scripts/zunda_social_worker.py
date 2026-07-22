#!/usr/bin/env python3
"""
zunda_social_worker.py
Autonomous social media content generator & campaign scheduler for Zundamon's Kitchen V2 nanoda! 🫛✨
Generates Twitter/X posts, TikTok scripts, Discord announcements, and exports feed data to docs/marketing/social_feed.json.
"""

import os
import sys
import json
import argparse
import random
from datetime import datetime

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

ZUNDAMON_VOICE = {
    "catchphrases": ["nanoda! 🫛✨", "nanoda! 🌸", "nanoda! 🍡", "nanoda! 🔥", "nanoda! 👑"],
    "emojis": ["🫛", "🍡", "✨", "🌸", "👑", "💖", "🍵", "📸", "🍨"],
    "hashtags": "#ZundamonsKitchen #Roblox #RobloxDev #InfinityNikki #Zundamon #CozyGames #RobloxFashion"
}

POST_TEMPLATES = [
    {
        "platform": "X / Twitter",
        "category": "Daily Fashion Tip",
        "content": "🌸 Zundamon's Daily Styling Tip {catchphrase}\nEquipping the Mint Frill Apron gives you +10% Precision on all Perfect recipe timing windows! Look cute AND cook fast nanoda! 👗✨\n\n🎮 Play on Roblox: https://fromage3900.github.io/Zundamons-Kitchen-V2/\n\n{hashtags}"
    },
    {
        "platform": "X / Twitter",
        "category": "Promo Code Drop",
        "content": "🎁 NEW PROMO CODE DROP NANODA! 🫛✨\nType code '{code}' in-game for +{gold} Gold and {item}!\n\nRedeem now:\n👉 https://fromage3900.github.io/Zundamons-Kitchen-V2/\n\n{hashtags}"
    },
    {
        "platform": "TikTok / Shorts",
        "category": "Gameplay Video Script",
        "content": "🎬 TIKTOK SCRIPT: 'How I Unlocked the Zunda Princess Crown'\nVisual: Zundamon doing a magical girl transformation spin on top of the Grand Cafe.\nVoiceover: Here is how to unlock the 5-Star Legendary Zunda Royalty Crown on Roblox nanoda! Complete 7 Daily Streaks and land S-Rank combos in Challenge Mode!\nCaption: Become Royalty in Zundamon's Kitchen nanoda! 🫛✨ #Roblox #ZundamonsKitchen"
    },
    {
        "platform": "Discord Webhook",
        "category": "Community Event",
        "content": "📢 **WEEKLY GOURMET CHALLENGE IS LIVE NANODA!** 🫛✨\nWave 10 of Challenge Mode is active! Earn double Style Points this weekend and claim exclusive Whim Tickets!\n\n👉 Join game: https://www.roblox.com/"
    }
]

PROMO_CODES = [
    {"code": "ZUNDAMOCHI2026", "gold": 500, "item": "10x Fresh Zunda Mochi"},
    {"code": "SOUPSEASON", "gold": 1000, "item": "5x Wild Mushroom Pack"},
    {"code": "KAWAIIZUNDA", "gold": 750, "item": "Sakura Chef Apron"},
    {"code": "NIKKIFASHION", "gold": 1500, "item": "3x Whim Gacha Tickets"}
]

def generate_feed(count=5):
    feed = []
    for i in range(count):
        tmpl = random.choice(POST_TEMPLATES)
        code = random.choice(PROMO_CODES)
        catch = random.choice(ZUNDAMON_VOICE["catchphrases"])
        
        text = tmpl["content"].format(
            catchphrase=catch,
            code=code["code"],
            gold=code["gold"],
            item=code["item"],
            hashtags=ZUNDAMON_VOICE["hashtags"]
        )
        
        feed.append({
            "id": f"post_{i+1:03d}",
            "timestamp": datetime.now().isoformat(),
            "platform": tmpl["platform"],
            "category": tmpl["category"],
            "text": text
        })
    return feed

def main():
    parser = argparse.ArgumentParser(description="Zundamon Social Worker")
    parser.add_argument("--count", type=int, default=5, help="Number of social posts")
    parser.add_argument("--out", type=str, default="docs/marketing/social_feed.json", help="Output file path")
    args = parser.parse_args()

    feed = generate_feed(args.count)
    out_path = os.path.abspath(args.out)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({"generated_at": datetime.now().isoformat(), "feed": feed}, f, indent=2, ensure_ascii=False)

    print(f"✅ Generated {len(feed)} Zundamon social posts to {out_path} nanoda! 🫛✨")

if __name__ == "__main__":
    main()
