local UIAssets = {
	icons = {
		Wheat = "rbxassetid://97901776460551",
		["Zunda Flower"] = "rbxassetid://87686181223941",
		["Zunda Pea"] = "rbxassetid://120362830313847",
		["Zunda Berry"] = "rbxassetid://125937437843150",
		["Zunda Mushroom"] = "rbxassetid://125224584568713",
		["Zunda Root"] = "rbxassetid://139113970836923",
		Apple = "rbxassetid://71743074728666",
		Bread = "rbxassetid://83364563804673",
		Cupcake = "rbxassetid://105528539414339",
		["Apple Pie"] = "rbxassetid://106711608247900",
		["Zunda Bread"] = "rbxassetid://83376991569348",
		["Zunda Mochi"] = "rbxassetid://112971731695110",
		["Royal Stew"] = "rbxassetid://75108474150232",
		["Salted Pea Bouquet"] = "rbxassetid://134178402924202",
		["Gold Ore"] = "rbxassetid://89169959149299",
		Rock = "rbxassetid://132471180360720",
	},

	sounds = {
		-- Harvesting
		harvest_start = "rbxassetid://9113837269",
		harvest_complete = "rbxassetid://4612374495",
		craft_start = "rbxassetid://9114542867",
		craft_perfect = "rbxassetid://125367748123159",
		serve_success = "rbxassetid://81614326929268",
		level_up = "rbxassetid://9038472644",
		gather_fail = "rbxassetid://14133663945",
		ui_click = "rbxassetid://87437544236708",
		-- Weather ambience (ProSoundEffects + free assets)
		rain = "rbxassetid://9112852739",
		storm = "rbxassetid://9112794090",
		snow = "rbxassetid://9112855667",
		wind = "rbxassetid://5799870105",
		cherry_blossom = "rbxassetid://9038469951",
		aurora = "rbxassetid://9125602882",
		fog = "rbxassetid://5799870105",
		-- Kawaii interactions
		ui_hover = "rbxassetid://87437544236708",
		ui_confirm = "rbxassetid://87437544236708",
		ui_cancel = "rbxassetid://14133663945",
		craft_note_hit = "rbxassetid://125367748123159",
		companion_pet = "rbxassetid://4612374495",
		-- Thunder
		thunder = "rbxassetid://4961088919",
	},

	particles = {
		harvest_sparkle = "rbxassetid://241685484",
		craft_magic = "rbxassetid://241685484",
		serve_stars = "rbxassetid://241685484",
	},

	gui = {
		progress_bar_fill = "rbxassetid://92783213335447",
		progress_bar_border = "rbxassetid://85079237605725",
		combo_badge = "rbxassetid://123736711329002",
		panel_bg = "rbxassetid://84226376723302",
		button_primary = "rbxassetid://134975137252558",
	},

	animations = {
		harvest_loop = "rbxassetid://2510798496",
		cook_victory = "rbxassetid://2510798496",
		cook_fail = "rbxassetid://2510798496",
	},
}

function UIAssets.isPlaceholder(id: string): boolean
	if typeof(id) ~= "string" then
		return true
	end
	return id:find("FILL_") ~= nil or id:find("rbxassetid://0$") ~= nil
end

function UIAssets.getIconWithFallback(itemName: string): (string, string)
	local id = UIAssets.icons[itemName] or ""
	return id, ""
end

return UIAssets
