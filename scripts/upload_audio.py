#!/usr/bin/env python3
"""
Roblox Audio Uploader — Zundamon's Kitchen V2

Batch-uploads the generated Zundamon voicelines to Roblox via Open Cloud and
records the resulting asset IDs back into `voicevox_output/manifest.json`.

Follows the same Open Cloud flow as `upload_decal.py` (multipart POST →
operation poll), with three audio-specific differences:
  - assetType "Audio", Content-Type audio/mpeg
  - Roblox rejects WAV; we upload the derived MP3
  - audio goes through moderation, so an upload can succeed and the asset still
    not be playable for a while

Resumable: clips that already carry an `asset_id` are skipped, so a partial run
(rate limit, expired key) can be re-run safely.

Prerequisites:
    setx ROBLOX_OPEN_CLOUD_API_KEY "<key with asset:write>"
    setx ROBLOX_CREATOR_USER_ID   "<your user id>"
    # then open a NEW terminal

Usage:
    python scripts/upload_audio.py --check          # validate credentials only
    python scripts/upload_audio.py --dry-run        # show what would upload
    python scripts/upload_audio.py                  # upload pending clips
    python scripts/upload_audio.py --only cook_     # prefix filter
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voicevox_output")
MANIFEST = os.path.join(OUT_DIR, "manifest.json")

API_KEY = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "")
USER_ID = os.environ.get("ROBLOX_CREATOR_USER_ID", "")

ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPS_URL = "https://apis.roblox.com/assets/v1/operations/{}"

# Open Cloud asset creation is rate limited; pace the batch.
DELAY_BETWEEN_UPLOADS = 1.5


def load_manifest() -> dict:
    if not os.path.exists(MANIFEST):
        print(f"ERROR: {MANIFEST} not found. Run voicevox_voiceline_worker.py first.")
        sys.exit(1)
    with open(MANIFEST, encoding="utf-8") as f:
        return json.load(f)


def save_manifest(data: dict) -> None:
    with open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def check_credentials() -> bool:
    """Verify the API key authenticates before burning a batch on 401s."""
    if not API_KEY:
        print("ERROR: ROBLOX_OPEN_CLOUD_API_KEY not set.")
        return False
    if not USER_ID:
        print("ERROR: ROBLOX_CREATOR_USER_ID not set.")
        return False

    req = urllib.request.Request(
        f"https://apis.roblox.com/cloud/v2/users/{USER_ID}",
        headers={"x-api-key": API_KEY},
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            if r.status == 200:
                print(f"credentials OK (user {USER_ID}, key {len(API_KEY)} chars)")
                return True
    except urllib.error.HTTPError as e:
        if e.code == 401:
            print(
                "ERROR: 401 Invalid API Key.\n"
                "  The key is set but Roblox rejects it. Usual causes:\n"
                "   - the key hit its expiration date\n"
                "   - your IP changed and the key has an IP allowlist\n"
                "   - the key was regenerated or deleted\n"
                "  Fix at https://create.roblox.com/credentials (confirm asset:write),\n"
                "  then re-set the env var and open a NEW terminal."
            )
        else:
            print(f"ERROR: HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:200]}")
        return False
    except Exception as e:
        print(f"ERROR: {type(e).__name__}: {e}")
        return False
    return False


def poll_operation(op_id: str, tries: int = 40) -> str | None:
    for _ in range(tries):
        req = urllib.request.Request(OPS_URL.format(op_id), headers={"x-api-key": API_KEY})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.loads(r.read().decode())
                if data.get("done"):
                    return data.get("response", {}).get("assetId")
        except Exception:
            pass
        time.sleep(2)
    return None


def upload_one(path: str, display_name: str, description: str) -> str | None:
    with open(path, "rb") as f:
        file_bytes = f.read()

    boundary = uuid.uuid4().hex
    meta = json.dumps({
        "assetType": "Audio",
        "displayName": display_name,
        "description": description,
        "creationContext": {"creator": {"userId": USER_ID}},
    })

    body = b""
    body += f"--{boundary}\r\n".encode()
    body += b'Content-Disposition: form-data; name="request"\r\n'
    body += b"Content-Type: application/json\r\n\r\n"
    body += meta.encode() + b"\r\n"
    body += f"--{boundary}\r\n".encode()
    body += (b'Content-Disposition: form-data; name="fileContent"; filename="'
             + os.path.basename(path).encode() + b'"\r\n')
    body += b"Content-Type: audio/mpeg\r\n\r\n"
    body += file_bytes + b"\r\n"
    body += f"--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        ASSETS_URL, data=body,
        headers={"x-api-key": API_KEY,
                 "Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            data = json.loads(r.read().decode())
            if data.get("assetId"):
                return str(data["assetId"])
            op = data.get("operationId")
            return poll_operation(op) if op else None
    except urllib.error.HTTPError as e:
        print(f"    HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:200]}")
        return None
    except Exception as e:
        print(f"    {type(e).__name__}: {e}")
        return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Upload Zundamon voicelines to Roblox")
    ap.add_argument("--check", action="store_true", help="validate credentials and exit")
    ap.add_argument("--dry-run", action="store_true", help="list pending uploads")
    ap.add_argument("--only", help="only keys starting with this prefix")
    ap.add_argument("--force", action="store_true", help="re-upload even if asset_id exists")
    args = ap.parse_args()

    if args.check:
        return 0 if check_credentials() else 1

    data = load_manifest()
    clips = data["clips"]
    if args.only:
        clips = [c for c in clips if c["key"].startswith(args.only)]

    pending = [c for c in clips if args.force or not c.get("asset_id")]
    done = len(clips) - len(pending)

    if args.dry_run:
        print(f"{len(pending)} pending, {done} already uploaded")
        for c in pending:
            print(f"  {c['key']:24s} {c.get('mp3', '(no mp3!)')}")
        return 0

    if not pending:
        print(f"nothing to do — all {len(clips)} clips already have asset IDs")
        return 0

    if not check_credentials():
        return 1

    print(f"uploading {len(pending)} clip(s)...\n")
    ok, fail = 0, 0
    try:
        for c in pending:
            mp3 = c.get("mp3")
            if not mp3:
                print(f"  SKIP {c['key']}: no mp3 (re-run the worker without --no-mp3)")
                fail += 1
                continue
            path = os.path.join(OUT_DIR, mp3)
            asset_id = upload_one(
                path,
                display_name=f"zunda_vo_{c['key']}",
                description=f"{c['text']} | VOICEVOX:ずんだもん | moment={c['moment']}",
            )
            if asset_id:
                c["asset_id"] = asset_id
                ok += 1
                print(f"  ok   {c['key']:24s} -> {asset_id}")
            else:
                fail += 1
                print(f"  FAIL {c['key']}")
            save_manifest(data)  # checkpoint after each, so a crash keeps progress
            time.sleep(DELAY_BETWEEN_UPLOADS)
    except KeyboardInterrupt:
        print("\ninterrupted — progress saved to manifest")

    save_manifest(data)
    print(f"\n{ok} uploaded, {fail} failed. manifest: {MANIFEST}")
    if ok:
        print("NOTE: uploaded audio goes through Roblox moderation and may not be "
              "playable immediately.")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
