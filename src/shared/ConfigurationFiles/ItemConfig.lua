-- [[ModuleScript] ItemConfig (ref: RBX33E6DFB0DAC343DFADE9E3960C058F0E)]]
-- ItemConfig: Central registry for all item definitions
-- Used by admin menus and shops for easy customization

local ItemConfig = {
	items = {
		-- Farmable items (gathered from plants in garden/forest)
		zunda_flower = {
			id = "zunda_flower",
			name = "Zunda Flower",
			type = "farmable",
			icon = "🜻",
			description = "A beautiful purple flower",
			rarity = 1,
			base_value = 10,
		},
		zunda_pea = {
			id = "zunda_pea",
			name = "Zunda Pea",
			type = "farmable",
			icon = "🝒",
			description = "Plump and nutritious",
			rarity = 1,
			base_value = 15,
		},
		zunda_mushroom = {
			id = "zunda_mushroom",
			name = "Zunda Mushroom",
			type = "farmable",
			icon = "🝄",
			description = "A rare forest fungus",
			rarity = 2,
			base_value = 25,
		},
		zunda_berry = {
			id = "zunda_berry",
			name = "Zunda Berry",
			type = "farmable",
			icon = "🝛",
			description = "Sweet and tangy",
			rarity = 2,
			base_value = 20,
		},
		zunda_root = {
			id = "zunda_root",
			name = "Zunda Root",
			type = "farmable",
			icon = "💀",
			description = "Earthy and aromatic",
			rarity = 2,
			base_value = 22,
		},

		-- Mineable items
		copper_ore = {
			id = "copper_ore",
			name = "Copper Ore",
			type = "mineable",
			icon = "📟",
			description = "Raw copper",
			rarity = 1,
			base_value = 5,
		},
	},
}

return ItemConfig
