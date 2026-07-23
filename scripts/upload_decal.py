import os, sys, json, urllib.request, uuid, time

API_KEY = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "")
USER_ID = os.environ.get("ROBLOX_CREATOR_USER_ID", "3930496852")

if not API_KEY:
    print("ROBLOX_OPEN_CLOUD_API_KEY not set")
    sys.exit(1)

file_path = sys.argv[1]
display_name = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(file_path))[0]
description = sys.argv[3] if len(sys.argv) > 3 else ""

with open(file_path, "rb") as f:
    file_bytes = f.read()

boundary = uuid.uuid4().hex
req_body = b""

req_part = json.dumps({
    "assetType": "Decal",
    "displayName": display_name,
    "description": description,
    "creationContext": {
        "creator": {
            "userId": USER_ID
        }
    }
})

req_body += f"--{boundary}\r\n".encode()
req_body += b'Content-Disposition: form-data; name="request"\r\n'
req_body += b"Content-Type: application/json\r\n\r\n"
req_body += req_part.encode() + b"\r\n"

req_body += f"--{boundary}\r\n".encode()
req_body += b'Content-Disposition: form-data; name="fileContent"; filename="' + os.path.basename(file_path).encode() + b'"\r\n'
req_body += b"Content-Type: image/png\r\n\r\n"
req_body += file_bytes + b"\r\n"

req_body += f"--{boundary}--\r\n".encode()

req = urllib.request.Request(
    "https://apis.roblox.com/assets/v1/assets",
    data=req_body,
    headers={
        "x-api-key": API_KEY,
        "Content-Type": f"multipart/form-data; boundary={boundary}"
    },
    method="POST"
)

def poll_operation(op_id):
    for i in range(30):
        poll_req = urllib.request.Request(
            f"https://apis.roblox.com/assets/v1/operations/{op_id}",
            headers={"x-api-key": API_KEY}
        )
        try:
            with urllib.request.urlopen(poll_req) as pr:
                data = json.loads(pr.read().decode())
                done = data.get("done", False)
                if done:
                    response = data.get("response", {})
                    asset_id = response.get("assetId", "?")
                    print(asset_id)
                    return True
                else:
                    time.sleep(2)
        except Exception as e:
            print(f"POLL_ERROR: {e}")
            time.sleep(2)
    print(f"TIMEOUT polling {op_id}")
    return False

try:
    with urllib.request.urlopen(req, timeout=120) as resp:
        body = resp.read().decode()
        status = resp.status
        if status in (200, 201):
            data = json.loads(body)
            aid = data.get("assetId")
            if aid:
                print(aid)
            else:
                op = data.get("operationId")
                if op:
                    poll_operation(op)
                else:
                    print(f"UNKNOWN: {body}")
        elif status == 202:
            op = json.loads(body).get("operationId", "?")
            poll_operation(op)
        else:
            print(f"ERROR {status}: {body}")
            sys.exit(1)
except urllib.error.HTTPError as e:
    print(f"HTTP {e.code}: {e.read().decode()}")
    sys.exit(1)
except Exception as e:
    print(f"EXCEPTION: {e}")
    sys.exit(1)
