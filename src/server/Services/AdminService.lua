local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerDataService = require(script.Parent.PlayerDataService)

local AdminService = {}
local commands = {}

local function isAdmin(player)
	local userId = player.UserId
	local admins = { [1] = true }
	return admins[userId] == true or RunService:IsStudio()
end

function AdminService.registerCommand(name, handler, help)
	commands[name:lower()] = { handler = handler, help = help or "" }
end

function AdminService.executeCommand(player, input)
	if typeof(input) ~= "string" or input:sub(1, 1) ~= "/" then return end
	if not isAdmin(player) then warn(player.Name .. " tried admin command without permission"); return end
	local parts = input:sub(2):split(" ")
	local cmdName = parts[1]:lower()
	local args = {}
	for i = 2, #parts do args[#args + 1] = parts[i] end
	local cmd = commands[cmdName]
	if not cmd then return "Unknown command. Type /help" end
	local ok, result = pcall(cmd.handler, player, args)
	if not ok then return "Error: " .. tostring(result) end
	return result
end

AdminService.registerCommand("help", function(player)
	local lines = { "=== Admin Commands ===" }
	for name, cmd in pairs(commands) do
		table.insert(lines, string.format("  /%s — %s", name, cmd.help))
	end
	return table.concat(lines, "\n")
end, "Show this help")

AdminService.registerCommand("givegold", function(player, args)
	local amount = tonumber(args[1])
	if not amount or amount < 0 then return "Usage: /givegold <amount>" end
	local data = PlayerDataService.getOrCreate(player)
	data.gold = (data.gold or 0) + amount
	return string.format("Gave %d gold to %s", amount, player.Name)
end, "Give gold to yourself: /givegold 100")

AdminService.registerCommand("giveitem", function(player, args)
	local itemName = args[1]
	local count = tonumber(args[2]) or 1
	if not itemName then return "Usage: /giveitem <name> [count]" end
	local data = PlayerDataService.getOrCreate(player)
	data[itemName] = (data[itemName] or 0) + count
	return string.format("Gave %dx %s", count, itemName)
end, "Give an item: /giveitem Apple 5")

AdminService.registerCommand("scatter", function(player)
	local success, svc = pcall(function()
		return require(game.ServerScriptService.Services.ScatterService)
	end)
	if not success or not svc or not svc.scatterBiome then return "ScatterService not available" end
	local region = Instance.new("Folder")
	region.Name = "AdminScatter_" .. player.Name
	region.Parent = workspace
	local biomeName = args[1] or "zunda_forest"
	task.delay(0.1, function()
		svc.scatterBiome(biomeName, region)
		task.delay(2, function() if region.Parent then region:Destroy() end end)
	end)
	return string.format("Scattering '%s' biome...", biomeName)
end, "Scatter a biome: /scatter [biome_name]")

AdminService.registerCommand("teleport", function(player, args)
	local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
	if not x then return "Usage: /teleport <x> <y> <z>" end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return "Character not loaded" end
	root.CFrame = CFrame.new(x, y or 0, z or 0)
	return string.format("Teleported to (%.0f, %.0f, %.0f)", x, y or 0, z or 0)
end, "Teleport to coordinates: /teleport 200 -515 -410")

AdminService.registerCommand("status", function(player)
	local data = PlayerDataService.get(player)
	if not data then return "No data loaded" end
	local lines = { "=== Player Status ===" }
	lines[#lines + 1] = string.format("Gold: %d", data.gold or 0)
	lines[#lines + 1] = string.format("Level: %d", data.chef and data.chef.level or 1)
	lines[#lines + 1] = string.format("Guests served: %d", data.guests_served or 0)
	lines[#lines + 1] = string.format("Companion: %s", data.active_companion or "none")
	lines[#lines + 1] = string.format("Cooking streak: %d", data.cooking_streak or 0)
	return table.concat(lines, "\n")
end, "Show your player status")

AdminService.registerCommand("listplayers", function()
	local lines = { "=== Players ===" }
	for _, p in ipairs(Players:GetPlayers()) do
		local data = PlayerDataService.get(p)
		lines[#lines + 1] = string.format("  %s (gold: %d, served: %d)",
			p.Name, data and data.gold or 0, data and data.guests_served or 0)
	end
	return table.concat(lines, "\n")
end, "List all online players")

AdminService.registerCommand("systems", function()
	local lines = { "=== System Status ===" }
	local checks = {
		PlayerDataService = PlayerDataService,
		ScatterService = pcall(function() return require(game.ServerScriptService.Services.ScatterService) end),
	}
	for name, ok in pairs(checks) do
		lines[#lines + 1] = string.format("  %s: %s", name, ok and "✅" or "❌")
	end
	local svcCount = #game.ServerScriptService:GetChildren()
	lines[#lines + 1] = string.format("  Server scripts: %d", svcCount)
	return table.concat(lines, "\n")
end, "Check system status")

AdminService.registerCommand("modifiers", function()
	local ModifierStack = require(game.ReplicatedStorage.Shared.Modules.ModifierStack)
	local mods = ModifierStack.getRegistered()
	local lines = { "=== Registered Modifiers ===" }
	for _, name in ipairs(mods) do
		lines[#lines + 1] = string.format("  %s", name)
	end
	return table.concat(lines, "\n")
end, "List registered modifiers")

AdminService.registerCommand("applymod", function(player, args)
	local modName = args[1]
	if not modName then return "Usage: /applymod <modifier_name> [target]" end
	local target = args[2] and args[2]:lower() or "me"
	local instance
	if target == "me" then
		local char = player.Character
		instance = char and char:FindFirstChild("HumanoidRootPart")
		if not instance then return "Character not loaded" end
	elseif target == "mouse" then
		local mouse = player:GetMouse()
		instance = mouse and mouse.Target
		if not instance then return "No target under mouse" end
	end
	if not instance then return "Target not found" end
	local ModifierStack = require(game.ReplicatedStorage.Shared.Modules.ModifierStack)
	ModifierStack.apply(instance, modName, { scale = 2, color = Color3.fromRGB(255, 200, 100), height = 1, speed = 30 })
	return string.format("Applied '%s' to %s", modName, instance.Name)
end, "Apply modifier to target: /applymod Scale [me|mouse]")

AdminService.registerCommand("clearmods", function(player)
	local char = player.Character
	if not char then return "Character not loaded" end
	local ModifierStack = require(game.ReplicatedStorage.Shared.Modules.ModifierStack)
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then ModifierStack.clear(root) end
	for _, child in ipairs(char:GetDescendants()) do
		if child:IsA("BasePart") then
			ModifierStack.clear(child)
		end
	end
	return "Cleared all modifiers from character"
end, "Clear all modifiers from your character")

return AdminService
