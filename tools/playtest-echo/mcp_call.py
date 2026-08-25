#!/usr/bin/env python3
"""Minimal MCP client for robloxstudio-mcp (streamable HTTP, port 58741).

Usage: python mcp_call.py <tool_name> [json_arguments]
"""
import json
import sys
import urllib.request

URL = "http://localhost:58741/mcp"
TOKEN = open(r"C:\Users\froma\.robloxstudio-mcp\auth-token").read().strip()
HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json, text/event-stream",
    "Authorization": f"Bearer {TOKEN}",
}
_session_id = None


def _post(payload):
    global _session_id
    req = urllib.request.Request(URL, data=json.dumps(payload).encode(), headers=HEADERS)
    if _session_id:
        req.add_header("Mcp-Session-Id", _session_id)
    resp = urllib.request.urlopen(req, timeout=120)
    sid = resp.headers.get("Mcp-Session-Id")
    if sid:
        _session_id = sid
    raw = resp.read().decode("utf-8", errors="replace")
    # streamable HTTP may return SSE or an empty 202; extract the data line(s)
    if not raw.strip():
        return {}
    if raw.lstrip().startswith("event:"):
        for line in raw.splitlines():
            if line.startswith("data:"):
                return json.loads(line[5:].strip())
        return None
    return json.loads(raw)


def call(tool, arguments):
    _post({"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {
        "protocolVersion": "2024-11-05", "capabilities": {},
        "clientInfo": {"name": "hermes", "version": "1.0"}}})
    result = _post({"jsonrpc": "2.0", "id": 1, "method": "tools/call",
                    "params": {"name": tool, "arguments": arguments}})
    if not isinstance(result, dict) or not result:
        # notification-only response (e.g. long-running action); poll logs separately
        return "(no immediate response — action dispatched)"
    content = result.get("result", {}).get("content", [])
    texts = [c.get("text", "") for c in content if c.get("type") == "text"]
    return "\n".join(texts)


if __name__ == "__main__":
    tool = sys.argv[1]
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    print(call(tool, args))
