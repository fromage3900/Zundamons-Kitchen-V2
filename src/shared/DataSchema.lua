local DataSchema = {
	-- Starter Pack for new players
	Gold = 100,
	
	-- Inventory Mapping (ItemName -> Quantity)
	Inventory = {
		["Basic Pan"] = 1,
		["Apple"] = 5,
	},

	-- Unlocked Recipes
	UnlockedRecipes = {
		["Zunda Apple Pie"] = true,
	},

	-- Meta progression
	ChefLevel = 1,
	Experience = 0,
}

return DataSchema
