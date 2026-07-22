--!strict
-- Normalizes existing and newly tagged resource nodes without replacing their
-- Studio-authored geometry. Visual swapping is opt-in via UseRegistryMesh.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.ConfigurationFiles.ResourceNodeRegistry)
local watched: { [Instance]: { RBXScriptConnection } } = setmetatable({}, { __mode = "k" })
local applying: { [Instance]: boolean } = setmetatable({}, { __mode = "k" })

-- Exact-name compatibility for the small set of legacy gameplay-loop cubes.
-- This intentionally does not opt in arbitrary Parts: authored level geometry
-- and imported MeshParts must remain under designer control.
local legacyPlaceholders: { [string]: { archetype: string, variant: string } } = {
	Loop_AppleTree_1 = { archetype = "AppleTree", variant = "Variant1" },
	Loop_AppleTree_2 = { archetype = "AppleTree", variant = "Variant2" },
	Loop_Rock_1 = { archetype = "Rock", variant = "Rock_Common" },
	Loop_Rock_2 = { archetype = "Rock", variant = "Rock_Rare" },
	Loop_GoldRock_1 = { archetype = "GoldRock", variant = "GoldOre_Default" },
	Loop_Wheat_1 = { archetype = "Wheat", variant = "Wheat_01" },
	Loop_Wheat_2 = { archetype = "Wheat", variant = "Wheat_02" },
	Loop_Wheat_3 = { archetype = "Wheat", variant = "Wheat_03" },
}

local function visualPart(root: Part, folder: Folder, name: string, size: Vector3, color: Color3, offset: CFrame, shape: Enum.PartType?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = root.CFrame * offset
	part.Parent = folder
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function applyPlaceholderFallback(root: Part, archetypeId: string)
	if root:FindFirstChild("RegistryFallbackVisual") then
		return
	end
	local failedMesh = root:FindFirstChildOfClass("SpecialMesh")
	if failedMesh then
		failedMesh:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "RegistryFallbackVisual"
	folder.Parent = root
	root.Transparency = 1

	if archetypeId == "AppleTree" then
		visualPart(root, folder, "Trunk", Vector3.new(5, 1.1, 1.1), Color3.fromRGB(133, 91, 62), CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
		visualPart(root, folder, "Canopy", Vector3.new(5.5, 5.5, 5.5), Color3.fromRGB(126, 196, 108), CFrame.new(0, 5, 0), Enum.PartType.Ball)
		visualPart(root, folder, "CanopyAccent", Vector3.new(3.8, 3.8, 3.8), Color3.fromRGB(167, 218, 127), CFrame.new(1.5, 5.8, 0.4), Enum.PartType.Ball)
	elseif archetypeId == "Wheat" then
		for index = -2, 2 do
			local x = index * 0.38
			visualPart(root, folder, "Stem", Vector3.new(3.2, 0.16, 0.16), Color3.fromRGB(112, 166, 75), CFrame.new(x, 1.25, (index % 2) * 0.3) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
			visualPart(root, folder, "Grain", Vector3.new(0.5, 0.85, 0.5), Color3.fromRGB(244, 207, 91), CFrame.new(x, 2.9, (index % 2) * 0.3), Enum.PartType.Ball)
		end
	else
		local gold = archetypeId == "GoldRock"
		local baseColor = if gold then Color3.fromRGB(244, 190, 55) else Color3.fromRGB(127, 133, 145)
		visualPart(root, folder, "StoneA", Vector3.new(2.8, 2.2, 2.5), baseColor, CFrame.new(0, 0, 0), Enum.PartType.Ball)
		visualPart(root, folder, "StoneB", Vector3.new(1.8, 1.8, 1.7), baseColor:Lerp(Color3.new(1, 1, 1), 0.12), CFrame.new(0.9, 0.45, 0.25), Enum.PartType.Ball)
	end
end

local function behaviorTarget(instance: Instance, archetype: any): Instance?
	if archetype.interaction == "click" and instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance
end

local function apply(instance: Instance)
	if applying[instance] or not instance.Parent then
		return
	end
	local placeholder = if instance:IsA("Part") then legacyPlaceholders[instance.Name] else nil
	local archetype = if placeholder then Registry.resolve(placeholder.archetype) else Registry.infer(instance)
	if not archetype then
		return
	end
	local target = behaviorTarget(instance, archetype)
	if not target then
		warn("[ResourceNodeBootstrap] No behavior target for " .. instance:GetFullName())
		return
	end
	applying[instance] = true
	Registry.applyBehavior(target, archetype.id)
	if instance ~= target then
		instance:SetAttribute("ResourceArchetype", archetype.id)
		instance:SetAttribute("VisualKey", archetype.visualKey)
	end
	if placeholder and instance:IsA("Part") and instance:GetAttribute("UseRegistryMesh") ~= true then
		-- The old uploaded IDs currently fail ContentProvider preloading in this
		-- experience. Keep the core loop readable with a built-in visual until a
		-- designer explicitly opts into a verified replacement mesh.
		applyPlaceholderFallback(instance, archetype.id)
		instance:SetAttribute("RegistryMeshStatus", "procedural_fallback")
	elseif instance:GetAttribute("UseRegistryMesh") == true then
		local configuredVariant = instance:GetAttribute("VisualVariant")
		local variant = if type(configuredVariant) == "string" then configuredVariant else nil
		local visualOk, visualReason =
			Registry.applyVisual(instance, archetype.id, type(variant) == "string" and variant or nil)
		instance:SetAttribute("RegistryMeshStatus", if visualOk then "applied" else visualReason or "unavailable")
	else
		instance:SetAttribute("RegistryMeshStatus", "authored")
	end
	applying[instance] = nil
end

local function watch(instance: Instance)
	if watched[instance] then
		apply(instance)
		return
	end
	local connections = {}
	watched[instance] = connections
	for _, attribute in ipairs({ "ResourceArchetype", "Type", "ResourceType", "UseRegistryMesh", "VisualVariant" }) do
		table.insert(
			connections,
			instance:GetAttributeChangedSignal(attribute):Connect(function()
				apply(instance)
			end)
		)
	end
	table.insert(
		connections,
		instance.AncestryChanged:Connect(function(_, parent)
			if parent then
				return
			end
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			watched[instance] = nil
			applying[instance] = nil
		end)
	)
	apply(instance)
end

local seen: { [Instance]: boolean } = {}
for _, tag in ipairs({ "ResourceNode", "Mineable", "GatheringNode" }) do
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		if not seen[instance] then
			seen[instance] = true
			watch(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(watch)
end

print("[ResourceNodeBootstrap] Mesh-independent resource archetypes ready")
