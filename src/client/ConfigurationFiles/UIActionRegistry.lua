--!strict
-- [[ModuleScript] UI_ActionRegistry]]
-- Canonical action definitions for the Pea Wheel and global HUD.
-- Each action carries: id, label, icon, bindings, availability, and callback adapter.
-- No script should hardcode these bindings elsewhere.

local UI_ActionRegistry = {}
local actions = {}
local keyToAction = {}
local currentBindings = {}

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
		defaultKey = nil :: Enum.KeyCode?,
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
		defaultKey = Enum.KeyCode.F1,
		category = "System",
		isAvailable = function() return true end,
		callback = nil :: (() -> ())?,
	},
}

-- ── Initialization ───────────────────────────────────────────
for _, def in ipairs(DEFAULTS) do
	actions[def.id] = def
	bindKey(def.id, def.defaultKey)
end

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
	warn("[UI_ActionRegistry] No callback registered for: " .. actionId)
	return false
end

function UI_ActionRegistry.registerCallback(actionId: string, fn: () -> ())
	local def = actions[actionId]
	if not def then
		warn("[UI_ActionRegistry] Cannot register callback — unknown action: " .. actionId)
		return
	end
	def.callback = fn
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