#!/usr/bin/env python3
"""
Autonomous Zundamon Social Media Publisher — Zundamon's Kitchen V2

Runs in the background, automatically invoking Ollama to generate in-character posts
and publishing them autonomously to X (Twitter), Instagram, and TikTok at set intervals.

Requirements:
    pip install requests tweepy python-dotenv

Usage:
    # Run once to post current queue:
    python scripts/autonomous_social_publisher.py --once

    # Run as a background daemon posting every 4 hours:
    python scripts/autonomous_social_publisher.py --daemon --interval-hours 4
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime

# Load environment variables from .env if present
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from ollama_client import OllamaClient, create_worker
from ollama_social_worker import generate_x_posts, generate_instagram_posts, generate_tiktok_scripts

# ─── API CONFIGURATION FROM ENVIRONMENT ─────────────────────────────────────

X_API_KEY = os.environ.get("X_API_KEY", "")
X_API_SECRET = os.environ.get("X_API_SECRET", "")
X_ACCESS_TOKEN = os.environ.get("X_ACCESS_TOKEN", "")
X_ACCESS_TOKEN_SECRET = os.environ.get("X_ACCESS_TOKEN_SECRET", "")

INSTAGRAM_ACCESS_TOKEN = os.environ.get("INSTAGRAM_ACCESS_TOKEN", "")
INSTAGRAM_ACCOUNT_ID = os.environ.get("INSTAGRAM_ACCOUNT_ID", "")

# ─── PUBLISHERS ─────────────────────────────────────────────────────────────

def publish_to_x(tweet_text: str) -> bool:
    """Publish tweet to X via Twitter API v2."""
    if not (X_API_KEY and X_API_SECRET and X_ACCESS_TOKEN and X_ACCESS_TOKEN_SECRET):
        print("[X Publisher] API Keys not configured in environment (.env). Skipping live post.")
        print(f"[X Publisher Preview] Post Content:\n{tweet_text}\n")
        return False

    try:
        import tweepy
        client = tweepy.Client(
            consumer_key=X_API_KEY,
            consumer_secret=X_API_SECRET,
            access_token=X_ACCESS_TOKEN,
            access_token_secret=X_ACCESS_TOKEN_SECRET
        )
        response = client.create_tweet(text=tweet_text)
        print(f"[X Publisher] Tweet published successfully! ID: {response.data['id']}")
        return True
    except Exception as e:
        print(f"[X Publisher] Error posting to X: {e}")
        return False

def publish_to_instagram(caption: str, image_url: str = None) -> bool:
    """Publish container post to Instagram via Meta Graph API."""
    if not (INSTAGRAM_ACCESS_TOKEN and INSTAGRAM_ACCOUNT_ID):
        print("[Instagram Publisher] Access Token not configured. Skipping live post.")
        print(f"[Instagram Preview] Caption:\n{caption}\n")
        return False

    try:
        import requests
        # Create media container
        url = f"https://graph.facebook.com/v18.0/{INSTAGRAM_ACCOUNT_ID}/media"
        payload = {
            "caption": caption,
            "access_token": INSTAGRAM_ACCESS_TOKEN
        }
        if image_url:
            payload["image_url"] = image_url

        resp = requests.post(url, data=payload, timeout=15)
        resp.raise_for_status()
        container_id = resp.json().get("id")

        # Publish container
        pub_url = f"https://graph.facebook.com/v18.0/{INSTAGRAM_ACCOUNT_ID}/media_publish"
        pub_resp = requests.post(pub_url, data={"creation_id": container_id, "access_token": INSTAGRAM_ACCESS_TOKEN}, timeout=15)
        pub_resp.raise_for_status()
        print(f"[Instagram Publisher] Post published successfully!")
        return True
    except Exception as e:
        print(f"[Instagram Publisher] Error posting to Instagram: {e}")
        return False

# ─── AUTONOMOUS CYCLE ───────────────────────────────────────────────────────

def run_publisher_cycle():
    print(f"\n==================================================")
    print(f"🌸 AUTONOMOUS ZUNDAMON PUBLISHER CYCLE: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} 🌸")
    print(f"==================================================")

    client = create_worker("creative")

    # 1. Generate Tweet
    try:
        tweets = generate_x_posts(client, count=1)
        if tweets and len(tweets) > 0:
            tweet_item = tweets[0]
            text = tweet_item.get("text", "")
            hashtags = tweet_item.get("hashtags", "")
            full_tweet = f"{text}\n\n{hashtags}\n🎮 Play on Roblox: https://www.roblox.com/"
            publish_to_x(full_tweet)
    except Exception as e:
        print(f"[Cycle] Failed X post generation: {e}")

    # 2. Generate Instagram Post
    try:
        ig_posts = generate_instagram_posts(client, count=1)
        if ig_posts and len(ig_posts) > 0:
            ig_item = ig_posts[0]
            caption = f"{ig_item.get('caption', '')}\n\n{ig_item.get('hashtags', '')}"
            publish_to_instagram(caption)
    except Exception as e:
        print(f"[Cycle] Failed Instagram post generation: {e}")

    print("✨ Publisher cycle completed!")

def main():
    parser = argparse.ArgumentParser(description="Autonomous Zundamon Social Media Publisher")
    parser.add_argument("--once", action="store_true", help="Run a single post cycle and exit")
    parser.add_argument("--daemon", action="store_true", help="Run continuously in the background")
    parser.add_argument("--interval-hours", type=float, default=4.0, help="Interval between posts in hours")
    args = parser.parse_args()

    if args.once or not args.daemon:
        run_publisher_cycle()
        return

    interval_sec = int(args.interval_hours * 3600)
    print(f"🚀 Starting Autonomous Zundamon Publisher Daemon (posting every {args.interval_hours} hours)...")
    while True:
        try:
            run_publisher_cycle()
        except Exception as e:
            print(f"[Daemon Error] {e}")
        time.sleep(interval_sec)

if __name__ == "__main__":
    main()
