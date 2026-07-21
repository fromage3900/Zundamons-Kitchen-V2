local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ModifierStack = require(ReplicatedStorage.Shared.Modules.ModifierStack)
local ZundamonSync = require(ReplicatedStorage.Shared.Modules.ZundamonSync)

local plugin = {
	name = "ZundamonFX",
	version = "1.0",
}

local companionModifiers = {}

function plugin.init()
	ZundamonSync.onChange(function(player, key, value)
		if key ~= "companionType" and key ~= "emotion" and key ~= "meshModifiers" then return end
		local char = player.Character
		if not char then return end
		local companion = char:FindFirstChild("ZundaCompanion_" .. player.Name)
		if not companion then return end
		local body = companion:FindFirstChild("Body")
		if not body then return end

		local state = ZundamonSync.getState(player)

		ModifierStack.clear(body)
		if state.emotion == "happy" or state.emotion == "excited" then
			ModifierStack.apply(body, "Glow", { color = Color3.fromRGB(255, 220, 100), sparkles = true })
			ModifierStack.apply(body, "Bob", { height = 0.8, speed = 2 })
		elseif state.emotion == "thinking" then
			ModifierStack.apply(body, "Bob", { height = 0.3, speed = 0.8 })
		else
			ModifierStack.apply(body, "Bob", { height = 0.4, speed = 1.2 })
		end

		if state.meshModifiers then
			for modName, modParams in pairs(state.meshModifiers) do
				ModifierStack.apply(body, modName, modParams)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		ZundamonSync.clear(player)
	end)

	print("[ZundamonFX] Plugin initialized")
end

function plugin.cleanup()
	print("[ZundamonFX] Plugin cleaned up")
end

return plugin
