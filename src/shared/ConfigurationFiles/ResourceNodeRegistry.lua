--!strict
-- Canonical behavior metadata for swappable resource visuals. Mesh identity is
-- deliberately separate from interaction, durability, loot, and respawn rules.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GatherConfig = require(ReplicatedStorage.ConfigurationFiles.GatherConfig)
local MeshAssets = require(ReplicatedStorage.ConfigurationFiles.MeshAssets)
local MineableConfig = require(ReplicatedStorage.ConfigurationFiles.MineableConfig)

export type Archetype = {
	id: string,
	interaction: "tool" | "click",
	resourceType: string,
	visualKey: string,
	requiredTool: string?,
	defaultYield: number?,
	respawnSeconds: number,
}

local Registry = {}
local archetypes: { [string]: Archetype } = {}
local aliases: { [string]: string } = {}

local function register(definition: Archetype, additionalAliases: { string }?)
	archetypes[definition.id] = table.freeze(definition)
	aliases[string.lower(definition.id)] = definition.id
	aliases[string.lower(definition.resourceType)] = definition.id
	for _, alias in ipairs(additionalAliases or {}) do
		aliases[string.lower(alias)] = definition.id
	end
end

local toolDefinitions = {
	{ "Rock", "PickAxe", "Rock" },
	{ "MarbleRock", "PickAxe", "Rock" },
	{ "GoldRock", "PickAxe", "Gold Ore" },
	{ "AppleTree", "Axe", "Tree" },
	{ "PineTree", "Axe", "Tree" },
	{ "Wheat", "Sickle", "Wheat" },
	{ "ZundaMushroom", "Sickle", "Zunda Mushroom" },
	{ "ZundaBerry", "Sickle", "Zunda Berry" },
	{ "ZundaRoot", "Sickle", "Zunda Root" },
}

for _, values in ipairs(toolDefinitions) do
	local id, tool, visualKey = values[1], values[2], values[3]
	local tuning = MineableConfig.Mineables[id]
	register({
		id = id,
		interaction = "tool",
		resourceType = id,
		visualKey = visualKey,
		requiredTool = tool,
		respawnSeconds = tuning.Respawn,
	}, (id == "GoldRock" or string.sub(id, 1, 5) == "Zunda") and { visualKey } or nil)
end

for resourceType, tuning in pairs(GatherConfig.clickResources) do
	register({
		id = resourceType,
		interaction = "click",
		resourceType = resourceType,
		visualKey = resourceType,
		defaultYield = tuning.defaultYield,
		respawnSeconds = tuning.respawnSeconds,
	}, { tuning.itemName })
end

register({
	id = "MysteryLoot",
	interaction = "click",
	resourceType = "MysteryLoot",
	visualKey = "Gold Ore",
	defaultYield = 1,
	respawnSeconds = GatherConfig.mysteryRespawnSeconds,
})

function Registry.resolve(value: any): Archetype?
	if type(value) ~= "string" then
		return nil
	end
	return archetypes[aliases[string.lower(value)]]
end

function Registry.infer(instance: Instance): Archetype?
	for _, value in ipairs({
		instance:GetAttribute("ResourceArchetype"),
		instance:GetAttribute("Type"),
		instance:GetAttribute("ResourceType"),
		instance.Name,
	}) do
		local exact = Registry.resolve(value)
		if exact then
			return exact
		end
	end
	local lowered = string.lower(instance.Name)
	for alias, id in pairs(aliases) do
		if string.find(lowered, alias, 1, true) then
			return archetypes[id]
		end
	end
	return nil
end

function Registry.resolveMeshId(archetypeId: string, variantId: string?): string
	local archetype = Registry.resolve(archetypeId)
	return archetype and MeshAssets.getMeshId(archetype.visualKey, variantId) or ""
end

function Registry.applyBehavior(instance: Instance, archetypeId: string): (boolean, string?)
	local archetype = Registry.resolve(archetypeId)
	if not archetype then
		return false, "unknown_archetype"
	end
	instance:SetAttribute("ResourceArchetype", archetype.id)
	instance:SetAttribute("ResourceType", archetype.resourceType)
	instance:SetAttribute("VisualKey", archetype.visualKey)
	if instance:GetAttribute("Available") == nil then
		instance:SetAttribute("Available", true)
	end
	CollectionService:AddTag(instance, "ResourceNode")

	if archetype.interaction == "tool" then
		local tuning = MineableConfig.Mineables[archetype.id]
		instance:SetAttribute("Type", archetype.id)
		if instance:GetAttribute("Health") == nil then
			instance:SetAttribute("Health", tuning.Health)
		end
		if instance:GetAttribute("MaxHealth") == nil then
			instance:SetAttribute("MaxHealth", tuning.MaxHealth)
		end
		if instance:GetAttribute("Respawn") == nil then
			instance:SetAttribute("Respawn", tuning.Respawn)
		end
		CollectionService:AddTag(instance, "Mineable")
		if archetype.requiredTool then
			CollectionService:AddTag(instance, archetype.requiredTool)
		end
	else
		if instance:GetAttribute("Yield") == nil then
			instance:SetAttribute("Yield", archetype.defaultYield or 1)
		end
		if instance:GetAttribute("Respawn") == nil then
			instance:SetAttribute("Respawn", archetype.respawnSeconds)
		end
		CollectionService:AddTag(instance, "GatheringNode")
		if instance:IsA("BasePart") and not instance:FindFirstChildOfClass("ClickDetector") then
			local detector = Instance.new("ClickDetector")
			detector.MaxActivationDistance = 16
			detector.Parent = instance
		end
	end
	return true
end

function Registry.applyVisual(instance: Instance, archetypeId: string, variantId: string?): (boolean, string?)
	local meshId = Registry.resolveMeshId(archetypeId, variantId)
	if meshId == "" then
		return false, "mesh_missing"
	end
	local meshPart = if instance:IsA("MeshPart") then instance else instance:FindFirstChildWhichIsA("MeshPart", true)
	if not meshPart then
		return false, "mesh_part_missing"
	end
	meshPart.MeshId = meshId
	if variantId then
		instance:SetAttribute("VisualVariant", variantId)
	end
	return true
end

function Registry.getArchetypes(): { [string]: Archetype }
	return table.clone(archetypes)
end

return Registry
