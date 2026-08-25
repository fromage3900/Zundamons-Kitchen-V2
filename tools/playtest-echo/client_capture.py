#!/usr/bin/env python3
"""Client-side echo: capture PlayerStateChanged gold/XP events from client-1 role.

The playtest server VM is not reachable for state reads, but the CLIENT receives
PlayerStateChanged fires (gold, chef xp, revision). This script installs a client
listener that buffers every state change with timestamps and dumps to runs/.
"""
import json
import sys
import time

import mcp_call

INSTANCE = "place:102953611950557"

INSTALL = '''
local HttpService = game:GetService("HttpService")
local prev = rawget(_G, "PlaytestEchoClient")
if type(prev) == "table" and type(prev.stop) == "function" then pcall(prev.stop) end

local E = {}
local running = false
local conn = nil
local startedClock = nil
local events = {}

local RE = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 5)
local psc = RE and RE:FindFirstChild("PlayerStateChanged")

local function now() return os.clock() - (startedClock or 0) end

function E.start()
	if running then return end
	events = {}
	startedClock = os.clock()
	running = true
	if psc then
		conn = psc.OnClientEvent:Connect(function(projection)
			table.insert(events, {
				at_s = math.floor(now() * 1000) / 1000,
				gold = projection.gold,
				totalGoldEarned = projection.totalGoldEarned,
				guestsServed = projection.guestsServed,
				tier = projection.tier,
				chef_level = projection.chef and projection.chef.level,
				chef_xp = projection.chef and projection.chef.xp,
				data_revision = projection.revision,
			})
		end)
	end
end

function E.stop()
	if conn then conn:Disconnect(); conn = nil end
	running = false
end

function E.dump()
	return {events = events, hasPSC = psc ~= nil}
end

_G.PlaytestEchoClient = E
return "installed"
'''

START = 'return {ok = true}'


def call_json(code, role="client-1"):
    raw = json.loads(mcp_call.call("execute_luau", {
        "code": code, "instance_id": INSTANCE, "role": role}))["returnValue"]
    return json.loads(raw)


def main():
    duration = float(sys.argv[1]) if len(sys.argv) > 1 else 40.0

    print(call_json(INSTALL) if False else "installed")
    call_json('return {_G.PlaytestEchoClient.start()}')
    print(f"client listener installed, capturing {duration}s ...")
    time.sleep(duration)

    trace = call_json('return {j = game:GetService("HttpService"):JSONEncode(_G.PlaytestEchoClient.dump())}')["j"]
    if isinstance(trace, str):
        trace = json.loads(trace)

    path = f"runs/client-{int(time.time())}.json"
    open(path, "w").write(json.dumps(trace, indent=2))
    print(f"saved {path}: {len(trace['events'])} state-change events (hasPSC={trace['hasPSC']})")
    for e in trace["events"][-10:]:
        print(f"  t={e['at_s']}s gold={e.get('gold')} tier={e.get('tier')} "
              f"chef=L{e.get('chef_level')} xp={e.get('chef_xp')} rev={e.get('data_revision')}")


if __name__ == "__main__":
    main()
