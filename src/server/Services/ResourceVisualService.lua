--!strict
-- Owns every runtime-created resource visual. Gameplay remains attached to a
-- stable interaction root; this service only mutates the _ResourceVisual child.

local ContentProvider = game:GetService("ContentProvider")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Catalog = require(ReplicatedStorage.ConfigurationFiles.ResourceVisualCatalog)

local MANAGED_NAME = "_ResourceVisual"
local FALLBACK_NAME = "Fallback"
local CANDIDATE_NAME = "Candidate"

local ResourceVisualService = {}
local modelCache: { [string]: Instance } = {}

local function rootPart(node: Instance): BasePart?
	if node:IsA("BasePart") then
		return node
	end
	if node:IsA("Model") then
		return node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
	end
	return node:FindFirstChildWhichIsA("BasePart", true)
end

local function setStatus(node: Instance, status: string, detail: string?)
	node:SetAttribute("RegistryMeshStatus", status)
	node:SetAttribute("RegistryMeshDetail", detail)
end

local function managedFolder(root: BasePart): Folder
	local existing = root:FindFirstChild(MANAGED_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = MANAGED_NAME
	folder.Parent = root
	return folder
end

local function preparePart(part: BasePart, root: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Name = "ResourceVisualWeld"
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function createPart(
	root: BasePart,
	parent: Instance,
	name: string,
	size: Vector3,
	color: Color3,
	offset: CFrame,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.CFrame = root.CFrame * offset
	part.Parent = parent
	preparePart(part, root)
	return part
end

local PASTEL = {
	GREEN = Color3.fromRGB(160, 210, 150),
	GOLD = Color3.fromRGB(255, 200, 80),
	PINK = Color3.fromRGB(255, 150, 200),
	MINT = Color3.fromRGB(145, 215, 195),
	BROWN = Color3.fromRGB(133, 91, 62),
	DARK_GREEN = Color3.fromRGB(100, 170, 90),
	LIGHT_GREEN = Color3.fromRGB(180, 230, 170),
	WHITE = Color3.fromRGB(245, 245, 245),
	GRAY = Color3.fromRGB(127, 133, 145),
	LIGHT_GRAY = Color3.fromRGB(180, 185, 190),
	BRIGHT_GOLD = Color3.fromRGB(255, 215, 0),
	RED = Color3.fromRGB(220, 80, 80),
	PURPLE = Color3.fromRGB(180, 120, 200),
}

local function buildFallback(root: BasePart, archetypeId: string): Folder
	local managed = managedFolder(root)
	local old = managed:FindFirstChild(FALLBACK_NAME)
	if old then
		old:Destroy()
	end
	local fallback = Instance.new("Folder")
	fallback.Name = FALLBACK_NAME
	fallback.Parent = managed

	local lo = string.lower

	if archetypeId == "AppleTree" then
		createPart(
			root,
			fallback,
			"Trunk",
			Vector3.new(5, 1.1, 1.1),
			PASTEL.BROWN,
			CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Canopy",
			Vector3.new(5, 5, 5),
			PASTEL.GREEN,
			CFrame.new(0, 5, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"CanopyLight",
			Vector3.new(3.5, 3.5, 3.5),
			PASTEL.LIGHT_GREEN,
			CFrame.new(1.2, 5.8, 0.6),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Blossom1",
			Vector3.new(0.8, 0.8, 0.8),
			PASTEL.PINK,
			CFrame.new(2, 6.5, 1),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Blossom2",
			Vector3.new(0.7, 0.7, 0.7),
			PASTEL.PINK,
			CFrame.new(-1.5, 6.2, -1.8),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Blossom3",
			Vector3.new(0.9, 0.9, 0.9),
			PASTEL.PINK,
			CFrame.new(0.5, 7, -2),
			Enum.PartType.Ball
		)
	elseif archetypeId == "PineTree" then
		createPart(
			root,
			fallback,
			"Trunk",
			Vector3.new(4, 1, 1),
			PASTEL.BROWN,
			CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Lower",
			Vector3.new(4.5, 4.5, 4.5),
			PASTEL.DARK_GREEN,
			CFrame.new(0, 4, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Upper",
			Vector3.new(3, 3, 3),
			PASTEL.GREEN,
			CFrame.new(0, 6.5, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Tip",
			Vector3.new(1.5, 1.5, 1.5),
			PASTEL.LIGHT_GREEN,
			CFrame.new(0, 8, 0),
			Enum.PartType.Ball
		)
	elseif lo(archetypeId):find("rock") then
		local gold = archetypeId == "GoldRock"
		local marble = archetypeId == "MarbleRock"
		local baseColor = if gold then PASTEL.BRIGHT_GOLD elseif marble then PASTEL.WHITE else PASTEL.GRAY
		createPart(root, fallback, "StoneA", Vector3.new(2.8, 2.2, 2.5), baseColor, CFrame.identity, Enum.PartType.Ball)
		createPart(
			root,
			fallback,
			"StoneB",
			Vector3.new(2, 1.6, 1.8),
			baseColor:Lerp(Color3.new(1, 1, 1), 0.15),
			CFrame.new(0.9, 0.45, 0.25),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"StoneC",
			Vector3.new(1.6, 1.4, 1.5),
			baseColor:Lerp(Color3.new(0, 0, 0), 0.06),
			CFrame.new(-0.7, 0.3, -0.6),
			Enum.PartType.Ball
		)
		if gold then
			createPart(
				root,
				fallback,
				"Sparkle",
				Vector3.new(0.5, 0.5, 0.5),
				Color3.fromRGB(255, 255, 200),
				CFrame.new(0.5, 1.2, 0.3),
				Enum.PartType.Ball
			)
		end
	elseif archetypeId == "Wheat" or archetypeId == "CarrotPlot" then
		for index = -2, 2 do
			local x = index * 0.38
			createPart(
				root,
				fallback,
				"Stem" .. index,
				Vector3.new(3.2, 0.16, 0.16),
				PASTEL.GREEN,
				CFrame.new(x, 1.25, (index % 2) * 0.3) * CFrame.Angles(0, 0, math.rad(90)),
				Enum.PartType.Cylinder
			)
			createPart(
				root,
				fallback,
				"Grain" .. index,
				Vector3.new(0.5, 0.85, 0.5),
				PASTEL.GOLD,
				CFrame.new(x, 2.9, (index % 2) * 0.3),
				Enum.PartType.Ball
			)
		end
	elseif archetypeId == "ZundaFlower" then
		createPart(
			root,
			fallback,
			"Stem",
			Vector3.new(2.5, 0.18, 0.18),
			PASTEL.GREEN,
			CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		for i = 0, 4 do
			local a = math.rad(i * 72)
			createPart(
				root,
				fallback,
				"Petal" .. i,
				Vector3.new(0.6, 0.6, 0.3),
				PASTEL.PINK,
				CFrame.new(math.cos(a) * 0.6, 2.2, math.sin(a) * 0.6),
				Enum.PartType.Ball
			)
		end
		createPart(
			root,
			fallback,
			"Center",
			Vector3.new(0.4, 0.4, 0.4),
			PASTEL.GOLD,
			CFrame.new(0, 2.2, 0),
			Enum.PartType.Ball
		)
	elseif archetypeId == "ZundaPea" then
		createPart(
			root,
			fallback,
			"Stem",
			Vector3.new(2, 0.16, 0.16),
			PASTEL.GREEN,
			CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Pod1",
			Vector3.new(1.2, 0.5, 0.5),
			PASTEL.GREEN,
			CFrame.new(0.4, 1.8, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Pod2",
			Vector3.new(1.1, 0.45, 0.45),
			PASTEL.LIGHT_GREEN,
			CFrame.new(-0.4, 2, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Pod3",
			Vector3.new(1, 0.4, 0.4),
			PASTEL.MINT,
			CFrame.new(0, 2.2, 0.4),
			Enum.PartType.Ball
		)
	elseif archetypeId == "ZundaMushroom" or archetypeId == "Zunda Mushroom" then
		createPart(
			root,
			fallback,
			"Stem",
			Vector3.new(1.8, 0.35, 0.35),
			PASTEL.WHITE,
			CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Cap",
			Vector3.new(2.5, 1.2, 2.5),
			PASTEL.RED,
			CFrame.new(0, 2.2, 0),
			Enum.PartType.Ball
		)
		for i = 1, 3 do
			local a = math.rad(i * 120)
			createPart(
				root,
				fallback,
				"Spot" .. i,
				Vector3.new(0.3, 0.3, 0.3),
				PASTEL.WHITE,
				CFrame.new(math.cos(a) * 0.6, 2.6, math.sin(a) * 0.6),
				Enum.PartType.Ball
			)
		end
	elseif archetypeId == "ZundaBerry" or archetypeId == "Zunda Berry" then
		createPart(
			root,
			fallback,
			"Stem",
			Vector3.new(1.5, 0.14, 0.14),
			PASTEL.BROWN,
			CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		for i = 0, 5 do
			local a = math.rad(i * 60)
			createPart(
				root,
				fallback,
				"Berry" .. i,
				Vector3.new(0.5, 0.5, 0.5),
				i % 2 == 0 and PASTEL.RED or PASTEL.PURPLE,
				CFrame.new(math.cos(a) * 0.5, 1.6 + math.sin(a) * 0.15, math.sin(a) * 0.5),
				Enum.PartType.Ball
			)
		end
	elseif archetypeId == "ZundaRoot" or archetypeId == "Zunda Root" then
		createPart(
			root,
			fallback,
			"RootA",
			Vector3.new(2.5, 0.4, 0.4),
			PASTEL.BROWN,
			CFrame.new(0.3, 0.8, 0) * CFrame.Angles(0.3, 0, math.rad(70)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"RootB",
			Vector3.new(2, 0.35, 0.35),
			Color3.fromRGB(160, 120, 80),
			CFrame.new(-0.2, 0.6, 0.3) * CFrame.Angles(-0.2, 0, math.rad(-60)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"RootC",
			Vector3.new(1.8, 0.3, 0.3),
			PASTEL.BROWN:Lerp(Color3.new(0, 0, 0), 0.1),
			CFrame.new(0.1, 1.4, -0.2) * CFrame.Angles(0.5, 0, math.rad(-40)),
			Enum.PartType.Cylinder
		)
	elseif archetypeId == "EdamamePod" then
		createPart(
			root,
			fallback,
			"Stem",
			Vector3.new(1.5, 0.14, 0.14),
			PASTEL.GREEN,
			CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Pod",
			Vector3.new(1.5, 0.7, 0.7),
			PASTEL.GREEN,
			CFrame.new(0, 1.6, 0),
			Enum.PartType.Ball
		)
		for i = 1, 3 do
			createPart(
				root,
				fallback,
				"Seed" .. i,
				Vector3.new(0.35, 0.35, 0.35),
				PASTEL.LIGHT_GREEN,
				CFrame.new((i - 2) * 0.3, 1.6, 0.4),
				Enum.PartType.Ball
			)
		end
	else
		createPart(
			root,
			fallback,
			"Glow",
			Vector3.new(1.6, 1.6, 1.6),
			PASTEL.GREEN,
			CFrame.new(0, 1.5, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Core",
			Vector3.new(0.8, 0.8, 0.8),
			PASTEL.PINK,
			CFrame.new(0.3, 1.7, 0.3),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"Sparkle",
			Vector3.new(0.3, 0.3, 0.3),
			PASTEL.GOLD,
			CFrame.new(0.6, 2.1, 0.1),
			Enum.PartType.Ball
		)
	end

	return fallback
end

local function setDescendantsVisible(container: Instance, visible: boolean)
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant:GetAttribute("ResourceVisualTransparency") == nil then
				descendant:SetAttribute("ResourceVisualTransparency", descendant.Transparency)
			end
			descendant.Transparency = if visible then descendant:GetAttribute("ResourceVisualTransparency") or 0 else 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
			descendant.Enabled = visible
		end
	end
end

local function sanitize(container: Instance)
	for _, descendant in container:GetDescendants() do
		if
			descendant:IsA("LuaSourceContainer")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent")
			or descendant:IsA("BindableFunction")
			or descendant:IsA("ClickDetector")
			or descendant:IsA("ProximityPrompt")
		then
			descendant:Destroy()
		end
	end
end

local function normalizeCandidate(candidate: Instance, root: BasePart, target: CFrame, scale: Vector3): boolean
	local parts = {}
	if candidate:IsA("BasePart") then
		table.insert(parts, candidate)
	end
	for _, descendant in candidate:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	if #parts == 0 then
		return false
	end

	local pivot = if candidate:IsA("Model") then candidate:GetPivot() else (parts[1] :: BasePart).CFrame
	for _, part in parts do
		local relative = pivot:ToObjectSpace(part.CFrame)
		local position = relative.Position
		local scaledPosition = Vector3.new(position.X * scale.X, position.Y * scale.Y, position.Z * scale.Z)
		part.Size *= scale
		part.CFrame = target * CFrame.new(scaledPosition) * relative.Rotation
		preparePart(part, root)
	end
	return true
end

local function studioDescriptor(variantId: string?): any
	if not variantId then
		return nil
	end
	local catalog = ServerStorage:FindFirstChild("ResourceVisualCatalog")
	local entries = catalog and catalog:FindFirstChild("Entries")
	local entry = entries and entries:FindFirstChild(variantId)
	if not entry then
		return nil
	end
	return {
		variant = variantId,
		assetId = entry:GetAttribute("AssetId") or "",
		assetType = entry:GetAttribute("AssetType") or "Mesh",
		scale = entry:GetAttribute("Scale") or Vector3.new(1, 1, 1),
		offset = entry:GetAttribute("Offset") or CFrame.identity,
		enabled = entry:GetAttribute("Enabled") ~= false,
	}
end

function ResourceVisualService.validate(assetId: any, assetType: any): (boolean, string, string)
	local normalized = Catalog.normalizeAssetId(assetId)
	if normalized == "" then
		return false, "", "invalid_asset_id"
	end
	if assetType ~= "Mesh" and assetType ~= "Model" and assetType ~= "Prefab" then
		return false, normalized, "invalid_asset_type"
	end
	return true, normalized, "format_valid"
end

function ResourceVisualService.resolve(node: Instance, archetypeId: string, variantId: string?): any
	local overrideId = node:GetAttribute("VisualAssetId")
	local overrideType = node:GetAttribute("VisualAssetType")
	if type(overrideId) == "string" and overrideId ~= "" then
		return {
			variant = variantId or "InstanceOverride",
			assetId = overrideId,
			assetType = if type(overrideType) == "string" then overrideType else "Model",
			scale = node:GetAttribute("VisualScale") or Vector3.new(1, 1, 1),
			offset = node:GetAttribute("VisualOffset") or CFrame.identity,
			enabled = true,
		}
	end
	return studioDescriptor(variantId) or Catalog.getForArchetype(archetypeId, variantId)
end

function ResourceVisualService.clear(node: Instance)
	local root = rootPart(node)
	if not root then
		return
	end
	local managed = root:FindFirstChild(MANAGED_NAME)
	if managed then
		managed:Destroy()
	end
	local original = root:GetAttribute("ResourceRootTransparency")
	if type(original) == "number" then
		root.Transparency = original
	end
	setStatus(node, "cleared")
end

function ResourceVisualService.setVisible(node: Instance, visible: boolean)
	local root = rootPart(node)
	local managed = root and root:FindFirstChild(MANAGED_NAME)
	if managed then
		setDescendantsVisible(managed, visible)
	end
end

function ResourceVisualService.getStatus(node: Instance): (string, string?)
	return node:GetAttribute("RegistryMeshStatus") or "unknown", node:GetAttribute("RegistryMeshDetail")
end

local function applyModel(node: Instance, root: BasePart, managed: Folder, descriptor: any): (boolean, string)
	local normalized = Catalog.normalizeAssetId(descriptor.assetId)

	-- PRIMARY: Check for baked prefab in ServerStorage.AssetLibrary.ResourceNodes (author-owned)
	local assetLibrary = ServerStorage:FindFirstChild("AssetLibrary")
	if assetLibrary then
		local resourceNodes = assetLibrary:FindFirstChild("ResourceNodes")
		local prefabVariant = resourceNodes and resourceNodes:FindFirstChild(node:GetAttribute("VisualVariant") or "")
		if prefabVariant and prefabVariant:IsA("Model") then
			local candidate = prefabVariant:Clone()
			candidate.Name = CANDIDATE_NAME
			candidate.Parent = managed
			if normalizeCandidate(candidate, root, root.CFrame * descriptor.offset, descriptor.scale) then
				local fallback = managed:FindFirstChild(FALLBACK_NAME)
				if fallback then
					setDescendantsVisible(fallback, false)
				end
				setStatus(node, "applied", "prefab:" .. node:GetAttribute("VisualVariant"))
				return true, "applied"
			end
			candidate:Destroy()
		end
	end

	-- FALLBACK: InsertService for third-party public assets (Kenney packs, etc.)
	local template = modelCache[normalized]
	if not template then
		local numericId = tonumber(string.match(normalized, "%d+"))
		local ok, loaded = pcall(function()
			return InsertService:LoadAsset(numericId :: number)
		end)
		if not ok or not loaded then
			return false, "model_load_failed"
		end
		sanitize(loaded)
		template = loaded
		modelCache[normalized] = loaded
		loaded.Parent = nil
	end
	local candidate = template:Clone()
	candidate.Name = CANDIDATE_NAME
	candidate.Parent = managed
	if not normalizeCandidate(candidate, root, root.CFrame * descriptor.offset, descriptor.scale) then
		candidate:Destroy()
		return false, "model_has_no_parts"
	end
	local fallback = managed:FindFirstChild(FALLBACK_NAME)
	if fallback then
		setDescendantsVisible(fallback, false)
	end
	setStatus(node, "applied", normalized)
	return true, "applied"
end

local function applyMeshAsync(node: Instance, root: BasePart, managed: Folder, descriptor: any): (boolean, string)
	-- PRIMARY: Check for baked prefab in ServerStorage.AssetLibrary.ResourceNodes (author-owned)
	local assetLibrary = ServerStorage:FindFirstChild("AssetLibrary")
	if assetLibrary then
		local resourceNodes = assetLibrary:FindFirstChild("ResourceNodes")
		local prefabVariant = resourceNodes and resourceNodes:FindFirstChild(node:GetAttribute("VisualVariant") or "")
		if prefabVariant and prefabVariant:IsA("Model") then
			local candidate = prefabVariant:Clone()
			candidate.Name = CANDIDATE_NAME
			candidate.Parent = managed
			if normalizeCandidate(candidate, root, root.CFrame * descriptor.offset, descriptor.scale) then
				local fallback = managed:FindFirstChild(FALLBACK_NAME)
				if fallback then
					setDescendantsVisible(fallback, false)
				end
				setStatus(node, "applied", "prefab:" .. node:GetAttribute("VisualVariant"))
				return true, "applied"
			end
			candidate:Destroy()
		end
	end

	-- FALLBACK: ContentProvider:PreloadAsync for third-party public assets
	local candidate = Instance.new("Part")
	candidate.Name = CANDIDATE_NAME
	candidate.Size = Vector3.new(2, 2, 2)
	candidate.Transparency = 1
	candidate.CFrame = root.CFrame * descriptor.offset
	candidate.Parent = managed
	preparePart(candidate, root)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = Catalog.normalizeAssetId(descriptor.assetId)
	mesh.Scale = descriptor.scale
	mesh.Parent = candidate
	setStatus(node, "loading", mesh.MeshId)

	task.spawn(function()
		local succeeded = false
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ candidate }, function(_, status)
				if status == Enum.AssetFetchStatus.Success then
					succeeded = true
				end
			end)
		end)
		if not candidate.Parent then
			return
		end
		if ok and succeeded then
			candidate:SetAttribute("ResourceVisualTransparency", 0)
			candidate.Transparency = 0
			local fallback = managed:FindFirstChild(FALLBACK_NAME)
			if fallback then
				setDescendantsVisible(fallback, false)
			end
			setStatus(node, "applied", mesh.MeshId)
		else
			candidate:Destroy()
			setStatus(node, "fallback", "asset_fetch_failed")
		end
	end)
	return true, "loading"
end

function ResourceVisualService.apply(node: Instance, descriptor: any?): (boolean, string)
	local root = rootPart(node)
	if not root then
		setStatus(node, "error", "visual_root_missing")
		return false, "visual_root_missing"
	end
	if root:GetAttribute("ResourceRootTransparency") == nil then
		root:SetAttribute("ResourceRootTransparency", root.Transparency)
	end
	local archetypeId = node:GetAttribute("ResourceArchetype") or root:GetAttribute("ResourceArchetype")
	if not archetypeId then
		for _, tag in ipairs(CollectionService:GetTags(node)) do
			if Catalog.getDefaultVariant(tag) then
				archetypeId = tag
				break
			end
		end
	end
	archetypeId = archetypeId or "Unknown"
	local managed = managedFolder(root)
	local oldCandidate = managed:FindFirstChild(CANDIDATE_NAME)
	if oldCandidate then
		oldCandidate:Destroy()
	end
	buildFallback(root, archetypeId)

	local variantId = node:GetAttribute("VisualVariant") or root:GetAttribute("VisualVariant")
	local resolved = descriptor or ResourceVisualService.resolve(node, archetypeId, variantId)
	if not resolved or resolved.enabled == false or resolved.assetType == "Fallback" then
		setStatus(node, "fallback", if resolved then "asset_disabled" else "asset_missing")
		return true, "fallback"
	end
	local valid, normalized, reason = ResourceVisualService.validate(resolved.assetId, resolved.assetType)
	if not valid then
		setStatus(node, "fallback", reason)
		return false, reason
	end
	resolved = table.clone(resolved)
	resolved.assetId = normalized
	resolved.scale = if typeof(resolved.scale) == "Vector3" then resolved.scale else Vector3.new(1, 1, 1)
	resolved.offset = if typeof(resolved.offset) == "CFrame" then resolved.offset else CFrame.identity

	-- Only hide the root AFTER confirming a visual has been successfully applied.
	-- This prevents the "invisible bug" where root becomes transparent but no replacement visual loads.
	local success, result
	if resolved.assetType == "Model" or resolved.assetType == "Prefab" then
		success, result = applyModel(node, root, managed, resolved)
	else
		success, result = applyMeshAsync(node, root, managed, resolved)
	end

	if success then
		root.Transparency = 1
	end

	if success then
		return true, result
	else
		return false, result
	end
end

return ResourceVisualService
