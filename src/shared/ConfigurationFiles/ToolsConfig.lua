-- [[ModuleScript] ToolsConfig (ref: RBXFDFA7DE33CCC4656B3B95E0ADD895831)]]
local toolsconfig = {}

toolsconfig.tools = {
	["Axe"] = {
		["Tiers"] = {
			["Tier1"] = { ["Damage"] = 10 },
			["Tier2"] = { ["Damage"] = 20 },
			["Tier3"] = { ["Damage"] = 30 },
		},
		["HitSound"] = "AxeHit",
		["Swing"] = "Swing",
	},
	["PickAxe"] = {
		["Tiers"] = {
			["Tier1"] = { ["Damage"] = 10 },
			["Tier2"] = { ["Damage"] = 20 },
			["Tier3"] = { ["Damage"] = 30 },
		},
		["HitSound"] = "Smash",
		["Swing"] = "Swing",
	},
	["Sickle"] = {
		["Tiers"] = {
			["Tier1"] = { ["Damage"] = 10 },
			["Tier2"] = { ["Damage"] = 20 },
			["Tier3"] = { ["Damage"] = 30 },
		},
		["HitSound"] = "AxeHit",
		["Swing"] = "Swing",
	},
	["FishingRod"] = {
		["Tiers"] = {
			["Tier1"] = { ["Damage"] = 15 },
			["Tier2"] = { ["Damage"] = 30 },
			["Tier3"] = { ["Damage"] = 50 },
		},
		["HitSound"] = "Splash",
		["Swing"] = "Cast",
	},
}
return toolsconfig
