--!strict
-- Normalizes resource behavior and delegates replaceable visuals to the single
-- ResourceVisualService boundary. Authored geometry is preserved by default.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Registry = require(ReplicatedStorage.ConfigurationFiles.ResourceNodeRegistry)
local ResourceVisualService = require(ServerScriptService.Services.ResourceVisualService)

local watched: { [Instance]: { RBXScriptConnection } } = setmetatable({}, { __mode = "k" })
local applying: { [Instance]: boolean } = setmetatable({}, { __mode = "k" })

local function behaviorTarget(instance: Instance, archetype: any): Instance?
	if archetype.interaction == "click" and instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance
end

local function hasAuthoredVisual(instance: Instance, target: Instance): boolean
	if instance:IsA("MeshPart") or target:IsA("MeshPart") then
		return true
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:FindFirstAncestor("_ResourceVisual") then
			continue
		end
		if descendant:IsA("MeshPart") or descendant:IsA("SpecialMesh") then
			return true
		end
	end
	return false
end

local function shouldManageVisual(instance: Instance, target: Instance): boolean
	if instance:GetAttribute("VisualAssetType") == "Fallback" then
		return true
	end
	if instance:GetAttribute("VisualAssetId") ~= nil or instance:GetAttribute("VisualVariant") ~= nil then
		return true
	end
	if instance:GetAttribute("UseRegistryMesh") == true then
		return true
	end
	return target:IsA("Part") and not hasAuthoredVisual(instance, target)
end

local function apply(instance: Instance)
	if applying[instance] or not instance.Parent then
		return
	end
	local archetype = Registry.infer(instance)
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
	instance:SetAttribute("ResourceArchetype", archetype.id)
	instance:SetAttribute("VisualKey", archetype.visualKey)
	if instance:GetAttribute("UseFallbackOnFailure") == nil then
		instance:SetAttribute("UseFallbackOnFailure", true)
	end

	if shouldManageVisual(instance, target) then
		ResourceVisualService.apply(instance)
	else
		instance:SetAttribute("RegistryMeshStatus", "authored")
		instance:SetAttribute("RegistryMeshDetail", nil)
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
	for _, attribute in
		{
			"ResourceArchetype",
			"Type",
			"ResourceType",
			"UseRegistryMesh",
			"VisualVariant",
			"VisualAssetId",
			"VisualAssetType",
			"VisualScale",
			"VisualOffset",
		}
	do
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
			for _, connection in connections do
				connection:Disconnect()
			end
			watched[instance] = nil
			applying[instance] = nil
		end)
	)
	apply(instance)
end

local seen: { [Instance]: boolean } = {}
for _, tag in { "ResourceNode", "Mineable", "GatheringNode" } do
	for _, instance in CollectionService:GetTagged(tag) do
		if not seen[instance] then
			seen[instance] = true
			watch(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(watch)
end

print("[ResourceNodeBootstrap] Canonical resource visual service ready")
