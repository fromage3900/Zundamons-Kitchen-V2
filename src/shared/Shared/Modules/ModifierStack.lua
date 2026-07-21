local ModifierStack = {}
local registeredModifiers = {}
local activeStacks = {}
local runService = game:GetService("RunService")

function ModifierStack.register(modifier)
	if not modifier or not modifier.name then return end
	registeredModifiers[modifier.name] = modifier
end

function ModifierStack.getRegistered()
	local result = {}
	for name in pairs(registeredModifiers) do
		table.insert(result, name)
	end
	return result
end

function ModifierStack.apply(instance, modifierName, params)
	if not instance then return end
	local mod = registeredModifiers[modifierName]
	if not mod then warn("Modifier not found: " .. modifierName); return end
	if not activeStacks[instance] then
		activeStacks[instance] = {}
		local conn
		conn = runService.RenderStepped:Connect(function(dt)
			local stack = activeStacks[instance]
			if not stack or not instance.Parent then
				if conn then conn:Disconnect() end
				activeStacks[instance] = nil
				return
			end
			for _, entry in ipairs(stack) do
				if entry.mod.update then
					pcall(entry.mod.update, instance, entry.params, dt)
				end
			end
		end)
	end
	table.insert(activeStacks[instance], { mod = mod, params = params or {} })
	if mod.apply then
		pcall(mod.apply, instance, params or {})
	end
	return true
end

function ModifierStack.remove(instance, modifierName)
	local stack = activeStacks[instance]
	if not stack then return end
	for i = #stack, 1, -1 do
		if stack[i].mod.name == modifierName then
			if stack[i].mod.revert then
				pcall(stack[i].mod.revert, instance, stack[i].params)
			end
			table.remove(stack, i)
			return true
		end
	end
	return false
end

function ModifierStack.clear(instance)
	local stack = activeStacks[instance]
	if not stack then return end
	for i = #stack, 1, -1 do
		if stack[i].mod.revert then
			pcall(stack[i].mod.revert, instance, stack[i].params)
		end
	end
	activeStacks[instance] = nil
end

function ModifierStack.getStack(instance)
	return activeStacks[instance]
end

function ModifierStack.hasModifier(instance, modifierName)
	local stack = activeStacks[instance]
	if not stack then return false end
	for _, entry in ipairs(stack) do
		if entry.mod.name == modifierName then return true end
	end
	return false
end

return ModifierStack
