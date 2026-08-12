--[[
  Map Mesh Names to Harvestable Nodes
  Scans Workspace descendants and assigns ResourceType attributes
  based on name patterns matching the Registry configuration.
  
  Usage: Run in Roblox Studio Command bar or as a plugin script
--]]

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

-- Name pattern -> canonical ResourceType mapping
-- Matches ResourceNodeRegistry.lua toolDefinitions and GatherConfig.clickResources
local NAME_TO_RESOURCE_TYPE = {
	-- Tree patterns (tool-based, requires Axe)
	["tree"] = "Tree",
	["apple"] = "Tree", -- apple trees
	["pine"] = "Tree", -- pine trees

	-- Rock patterns (tool-based, requires PickAxe)
	["rock"] = "Rock",
	["stone"] = "Rock",
	["gold"] = "Gold Ore",
	["marble"] = "Marble Rock",

	-- Plant/click patterns (click-to-gather)
	["flower"] = "ZundaFlower",
	["pea"] = "ZundaPea",
	["leaf"] = "ZundaLeaf",

	-- Wheat (tool-based, requires Sickle)
	["wheat"] = "Wheat",

	-- Mushroom/berry/root (tool-based, requires Sickle)
	["mushroom"] = "ZundaMushroom",
	["berry"] = "ZundaBerry",
	["root"] = "ZundaRoot",

	-- Edible plants
	["carrot"] = "CarrotPlot",
	["plant"] = "CarrotPlot",
}

-- Additional: substring matching for case-insensitive partial matches
local function findResourceType(nameLower)
	-- First try exact key match
	if NAME_TO_RESOURCE_TYPE[nameLower] then
		return NAME_TO_RESOURCE_TYPE[nameLower]
	end

	-- Then try substring patterns
	for pattern, rtype in pairs(NAME_TO_RESOURCE_TYPE) do
		if string.find(nameLower, pattern, 1, true) then
			return rtype
		end
	end

	return nil
end

-- Main mapping function
local function mapMeshToHarvest(node)
	if not node:IsA("BasePart") and not node:IsA("MeshPart") then
		return
	end

	-- Skip if already has ResourceType attribute
	if node:GetAttribute("ResourceType") then
		return
	end

	local nameLower = string.lower(node.Name)
	local rtype = findResourceType(nameLower)

	if not rtype then
		-- print("[MapMesh] No harvest type found for: " .. node.Name)
		return
	end

	-- Set the ResourceType attribute
	node:SetAttribute("ResourceType", rtype)

	-- Ensure ClickDetector exists for click-based gathering
	if rtype ~= "CarrotPlot" and not node:FindFirstChildOfClass("ClickDetector") then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = node
	end

	-- Add ResourceNode tag ((ResourceNodeBootstrap) will handle this,
	-- but we add it here for immediate effect)
	CollectionService:AddTag(node, "ResourceNode")

	-- print("[MapMesh] Mapped '" .. node.Name .. "' → ResourceType: '" .. rtype .. "'")
end

-- Run scan on Workspace descendants
local function runMapping()
	local count = 0

	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("BasePart") or inst:IsA("MeshPart") then
			-- Only map unparented or studio-placed parts (not scripts, etc.)
			mapMeshToHarvest(inst)
			count = count + 1
		end
	end

	print("[MapMesh] Scanned " .. count .. " parts in Workspace")
	print("[MapMesh] Complete! Manually re-open Studio or run Rojo sync to apply.")
end

-- Also check ServerScriptService/Workspace for baked instances
local function runServerMapping()
	local count = 0

	-- Scan ServerScriptService service folders that might have node definitions
	local sss = game:GetService("ServerScriptService")
	-- Look in workspace zones and gameplay areas
	local function scanFolder(folder, depth)
		depth = depth or 0
		if depth > 3 then
			return
		end -- safety limit

		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("BasePart") or child:IsA("MeshPart") then
				mapMeshToHarvest(child)
				count = count + 1
			elseif child:IsA("Folder") then
				scanFolder(child, depth + 1)
			end
		end
	end

	-- Scan common harvest areas
	local areas = {
		"Workspace.ZoneAssets",
		"Workspace.Guests",
		"Workspace.Houses",
		"Workspace.Kitchen",
	}

	for _, areaPath in ipairs(areas) do
		local parts = Workspace:FindFirstChild(areaPath)
		if parts then
			scanFolder(parts)
		end
	end

	print("[MapServer] Mapped " .. count .. " potential harvest parts")
end

-- Execute
print("=== Zunda Harvest Mesh Mapper ===")
print("Mapping Workspace meshes to harvestable nodes...")
runMapping()

print("\nMapping ServerScriptService folders...")
runServerMapping()

print("\n=== Done ===")
print("Notes:")
print("- Parts named 'tree', 'rock', 'flower' etc. will be auto-mapped")
print("- ResourceType attribute set for each mapped part")
print("- ClickDetector added where needed")
print("- Run 'rojo build default.project.json' to sync changes")
