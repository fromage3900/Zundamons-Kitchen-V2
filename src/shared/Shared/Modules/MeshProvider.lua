--!strict
-- [[ModuleScript] MeshProvider]]
-- Provides mesh IDs from imported meshes in ReplicatedStorage.Meshes
-- This ensures meshes are available to all collaborators without external asset dependencies

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshProvider = {}

local meshesFolder = ReplicatedStorage:FindFirstChild("Meshes")

-- Get mesh ID by category and name
-- Example: MeshProvider.get("HarvestNodes", "Wheat")
-- Example: MeshProvider.get("HarvestNodes/CarrotPlot", "Seed")
function MeshProvider.get(category: string, name: string): string
	if not meshesFolder then
		warn("[MeshProvider] Meshes folder not found in ReplicatedStorage")
		return ""
	end
	
	-- Handle nested paths like "HarvestNodes/CarrotPlot"
	local currentFolder = meshesFolder
	for folderName in category:gmatch("[^/]+") do
		currentFolder = currentFolder:FindFirstChild(folderName)
		if not currentFolder then
			warn(`[MeshProvider] Category path "{category}" not found`)
			return ""
		end
	end
	
	local meshPart = currentFolder:FindFirstChild(name)
	if meshPart and meshPart:IsA("MeshPart") then
		return meshPart.MeshId
	elseif meshPart and meshPart:IsA("Model") then
		-- For models, find the first MeshPart child
		for _, child in meshPart:GetDescendants() do
			if child:IsA("MeshPart") then
				return child.MeshId
			end
		end
	end
	
	warn(`[MeshProvider] Mesh "{name}" not found in category "{category}"`)
	return ""
end

-- Get all mesh names in a category
function MeshProvider.getCategoryNames(category: string): {string}
	if not meshesFolder then return {} end
	local categoryFolder = meshesFolder:FindFirstChild(category)
	if not categoryFolder then return {} end
	
	local names = {}
	for _, child in categoryFolder:GetChildren() do
		table.insert(names, child.Name)
	end
	return names
end

-- Check if a mesh exists
function MeshProvider.exists(category: string, name: string): boolean
	if not meshesFolder then return false end
	
	-- Handle nested paths
	local currentFolder = meshesFolder
	for folderName in category:gmatch("[^/]+") do
		currentFolder = currentFolder:FindFirstChild(folderName)
		if not currentFolder then return false end
	end
	
	return currentFolder:FindFirstChild(name) ~= nil
end

return MeshProvider
