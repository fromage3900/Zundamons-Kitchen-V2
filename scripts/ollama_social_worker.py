#!/usr/bin/env python3
"""
Ollama Autonomous Social Media Content Worker — Zundamon's Kitchen V2

Generates in-character social media posts for X (Twitter), TikTok, and Instagram
speaking directly as Zundamon (all-caps enthusiasm, pea metaphors, 🫛🍡✨ emojis).

Usage:
    python scripts/ollama_social_worker.py --platform x --count 5
    python scripts/ollama_social_worker.py --platform tiktok --count 3
    python scripts/ollama_social_worker.py --platform instagram --count 3
    python scripts/ollama_social_worker.py --all
"""

import argparse
import json
import os
import sys
from datetime import datetime

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from ollama_client import OllamaClient, ZUNDAMON_PERSONA, create_worker

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "ollama_output")

SOCIAL_SYSTEM_PROMPT = ZUNDAMON_PERSONA + """
You are generating official social media content for Zundamon's Kitchen V2 on Roblox!
Your goal is to promote the game, share daily cooking tips, hype up Challenge Mode waves,
and interact with players in Zundamon's signature enthusiastic voice (ALL CAPS, pea metaphors, emojis).

Platform Guidelines:
1. X (Twitter):
   - Under 280 characters.
   - High dopamine, enthusiastic call-to-action to play on Roblox.
   - Includes 2-3 hashtags: #ZundamonsKitchen #Roblox #CozyGaming #Zundamon

2. TikTok:
   - Voiceover Script (15-30 seconds): High energy hook, visual description, audio cue, and Zundamon VO text.
   - Caption: Short, catchy, viral hashtags: #Zundamon #RobloxGaming #AnimeCooking #CozyVibes

3. Instagram:
   - Visual post description (aesthetic, pastel kawaii, Zunda Mochi).
   - Post Body: 2-3 paragraphs in Zundamon's voice with tips, secret recipe huddle, or companion showcase.
   - Hashttags block: #ZundamonsKitchen #KawaiiGaming #InfinityNikki #RobloxDev #ZundaVillage
"""

def generate_x_posts(client: OllamaClient, count: int = 5) -> list:
    prompt = f"""
Generate {count} distinct X (Twitter) posts written directly by Zundamon promoting Zundamon's Kitchen V2 on Roblox.

Requirements:
- Written in ALL CAPS with Zundamon's signature energy and pea emojis (🫛🍡✨🔥).
- Under 280 characters each.
- Includes call-to-action to jump into Roblox.
- Returns JSON array of objects: [{{"id": "tweet_1", "text": "...", "hashtags": "#ZundamonsKitchen #Roblox"}}]
"""
    result = client.generate_json(prompt, SOCIAL_SYSTEM_PROMPT)
    if isinstance(result, list):
        return result
    return result.get("posts", result.get("tweets", []))

def generate_tiktok_scripts(client: OllamaClient, count: int = 3) -> list:
    prompt = f"""
Generate {count} TikTok video concepts & voiceover scripts for Zundamon's Kitchen V2.

Requirements:
- Visual concept (e.g. 120 BPM Perfect Cook combo streak, Gacha 5-star pull, Nikki the Drifter visit).
- Voiceover script written in Zundamon's ALL CAPS voice.
- Caption + hashtag block.
- Returns JSON array of objects: [{{"title": "...", "visual": "...", "voiceover": "...", "caption": "..."}}]
"""
    result = client.generate_json(prompt, SOCIAL_SYSTEM_PROMPT)
    if isinstance(result, list):
        return result
    return result.get("scripts", result.get("videos", []))

def generate_instagram_posts(client: OllamaClient, count: int = 3) -> list:
    prompt = f"""
Generate {count} Instagram carousel / image post concepts for Zundamon's Kitchen V2.

Requirements:
- Aesthetic image concept (Pastel Y2K, Infinity Nikki style lighting, Zunda Mochi feast).
- Caption text written in Zundamon's voice.
- Tag list & hashtags.
- Returns JSON array of objects: [{{"title": "...", "image_idea": "...", "caption": "...", "hashtags": "..."}}]
"""
    result = client.generate_json(prompt, SOCIAL_SYSTEM_PROMPT)
    if isinstance(result, list):
        return result
    return result.get("posts", result.get("instagram", []))

def main():
    parser = argparse.ArgumentParser(description="Generate Zundamon Social Media Content")
    parser.add_argument("--platform", choices=["x", "tiktok", "instagram", "all"], default="all")
    parser.add_argument("--count", type=int, default=3, help="Number of items to generate per platform")
    parser.add_argument("--model", type=str, default="llama3.1:8b", help="Ollama model to use")
    args = parser.parse_args()

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    client = create_worker("creative", model=args.model)

    print(f"🌸 ZUNDAMON SOCIAL MEDIA CONTENT WORKER 🌸")
    print(f"Target Platform: {args.platform}")
    print(f"Ollama Host: {client.host} | Model: {client.model}")

    output_data = {"generated_at": datetime.now().isoformat()}

    if args.platform in ["x", "all"]:
        print(f"\n[X/Twitter] Generating {args.count} tweets...")
        try:
            output_data["x_posts"] = generate_x_posts(client, args.count)
            print(f"✓ Generated {len(output_data.get('x_posts', []))} tweets")
        except Exception as e:
            print(f"✗ Failed to generate X posts: {e}")

    if args.platform in ["tiktok", "all"]:
        print(f"\n[TikTok] Generating {args.count} video scripts...")
        try:
            output_data["tiktok_scripts"] = generate_tiktok_scripts(client, args.count)
            print(f"✓ Generated {len(output_data.get('tiktok_scripts', []))} TikTok scripts")
        except Exception as e:
            print(f"✗ Failed to generate TikTok scripts: {e}")

    if args.platform in ["instagram", "all"]:
        print(f"\n[Instagram] Generating {args.count} posts...")
        try:
            output_data["instagram_posts"] = generate_instagram_posts(client, args.count)
            print(f"✓ Generated {len(output_data.get('instagram_posts', []))} Instagram posts")
        except Exception as e:
            print(f"✗ Failed to generate Instagram posts: {e}")

    # Write out JSON result
    out_file = os.path.join(OUTPUT_DIR, "social_media_queue.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print(f"\n✨ Social Media Content generated successfully -> {out_file}")

if __name__ == "__main__":
    main()
