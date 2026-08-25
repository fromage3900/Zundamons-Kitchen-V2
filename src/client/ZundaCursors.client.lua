-- [[LocalScript] ZundaCursors]
-- Central cursor controller for the Zundamon cursor set (wappon_28_dev, MIT).
-- The uploaded Decal asset IDs live in ReplicatedStorage.ConfigurationFiles.CursorConfig.
-- Exposes _G.ZundaCursors.setCursor(name) / push(name) / pop() so any client
-- feature can temporarily swap the OS-style cursor (Photo Mode, perfect-cook
-- beat, guest interaction, etc.) and automatically restore the last one.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local CursorConfig = require(RS.ConfigurationFiles.CursorConfig)
local mouse = player:GetMouse()

-- Roblox supports Player.MouseIcon (string asset id). Older clients only respect
-- the Mouse object's .Icon, so write both; whichever the runtime honors wins.
local function applyRaw(cursorValue: string)
	player.MouseIcon = cursorValue
	if mouse then
		mouse.Icon = cursorValue
	end
end

local cursorStack: { string } = {}

-- The persistent "base" cursor is the zunda normal arrow. Push the empty
-- default onto the stack so pop() always bottoms out here instead of blank.
local BASE = CursorConfig.getCursor("normal") or ""

local function pushCursor(cursorValue: string)
	table.insert(cursorStack, cursorValue)
	applyRaw(cursorValue)
end

local function popCursor()
	if #cursorStack > 1 then
		table.remove(cursorStack)
		applyRaw(cursorStack[#cursorStack])
	else
		applyRaw(BASE)
	end
end

-- Set a named cursor by CursorConfig key (e.g. "cross", "move", "person").
local function named(name: string)
	local val = CursorConfig.getCursor(name)
	if val and val ~= "" then
		pushCursor(val)
	else
		pushCursor(BASE)
	end
end

-- Set an explicit raw rbxassetid string, bypassing the config table.
local function raw(cursorValue: string)
	if typeof(cursorValue) == "string" then
		pushCursor(cursorValue)
	end
end

local ZundaCursors = {
	setCursor = named,
	setRaw = raw,
	push = pushCursor,
	pop = popCursor,
	restore = function()
		applyRaw(cursorStack[#cursorStack] or BASE)
	end,
	BASE = BASE,
}

_G.ZundaCursors = ZundaCursors

-- Bootstrap: start the game on the default Zunda arrow.
applyRaw(BASE)

print("[ZundaCursors] Ready — base cursor: " .. (BASE == "" and "default" or "zunda/normal"))
