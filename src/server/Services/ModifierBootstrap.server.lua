local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModifierStack = require(ReplicatedStorage.Shared.Modules.ModifierStack)

local MODIFIER_PATH = ReplicatedStorage.Shared.Modules.Modifiers
local modifiers = {
	"ScaleModifier", "ColorModifier", "GlowModifier",
	"BobModifier", "SpinModifier", "SwayModifier",
}
local count = 0
for _, name in ipairs(modifiers) do
	local module = MODIFIER_PATH:FindFirstChild(name)
	if module then
		local ok, mod = pcall(function() return require(module) end)
		if ok and mod then
			ModifierStack.register(mod)
			count = count + 1
		end
	end
end
print(string.format("[ModifierBootstrap] Registered %d modifiers", count))

return ModifierStack
