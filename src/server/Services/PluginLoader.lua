local ServerScriptService = game:GetService("ServerScriptService")

local PluginLoader = {}
local loadedPlugins = {}

function PluginLoader.getPluginsFolder()
	local folder = ServerScriptService:FindFirstChild("Plugins")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Plugins"
		folder.Parent = ServerScriptService
	end
	return folder
end

function PluginLoader.loadAll()
	local PLUGINS_FOLDER = PluginLoader.getPluginsFolder()
	local count = 0
	for _, child in ipairs(PLUGINS_FOLDER:GetChildren()) do
		if child:IsA("ModuleScript") then
			local ok, plugin = pcall(function()
				local mod = require(child)
				if type(mod) == "table" and type(mod.init) == "function" then
					return mod
				end
				return nil
			end)
			if ok and plugin then
				local initOk, initErr = pcall(plugin.init)
				if initOk then
					loadedPlugins[child.Name] = plugin
					count = count + 1
					print(string.format("[PluginLoader] Loaded: %s v%s", plugin.name or child.Name, plugin.version or "?"))
				else
					warn(string.format("[PluginLoader] Plugin '%s' init failed: %s", child.Name, initErr))
				end
			else
				warn(string.format("[PluginLoader] Skipped '%s' — missing init() function", child.Name))
			end
		end
	end
	print(string.format("[PluginLoader] Loaded %d plugins", count))
	return loadedPlugins
end

function PluginLoader.unloadAll()
	for name, plugin in pairs(loadedPlugins) do
		local ok, err = pcall(plugin.cleanup or function() end)
		if not ok then warn(string.format("[PluginLoader] Cleanup failed for '%s': %s", name, err)) end
	end
	loadedPlugins = {}
	print("[PluginLoader] All plugins unloaded")
end

function PluginLoader.reload(name)
	local folder = PluginLoader.getPluginsFolder()
	if name then
		local plugin = loadedPlugins[name]
		if plugin and plugin.cleanup then pcall(plugin.cleanup) end
		loadedPlugins[name] = nil
		local module = folder:FindFirstChild(name)
		if module and module:IsA("ModuleScript") then
			pcall(function() module:ClearAllChildren() end)
			local ok, newPlugin = pcall(require, module)
			if ok and newPlugin and newPlugin.init then
				pcall(newPlugin.init)
				loadedPlugins[name] = newPlugin
				return ("Plugin '%s' reloaded"):format(name)
			end
		end
		return ("Plugin '%s' not found"):format(name)
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			PluginLoader.reload(child.Name)
		end
	end
	return "All plugins reloaded"
end

function PluginLoader.getPlugins()
	local result = {}
	for name, plugin in pairs(loadedPlugins) do
		result[name] = { name = plugin.name or name, version = plugin.version or "?" }
	end
	return result
end

return PluginLoader
