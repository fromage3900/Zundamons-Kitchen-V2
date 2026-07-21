local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RF = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not RF then
	RF = Instance.new("Folder")
	RF.Name = "RemoteFunctions"
	RF.Parent = ReplicatedStorage
end

local executeCmd = RF:FindFirstChild("ExecuteAdminCommand")
if not executeCmd then
	executeCmd = Instance.new("RemoteFunction")
	executeCmd.Name = "ExecuteAdminCommand"
	executeCmd.Parent = RF
end

local AdminService = require(script.Parent.Services.AdminService)
local PluginLoader = require(script.Parent.Services.PluginLoader)

pcall(function()
	require(script.Parent.Services.ModifierBootstrap)
end)

executeCmd.OnServerInvoke = function(player, input)
	local result = AdminService.executeCommand(player, input)
	return result
end

PluginLoader.loadAll()

game:BindToClose(function()
	PluginLoader.unloadAll()
end)

AdminService.registerCommand("plugins", function(player)
	local plugins = PluginLoader.getPlugins()
	local lines = { "=== Plugins ===" }
	for name, info in pairs(plugins) do
		lines[#lines + 1] = string.format("  %s (v%s)", info.name, info.version)
	end
	if #lines == 1 then lines[#lines + 1] = "  No plugins loaded" end
	return table.concat(lines, "\n")
end, "List loaded plugins")

AdminService.registerCommand("reload", function(player, args)
	if args[1] then
		return PluginLoader.reload(args[1])
	end
	return PluginLoader.reload()
end, "Reload plugins: /reload [plugin_name]")

print(string.format("[AdminBootstrap] Ready — %s", RunService:IsStudio() and "Studio mode" or "Live mode"))
