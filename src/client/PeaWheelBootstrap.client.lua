-- [[LocalScript] PeaWheelBootstrap]]
-- Registers Pea Wheel action callbacks with existing panel scripts.
-- Keeps all panel logic intact; only wires the Pea Wheel to their toggle functions.

local Players = game:GetService("Players")

local ActionRegistry = require(script.Parent.ConfigurationFiles.UIActionRegistry)
local PeaWheel = require(script.Parent.Controllers.PeaWheelController)

local function requireClientScript(name)
	local playerScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then
		warn("[PeaWheelBootstrap] PlayerScripts not found for " .. name)
		return nil
	end
	local script = playerScripts:FindFirstChild(name)
	if not script then
		warn("[PeaWheelBootstrap] Script not found: " .. name)
		return nil
	end
	return require(script)
end

-- Helper: register a callback if the module exposes a toggle/open function
local function bindPanel(actionId, mod, toggleName)
	if type(mod) ~= "table" then
		warn("[PeaWheelBootstrap] Missing module for " .. actionId)
		return
	end
	local fn = mod[toggleName] or mod.toggle or mod.open
	if type(fn) ~= "function" then
		warn("[PeaWheelBootstrap] No toggle function found for " .. actionId)
		return
	end
	ActionRegistry.registerCallback(actionId, function()
		fn()
	end)
	print("[PeaWheelBootstrap] Bound " .. actionId)
end

-- Panel bindings
bindPanel("inventory",  requireClientScript("PouchScript"),        "toggle")
bindPanel("quests",     requireClientScript("QuestScript"),        "toggle")
bindPanel("compendium", requireClientScript("CompendiumScript"),   "toggle")
bindPanel("map",        requireClientScript("MinimapScript"),      "toggle")
bindPanel("settings",   requireClientScript("SettingsScreen"),     "toggle")
bindPanel("materials",  requireClientScript("MaterialsScript"),    "toggle")
bindPanel("companions", requireClientScript("CompanionShopScript"), "toggle")
bindPanel("cook",       requireClientScript("CookingController"),  "start")

print("[PeaWheelBootstrap] All action callbacks registered")
