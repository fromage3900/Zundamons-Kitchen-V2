#!/usr/bin/env python3
"""StudioMCP stdio client helper for the Zundamon's Kitchen V2 playtest.

Wraps the chrrxs robloxstudio-mcp (the surface the echo pipeline README
documents) over stdio. Usage:
    from studio_mcp import StudioMCP
    m = StudioMCP()
    m.initialize()
    r = m.call("execute_luau", {"code": "return 1"})
    print(r)
"""
import json, os, subprocess, threading, time, sys

# chrrxs robloxstudio-mcp installed in npm cache
_DIST = r"C:\Users\froma\AppData\Local\npm-cache\_npx\0969bd0ae5ba7ffb\node_modules\@chrrxs\robloxstudio-mcp\dist\index.js"
_NODE = r"C:\Program Files\nodejs\node.exe"

class StudioMCP:
    def __init__(self, timeout=30):
        self.proc = subprocess.Popen(
            [_NODE, _DIST, "--auto-install-plugin"],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            bufsize=1, universal_newlines=True)
        self._id = 0
        self._lock = threading.Lock()
        self._timeout = timeout
        self._queue = []
        self._cv = threading.Condition()
        t = threading.Thread(target=self._reader, daemon=True)
        t.start()

    def _reader(self):
        while True:
            line = self.proc.stdout.readline()
            if not line:
                break
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except Exception:
                continue
            with self._cv:
                self._queue.append(obj)
                self._cv.notify_all()

    def _send(self, obj):
        with self._lock:
            self.proc.stdin.write(json.dumps(obj) + "\n")
            self.proc.stdin.flush()

    def _read_id(self, target, timeout=None):
        timeout = timeout or self._timeout
        deadline = time.time() + timeout
        while time.time() < deadline:
            with self._cv:
                for i, obj in enumerate(self._queue):
                    if obj.get("id") == target:
                        del self._queue[i]
                        return obj
                self._cv.wait(0.2)
        return None

    def initialize(self):
        self._id += 1
        i = self._id
        self._send({"jsonrpc":"2.0","id":i,"method":"initialize",
            "params":{"protocolVersion":"2024-11-05","capabilities":{},
                      "clientInfo":{"name":"hermes-probe","version":"1.0"}}})
        r = self._read_id(i)
        if not r:
            raise RuntimeError("no initialize response")
        self._send({"jsonrpc":"2.0","method":"notifications/initialized","params":{}})
        return r

    def call(self, name, arguments=None, timeout=None):
        self._id += 1
        i = self._id
        self._send({"jsonrpc":"2.0","id":i,"method":"tools/call",
            "params":{"name":name,"arguments":arguments or {}}})
        r = self._read_id(i, timeout)
        if r is None:
            return {"_err": f"timeout waiting for {name}"}
        # Flatten text content for convenience
        try:
            c = r["result"]["content"]
            txt = "".join(x.get("text","") for x in c if isinstance(x,dict))
            r["_text"] = txt
        except Exception:
            pass
        return r

    def close(self):
        try:
            self.proc.terminate()
        except Exception:
            pass

if __name__ == "__main__":
    m = StudioMCP()
    m.initialize()
    print(json.dumps(m.call("get_place_info", {}), indent=2)[:2000])
    m.close()

