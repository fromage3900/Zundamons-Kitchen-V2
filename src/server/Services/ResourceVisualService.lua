--!strict
-- Owns every runtime-created resource visual. Gameplay remains attached to a
-- stable interaction root; this service only mutates the _ResourceVisual child.

local ContentProvider = game:GetService("ContentProvider")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

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

local function buildFallback(root: BasePart, archetypeId: string): Folder
	local managed = managedFolder(root)
	local old = managed:FindFirstChild(FALLBACK_NAME)
	if old then
		old:Destroy()
	end
	local fallback = Instance.new("Folder")
	fallback.Name = FALLBACK_NAME
	fallback.Parent = managed

	if archetypeId == "AppleTree" or archetypeId == "PineTree" then
		createPart(
			root,
			fallback,
			"Trunk",
			Vector3.new(5, 1.1, 1.1),
			Color3.fromRGB(133, 91, 62),
			CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Canopy",
			Vector3.new(5.5, 5.5, 5.5),
			Color3.fromRGB(126, 196, 108),
			CFrame.new(0, 5, 0),
			Enum.PartType.Ball
		)
		createPart(
			root,
			fallback,
			"CanopyAccent",
			Vector3.new(3.8, 3.8, 3.8),
			Color3.fromRGB(167, 218, 127),
			CFrame.new(1.5, 5.8, 0.4),
			Enum.PartType.Ball
		)
	elseif archetypeId == "Wheat" or archetypeId == "CarrotPlot" then
		for index = -2, 2 do
			local x = index * 0.38
			createPart(
				root,
				fallback,
				"Stem",
				Vector3.new(3.2, 0.16, 0.16),
				Color3.fromRGB(112, 166, 75),
				CFrame.new(x, 1.25, (index % 2) * 0.3) * CFrame.Angles(0, 0, math.rad(90)),
				Enum.PartType.Cylinder
			)
			createPart(
				root,
				fallback,
				"Grain",
				Vector3.new(0.5, 0.85, 0.5),
				Color3.fromRGB(244, 207, 91),
				CFrame.new(x, 2.9, (index % 2) * 0.3),
				Enum.PartType.Ball
			)
		end
	elseif string.find(string.lower(archetypeId), "rock", 1, true) then
		local gold = archetypeId == "GoldRock"
		local color = if gold then Color3.fromRGB(244, 190, 55) else Color3.fromRGB(127, 133, 145)
		createPart(root, fallback, "StoneA", Vector3.new(2.8, 2.2, 2.5), color, CFrame.identity, Enum.PartType.Ball)
		createPart(
			root,
			fallback,
			"StoneB",
			Vector3.new(1.8, 1.8, 1.7),
			color:Lerp(Color3.new(1, 1, 1), 0.12),
			CFrame.new(0.9, 0.45, 0.25),
			Enum.PartType.Ball
		)
	else
		local color = if string.find(archetypeId, "Flower", 1, true)
			then Color3.fromRGB(255, 150, 200)
			else Color3.fromRGB(160, 210, 150)
		createPart(
			root,
			fallback,
			"Stem",
			Vector3.new(2.2, 0.18, 0.18),
			Color3.fromRGB(112, 166, 75),
			CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.PartType.Cylinder
		)
		createPart(
			root,
			fallback,
			"Gatherable",
			Vector3.new(1.4, 1.4, 1.4),
			color,
			CFrame.new(0, 2.1, 0),
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
	local archetypeId = node:GetAttribute("ResourceArchetype") or root:GetAttribute("ResourceArchetype") or "Unknown"
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
