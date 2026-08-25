-- Injector: create a LocalScript in the real game VM, read back its report.
-- Run via execute_luau target=client-1. The inner LocalScript shares the game's
-- require cache, so it sees the REAL UIActionRegistry state (unlike direct
-- execute_luau, which gets its own module copy — proven by queued-dispatch warns).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- clean stale artifacts from earlier attempts
for _, n in ipairs({ "EchoVerifyScript", "EchoVerifyResult" }) do
	local old = pg:FindFirstChild(n)
	if old then
		old:Destroy()
	end
end

local src = [==[
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local out = {}
local ok, err = pcall(function()
	local reg = require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))
	local acts = {}
	for _, id in ipairs(reg.getAllActions()) do
		local def = reg.getAction(id)
		local key = reg.getBinding(id)
		acts[id] = {
			key = key and key.Name or "(none)",
			hasCallback = type(def.callback) == "function",
		}
	end
	out.actions = acts
	-- reverse map consistency (key -> action)
	local reverseOk = true
	for id, info in pairs(acts) do
		if info.key ~= "(none)" and reg.getActionByKey(Enum.KeyCode[info.key]) ~= id then
			reverseOk = false
		end
	end
	out.reverseMapConsistent = reverseOk
	-- Issue 4 live toggle: settings open + close via the registry (same path the
	-- InputBegan dispatcher and HUD button use)
	local sg = pg:WaitForChild("SettingsScreenGui", 5)
	out.settingsGuiFound = sg ~= nil
	if sg then
		local before = sg.Enabled
		reg.dispatch("settings")
		task.wait(0.7)
		local afterOpen = sg.Enabled
		reg.dispatch("settings")
		task.wait(0.9)
		local afterClose = sg.Enabled
		out.settingsToggle = { before = before, afterOpen = afterOpen, afterClose = afterClose,
			works = (afterOpen ~= before) and (afterClose == before) }
	end
	-- legacy overlay shells that 000_LegacyOverlayCleanup should have removed
	local legacy = {}
	for _, gui in ipairs(pg:GetChildren()) do
		local n = string.lower(gui.Name)
		if string.find(n, "legacy", 1, true) or string.find(n, "vignette", 1, true) then
			table.insert(legacy, gui.Name)
		end
	end
	out.legacyOverlaysAlive = legacy
end)
out.ok = ok
out.err = err and tostring(err) or nil
local sv = Instance.new("StringValue")
sv.Name = "EchoVerifyResult"
sv.Value = HttpService:JSONEncode(out)
sv.Parent = pg
]==]

local ls = Instance.new("LocalScript")
ls.Name = "EchoVerifyScript"
local okSrc, errSrc = pcall(function()
	ls.Source = src
end)
if not okSrc then
	return { j = HttpService:JSONEncode({ ok = false, err = "Source write denied: " .. tostring(errSrc) }) }
end
ls.Parent = pg

local sv = pg:WaitForChild("EchoVerifyResult", 15)
local result = sv and sv.Value or '{"ok":false,"err":"result timeout - LocalScript never reported"}'
ls:Destroy()
if sv then
	sv:Destroy()
end
return { j = result }
