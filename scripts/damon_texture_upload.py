#!/usr/bin/env python3
"""
Roblox Damon Texture Uploader — Zundamon's Kitchen V2

Batch-uploads generated damon card PNG textures to Roblox via Open Cloud
and records the resulting asset IDs back into scripts/damon_textures/manifest.json.

Pipeline:
    1. Generate:  python scripts/damon_texture_gen.py --all
    2. Upload:    python scripts/damon_texture_upload.py --all
    3. Emit:      python scripts/emit_damon_texture_config.py

Usage:
    python scripts/damon_texture_upload.py --check          # validate credentials only
    python scripts/damon_texture_upload.py --dry-run        # show what would upload
    python scripts/damon_texture_upload.py --all            # upload all pending textures
    python scripts/damon_texture_upload.py --key zundamon   # upload single texture
    python scripts/damon_texture_upload.py --force --all    # force re-upload
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPTS_DIR / "damon_textures"
MANIFEST = OUT_DIR / "manifest.json"
EMIT_SCRIPT = SCRIPTS_DIR / "emit_damon_texture_config.py"

API_KEY = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "")
USER_ID = os.environ.get("ROBLOX_CREATOR_USER_ID", "")

ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPS_URL = "https://apis.roblox.com/assets/v1/operations/{}"

# Pacing between uploads to respect Open Cloud rate limits
DELAY_BETWEEN_UPLOADS = 1.5


def load_manifest() -> dict:
    if not MANIFEST.exists():
        print(f"ERROR: {MANIFEST} not found. Run damon_texture_gen.py first.")
        sys.exit(1)
    with open(MANIFEST, "r", encoding="utf-8") as f:
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


def upload_one(path: Path, display_name: str, description: str) -> str | None:
    with open(path, "rb") as f:
        file_bytes = f.read()

    boundary = uuid.uuid4().hex
    meta = json.dumps({
        "assetType": "Decal",
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
    body += (
        b'Content-Disposition: form-data; name="fileContent"; filename="'
        + path.name.encode()
        + b'"\r\n'
    )
    body += b"Content-Type: image/png\r\n\r\n"
    body += file_bytes + b"\r\n"
    body += f"--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        ASSETS_URL,
        data=body,
        headers={
            "x-api-key": API_KEY,
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
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
    ap = argparse.ArgumentParser(description="Upload Damon Card textures to Roblox")
    ap.add_argument("--all", action="store_true", help="upload all pending textures")
    ap.add_argument("--key", help="upload texture for a specific companion key")
    ap.add_argument("--check", action="store_true", help="validate credentials and exit")
    ap.add_argument("--dry-run", action="store_true", help="list pending uploads")
    ap.add_argument("--force", action="store_true", help="re-upload even if asset_id exists")
    args = ap.parse_args()

    if args.check:
        return 0 if check_credentials() else 1

    manifest = load_manifest()

    if args.key:
        target_keys = [args.key]
    elif args.all or args.dry_run:
        target_keys = list(manifest.keys())
    else:
        print("Please specify --all, --key <key>, --dry-run, or --check.")
        return 1

    pending = [k for k in target_keys if args.force or not manifest.get(k)]
    done = len(target_keys) - len(pending)

    if args.dry_run:
        print(f"{len(pending)} pending, {done} already uploaded (of {len(target_keys)} targeted)")
        for k in pending:
            png_path = OUT_DIR / f"{k}.png"
            status = "exists" if png_path.exists() else "MISSING PNG"
            print(f"  {k:24s} [{status}]")
        return 0

    if not pending:
        print(f"nothing to do — all {len(target_keys)} textures already have asset IDs")
        return 0

    if not check_credentials():
        return 1

    print(f"uploading {len(pending)} texture(s)...\n")
    ok, fail = 0, 0
    try:
        for k in pending:
            png_path = OUT_DIR / f"{k}.png"
            if not png_path.exists():
                print(f"  SKIP {k}: {png_path.name} not found (run damon_texture_gen.py first)")
                fail += 1
                continue
            asset_id = upload_one(
                png_path,
                display_name=f"damon_card_{k}",
                description=f"Damon card texture for {k} | Zundamon's Kitchen V2",
            )
            if asset_id:
                manifest[k] = asset_id
                ok += 1
                print(f"  ok   {k:24s} -> {asset_id}")
            else:
                fail += 1
                print(f"  FAIL {k}")
            save_manifest(manifest)
            time.sleep(DELAY_BETWEEN_UPLOADS)
    except KeyboardInterrupt:
        print("\ninterrupted — progress saved to manifest")

    save_manifest(manifest)
    print(f"\n{ok} uploaded, {fail} failed. manifest: {MANIFEST}")

    if ok > 0 and EMIT_SCRIPT.exists():
        print("\nRegenerating DamonTextureConfig.lua...")
        try:
            subprocess.run([sys.executable, str(EMIT_SCRIPT)], check=True)
        except Exception as e:
            print(f"Failed to auto-emit DamonTextureConfig.lua: {e}")

    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
