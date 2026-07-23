--!strict
-- LegacyGuiConfig: Studio ScreenGuis to remove at runtime (Rojo replaces these).
-- See docs/studio-legacy-ui-deletion.md for Editor deletion checklist.

local LegacyGuiConfig = {}

-- Vignette / post-process overlays (full ScreenGui destroy).
LegacyGuiConfig.destroyScreenGuis = {
	"ZundaFX",
	"PostProcessOverlay",
	-- Dead-generation Studio shells confirmed live 2026-07-23 (superseded by the
	-- PeaWheel/ActionRegistry UI; the custom hotbar is non-functional — the
	-- default Roblox backpack is the real tool bar):
	"Custom Inventory",
	"ToolsGUI",
	"Tools",
	"SellLoot",
	"PlanterGui",
	"DataGUI",
	"ProgressionPanel",
	"MaterialsInventory", -- duplicate of MaterialsGui
	"ZundaFrame", -- Studio border-decal shell; reads as screen clutter (2026-07-23)
}

-- Descendant names removed anywhere under PlayerGui (watercolour vignette layers).
LegacyGuiConfig.destroyDescendantNames = {
	"WatercolourBleed",
	"Vignette",
	"GrainLayer",
	"NoiseImage",
}

-- Studio StarterGui shells: delete in Editor AND torn down if they clone to PlayerGui.
-- Rojo bootstrap scripts recreate these under PlayerGui (often with new names).
LegacyGuiConfig.destroyLegacyStarterShells = {
	"ZundaVN",
	"ZundaPouch",
	"QuestPanel",
	"CompanionShop",
	"ZundaShop",
}

-- Deprecated alias (use destroyLegacyStarterShells).
LegacyGuiConfig.destroyLegacyBootstrapShells = LegacyGuiConfig.destroyLegacyStarterShells

-- Legacy VN shell from Studio; VNController builds ZundaVNGui in code.
LegacyGuiConfig.destroyLegacyVnShell = true

return LegacyGuiConfig
