#!/usr/bin/env python3
"""Live echo run: inject capture, start playtest, sample, dump trace to runs/."""
import json
import sys
import time

import mcp_call

INSTANCE = "place:102953611950557"


def main():
    duration = float(sys.argv[1]) if len(sys.argv) > 1 else 40.0

    # 1. inject fresh capture module into edit context (it propagates to playtest spawn)
    code = open("capture.luau", encoding="utf-8").read()
    mcp_call.call("execute_luau", {"code": code, "instance_id": INSTANCE})

    # 2. start echo in edit context (LogService of edit captures plugin+edit errors)
    out = json.loads(mcp_call.call("execute_luau", {
        "code": 'return {s = _G.PlaytestEcho.start()}',
        "instance_id": INSTANCE}))["returnValue"]
    session = json.loads(out)["s"]
    print(f"echo session {session} started")

    # 3. start solo playtest
    try:
        mcp_call._post({"jsonrpc": "2.0", "id": 9, "method": "tools/call",
                        "params": {"name": "solo_playtest", "arguments": {
                            "instance_id": INSTANCE, "action": "start", "mode": "play"}}})
        print("playtest start dispatched")
    except Exception as exc:  # playtest may already be running
        print(f"playtest start: {exc}")

    print(f"capturing for {duration}s ...")
    time.sleep(duration)

    # 4. stop + dump
    out = mcp_call.call("execute_luau", {
        "code": 'local t = _G.PlaytestEcho.stop(); return {j = game:GetService("HttpService"):JSONEncode(t)}',
        "instance_id": INSTANCE})
    trace = json.loads(json.loads(json.loads(out)["returnValue"])["j"])
    trace = trace if isinstance(trace, dict) else json.loads(trace)
    # normalize double-encoding
    if isinstance(trace, str):
        trace = json.loads(trace)

    path = f"runs/{trace['session_id'][:8]}.json"
    open(path, "w").write(json.dumps(trace, indent=2))
    print(f"saved {path}: {trace['duration_s']}s, "
          f"{len(trace['errors'])} errors, {len(trace['warnings'])} warnings, "
          f"{len(trace['state_samples'])} samples")
    for e in trace["errors"][:10]:
        print(f"  ERR [{e['script']}] {e['message'][:110]}")


if __name__ == "__main__":
    main()
