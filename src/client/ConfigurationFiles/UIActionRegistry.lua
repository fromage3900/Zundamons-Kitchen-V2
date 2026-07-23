--!strict
-- [[ModuleScript] UI_ActionRegistry]]
-- Canonical action definitions for the Pea Wheel and global HUD.
-- Each action carries: id, label, icon, bindings, availability, and callback adapter.
-- No script should hardcode these bindings elsewhere.

local UI_ActionRegistry = {}
local actions = {}
local keyToAction = {}
local currentBindings = {}
local pendingDispatches: { [string]: boolean } = {}
local PENDING_TTL = 8

-- ── Helpers ──────────────────────────────────────────────────
local function bindKey(actionId, keyCode)
	if keyCode == nil then return end
	if keyToAction[keyCode] and keyToAction[keyCode] ~= actionId then
		warn(("[UI_ActionRegistry] Key %s rebound from %s to %s"):format(
			tostring(keyCode):gsub("Enum.KeyCode.", ""),
			keyToAction[keyCode],
			actionId
		))
	end
	keyToAction[keyCode] = actionId
	currentBindings[actionId] = keyCode
end

local function isActionAvailable(actionId): boolean
	local def = actions[actionId]
	if not def then return false end
	if type(def.isAvailable) == "function" then
		return def.isAvailable()
	end
	return true
end

-- ── Canonical Action Definitions ─────────────────────────────
-- 8 Pea Wheel slices per UI_UX_OVERHAUL_PLAN.md
-- @type { { id: string, label: string, icon: string, description: string, defaultKey: Enum.KeyCode?, category: string, isAvailable: () -> boolean, callback: (() -> ())? } }
local DEFAULTS: { { id: string, label: string, icon: string, description: string, defaultKey: Enum.KeyCode?, category: string, isAvailable: () -> boolean, callback: (() -> ())? } } = {
	{
		id = "inventory",
		label = "Pouch",
		icon = "🎒",
		description = "Open your item pouch",
		defaultKey = Enum.KeyCode.I,
		category = "Inventory",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "cook",
		label = "Cook",
		icon = "🍳",
		description = "Open cooking station",
		defaultKey = Enum.KeyCode.K,
		category = "Gameplay",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "quests",
		label = "Quests",
		icon = "📜",
		description = "View active quests",
		defaultKey = Enum.KeyCode.J,
		category = "Exploration",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "compendium",
		label = "Collection",
		icon = "📖",
		description = "Open recipe & item compendium",
		defaultKey = Enum.KeyCode.C,
		category = "Reference",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "materials",
		label = "Materials",
		icon = "🧺",
		description = "View gathered materials",
		defaultKey = nil :: Enum.KeyCode?,
		category = "Inventory",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "map",
		label = "Map",
		icon = "🗺️",
		description = "Toggle world map",
		defaultKey = Enum.KeyCode.M,
		category = "Exploration",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "companions",
		label = "Companions",
		icon = "🌸",
		description = "Manage your Zunda companions",
		defaultKey = nil :: Enum.KeyCode?,
		category = "Progression",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "settings",
		label = "Settings",
		icon = "⚙",
		description = "Open settings & keybinds",
		-- Settings opens via the Pea Wheel slice and HUD button (both dispatch()).
		-- F1 is reserved for the Keybinds help panel to avoid a double-bind.
		defaultKey = nil :: Enum.KeyCode?,
		category = "System",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "peawheel",
		label = "Pea Wheel",
		icon = "🌱",
		description = "Toggle the radial quick-action wheel",
		-- Not a Pea Wheel slice itself — this is the wheel's own open/close toggle,
		-- previously a rogue listener inside PeaWheelController bypassing this registry.
		defaultKey = Enum.KeyCode.Tab,
		category = "System",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
	{
		id = "wardrobe",
		label = "Wardrobe",
		icon = "👗",
		description = "Open your outfit wardrobe",
		-- No default key: every obvious letter is already claimed by another
		-- action. Button-only for now (was a rogue K listener that double-fired
		-- alongside "cook").
		defaultKey = nil :: Enum.KeyCode?,
		category = "Inventory",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
}

-- ── Initialization ───────────────────────────────────────────
for _, def in ipairs(DEFAULTS) do
	actions[def.id] = def
	bindKey(def.id, def.defaultKey)
end

-- ── Central keyboard dispatch (SINGLE SOURCE OF TRUTH) ────────
-- Exactly one listener turns any bound key into dispatch(actionId). No other script
-- should listen for panel hotkeys — panels expose behaviour via registerCallback().
-- This module is a cached ModuleScript, so this connects exactly once.
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if UserInputService:GetFocusedTextBox() ~= nil then return end
	local actionId = keyToAction[input.KeyCode]
	if actionId then
		-- Dispatch even when gameProcessed: the core Backpack CoreScript sinks
		-- our I bind (marks it processed), which silently killed the hotkey.
		-- Textbox focus is checked above, so typing never triggers actions.
		UI_ActionRegistry.dispatch(actionId)
	end
end)

-- ── Public API ───────────────────────────────────────────────
function UI_ActionRegistry.getAction(id: string)
	return actions[id]
end

function UI_ActionRegistry.getAllActions()
	local list = {}
	for id, _ in pairs(actions) do
		table.insert(list, id)
	end
	return list
end

function UI_ActionRegistry.getBinding(actionId: string): Enum.KeyCode?
	return currentBindings[actionId]
end

function UI_ActionRegistry.setBinding(actionId: string, keyCode: Enum.KeyCode?)
	local def = actions[actionId]
	if not def then return end
	bindKey(actionId, keyCode)
end

function UI_ActionRegistry.getActionByKey(keyCode: Enum.KeyCode): string?
	return keyToAction[keyCode]
end

function UI_ActionRegistry.isAvailable(actionId: string): boolean
	return isActionAvailable(actionId)
end

function UI_ActionRegistry.dispatch(actionId: string): boolean
	local def = actions[actionId]
	if not def then
		warn("[UI_ActionRegistry] Unknown action: " .. tostring(actionId))
		return false
	end
	if not isActionAvailable(actionId) then
		warn("[UI_ActionRegistry] Action unavailable: " .. actionId)
		return false
	end
	if type(def.callback) == "function" then
		def.callback()
		return true
	end
	-- Panel scripts register their callback whenever they finish loading, with
	-- no ordering guarantee vs. HUD/Pea Wheel bootstrap — a click that lands
	-- before that happens used to be silently, permanently dropped. Queue it
	-- instead so registerCallback() can auto-fire it once the panel is ready.
	warn("[UI_ActionRegistry] No callback registered for: " .. actionId .. " — queuing dispatch")
	pendingDispatches[actionId] = true
	task.delay(PENDING_TTL, function()
		if pendingDispatches[actionId] then
			pendingDispatches[actionId] = nil
			warn("[UI_ActionRegistry] Dispatch for " .. actionId .. " expired after " .. PENDING_TTL .. "s — panel never registered a callback")
		end
	end)
	return false
end

function UI_ActionRegistry.registerCallback(actionId: string, fn: () -> ())
	local def = actions[actionId]
	if not def then
		warn("[UI_ActionRegistry] Cannot register callback — unknown action: " .. actionId)
		return
	end
	def.callback = fn
	if pendingDispatches[actionId] then
		pendingDispatches[actionId] = nil
		fn()
	end
end

function UI_ActionRegistry.getOrderedSliceList(): {string}
	return {
		"inventory",
		"cook",
		"quests",
		"compendium",
		"materials",
		"map",
		"companions",
		"settings",
	}
end

return UI_ActionRegistry