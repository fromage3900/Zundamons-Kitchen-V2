--!strict
-- Normalizes existing and newly tagged resource nodes without replacing their
-- Studio-authored geometry. Visual swapping is opt-in via UseRegistryMesh.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.ConfigurationFiles.ResourceNodeRegistry)
local bound: { [Instance]: boolean } = setmetatable({}, { __mode = "k" })

local function behaviorTarget(instance: Instance, archetype: any): Instance?
	if archetype.interaction == "click" and instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance
end

local function bind(instance: Instance)
	if bound[instance] or not instance.Parent then
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
	bound[instance] = true
	Registry.applyBehavior(target, archetype.id)
	if instance ~= target then
		instance:SetAttribute("ResourceArchetype", archetype.id)
		instance:SetAttribute("VisualKey", archetype.visualKey)
	end
	if instance:GetAttribute("UseRegistryMesh") == true then
		local variant = instance:GetAttribute("VisualVariant")
		Registry.applyVisual(instance, archetype.id, type(variant) == "string" and variant or nil)
	end
end

local seen: { [Instance]: boolean } = {}
for _, tag in ipairs({ "ResourceNode", "Mineable", "GatheringNode" }) do
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		if not seen[instance] then
			seen[instance] = true
			bind(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(bind)
end

print("[ResourceNodeBootstrap] Mesh-independent resource archetypes ready")
