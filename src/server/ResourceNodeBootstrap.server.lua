--!strict
-- Normalizes existing and newly tagged resource nodes without replacing their
-- Studio-authored geometry. Visual swapping is opt-in via UseRegistryMesh.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.ConfigurationFiles.ResourceNodeRegistry)
local watched: { [Instance]: { RBXScriptConnection } } = setmetatable({}, { __mode = "k" })
local applying: { [Instance]: boolean } = setmetatable({}, { __mode = "k" })

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
	if instance ~= target then
		instance:SetAttribute("ResourceArchetype", archetype.id)
		instance:SetAttribute("VisualKey", archetype.visualKey)
	end
	if instance:GetAttribute("UseRegistryMesh") == true then
		local variant = instance:GetAttribute("VisualVariant")
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
