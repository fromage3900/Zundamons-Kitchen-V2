local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModifierStack = require(ReplicatedStorage.Shared.Modules.ModifierStack)

local plugin = {
	name = "AmbientNodes",
	version = "1.0",
}

local function applyNodeFX(part)
	if not part:IsA("BasePart") then return end
	local rType = part:GetAttribute("ResourceType")
	if not rType then return end
	if rType == "ZundaFlower" or rType == "PeaFlower" then
		ModifierStack.apply(part, "Bob", { height = 0.3, speed = 0.8 + math.random() * 0.4 })
		ModifierStack.apply(part, "Glow", { color = Color3.fromRGB(200, 220, 255), brightness = 0.8, range = 4 })
	elseif rType == "ZundaPea" or rType == "Zunda Berry" then
		ModifierStack.apply(part, "Bob", { height = 0.2, speed = 1 })
	elseif rType == "Wheat" then
		ModifierStack.apply(part, "Sway", { strength = 0.2, speed = 1.2 })
	elseif rType == "Gold Ore" then
		ModifierStack.apply(part, "Glow", { color = Color3.fromRGB(255, 215, 0), brightness = 1.5, sparkles = true })
	elseif rType == "Rock" then
		ModifierStack.apply(part, "Scale", { scale = 0.9 + math.random() * 0.2 })
	end
end

function plugin.init()
	for _, part in ipairs(CollectionService:GetTagged("GatheringNode")) do
		task.spawn(function() applyNodeFX(part) end)
	end
	CollectionService:GetInstanceAddedSignal("GatheringNode"):Connect(function(part)
		task.wait(0.5)
		applyNodeFX(part)
	end)
	print("[AmbientNodes] Plugin initialized — ambient FX on gathering nodes")
end

function plugin.cleanup()
	for _, part in ipairs(CollectionService:GetTagged("GatheringNode")) do
		ModifierStack.clear(part)
	end
	print("[AmbientNodes] Plugin cleaned up")
end

return plugin
