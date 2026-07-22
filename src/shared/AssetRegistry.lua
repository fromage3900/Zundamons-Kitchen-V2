--!strict
-- AssetRegistry: Single source of truth for all game assets and asset IDs
-- Assets are organized by category and referenced throughout the project
-- Use MCP tools (roblox-studio-list_assets, roblox-studio-get_asset_info) to populate real IDs

local AssetRegistry = {
	-- Metadata
	Name = "Zundamon's Kitchen V2 Asset Registry" :: string,
	Version = "1.0.0" :: string,
	LastUpdated = os.time() :: number,
	
	-- 3D Meshes (farmables, ingredients, cookware)
	Meshes = {
		Produce = {
			ZundaBerry = "rbxassetid://1234567890", -- Replace with real asset ID
			Apple = "rbxassetid://0987654321",
			Pea = "rbxassetid://",
			Tomato = "rbxassetid://",
			Corn = "rbxassetid://",
		},
		Cookware = {
			BasicPan = "rbxassetid://1122334455",
			Pot = "rbxassetid://",
			CuttingBoard = "rbxassetid://",
			Oven = "rbxassetid://",
		},
		Environment = {
			PlanterBox = "rbxassetid://",
			HarvestNode = "rbxassetid://",
			WaterSource = "rbxassetid://",
			CookingStation = "rbxassetid://",
		}
	},
	
	-- UI Textures (icons, buttons, backgrounds)
	Textures = {
		Icons = {
			ZundaBerry = "rbxassetid://9988776655",
			Apple = "rbxassetid://5566778899",
			Pea = "rbxassetid://",
			Tomato = "rbxassetid://",
			Corn = "rbxassetid://",
			CookingPot = "rbxassetid://",
			Serving = "rbxassetid://",
		},
		UI = {
			ButtonNormal = "rbxassetid://",
			ButtonHover = "rbxassetid://",
			ButtonPressed = "rbxassetid://",
			PanelBackground = "rbxassetid://",
			ProgressBar = "rbxassetid://",
		}
	},
	
	-- Companion Models (followers/pets)
	Companions = {
		MiniZunda = "rbxassetid://7777777777",
		ChefZunda = "rbxassetid://",
		KitchenSpirit = "rbxassetid://",
	},
	
	-- Audio (SFX, music, voice lines)
	Audio = {
		SFX = {
			Harvest = "rbxassetid://",
			CookingSizzle = "rbxassetid://",
			OrderBell = "rbxassetid://",
			CoinPickup = "rbxassetid://",
			CompanionBark = "rbxassetid://",
		},
		Music = {
			MainMenu = "rbxassetid://",
			KitchenAmbient = "rbxassetid://",
			CustomerLoop = "rbxassetid://",
		}
	},
	
	-- Particles (VFX, cooking effects, harvest popups)
	Particles = {
		HarvestSparkle = "rbxassetid://",
		CookingFlame = "rbxassetid://",
		Steam = "rbxassetid://",
		XPOrb = "rbxassetid://",
		Confetti = "rbxassetid://",
	},
	
	-- Animations (companion, cooking, serving)
	Animations = {
		CompanionIdle = "rbxassetid://",
		CompanionFollow = "rbxassetid://",
		ChefCook = "rbxassetid://",
		ServingAction = "rbxassetid://",
		CustomerEat = "rbxassetid://",
	}
}

-- AssetRegistry API
local AssetRegistry = {}

--[[
	Get an asset ID by type and name
	@param category: "Meshes", "Textures", "Audio", "Particles", "Animations"
	@param subcategory: The nested table name (e.g., "Produce", "Icons", "SFX")
	@param assetName: The key in the nested table (e.g., "ZundaBerry")
	@returns string asset ID or empty string if not found
]]
function AssetRegistry.Get(category: string, subcategory: string, assetName: string): string
	local categoryTable = AssetRegistry[category]
	if not categoryTable then return "" end
	
	local subcategoryTable = categoryTable[subcategory]
	if not subcategoryTable then return "" end
	
	return subcategoryTable[assetName] or ""
end

--[[
	Set or update an asset ID
	@param category: The top-level category
	@param subcategory: The nested table name
	@param assetName: The key to update
	@param assetId: The new asset ID string
]]
function AssetRegistry.Set(category: string, subcategory: string, assetName: string, assetId: string): ()
	local categoryTable = AssetRegistry[category]
	if not categoryTable then categoryTable = {} AssetRegistry[category] = categoryTable end
	
	local subcategoryTable = categoryTable[subcategory]
	if not subcategoryTable then subcategoryTable = {} categoryTable[subcategory] = subcategoryTable end
	
	subcategoryTable[assetName] = assetId
	AssetRegistry.LastUpdated = os.time()
end

--[[
	Validate that all asset IDs are properly formatted
	Returns a list of assets with missing or invalid IDs
]]
function AssetRegistry.Validate(): {string}
	local invalid = {}
	local pattern = "^rbxassetid://%d+$"
	
	local function validateTable(tbl: {[string]: any}, path: string)
		for key, value in tbl do
			local currentPath = path .. "." .. key
			if type(value) == "table" then
				validateTable(value, currentPath)
			elseif type(value) == "string" then
				if value == "" or not value:match(pattern) then
					table.insert(invalid, currentPath .. " = " .. tostring(value))
				end
			end
		end
	end
	
	-- Skip metadata fields
	validateTable({
		AssetRegistry.Meshes,
		AssetRegistry.Textures,
		AssetRegistry.Audio,
		AssetRegistry.Particles,
		AssetRegistry.Animations
	}, "AssetRegistry")
	
	return invalid
end

--[[
	Get all assets missing IDs
]]
function AssetRegistry.GetMissingIDs(): {string}
	local missing = {}
	
	local function checkTable(tbl: {[string]: any}, path: string)
		for key, value in tbl do
			local currentPath = path .. "." .. key
			if type(value) == "table" then
				checkTable(value, currentPath)
			elseif value == "" then
				table.insert(missing, currentPath)
			end
		end
	end
	
	checkTable({
		AssetRegistry.Meshes,
		AssetRegistry.Textures,
		AssetRegistry.Audio,
		AssetRegistry.Particles,
		AssetRegistry.Animations
	}, "AssetRegistry")
	
	return missing
end

return AssetRegistry