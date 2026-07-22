--!strict
-- [[ModuleScript] UIRouter]]
-- Modal exclusivity and focus stack for the Pea Wheel and all HUD panels.
-- Guarantees only one large modal is open at a time; panels register adapters here.

local UIRouter = {}

local openModals = {}      -- actionId -> boolean
local focusStack = {}      -- ordered list of actionIds
local listeners = {}       -- actionId -> { onOpen, onClose }

-- ── Public API ───────────────────────────────────────────────
function UIRouter.open(actionId: string): boolean
	if openModals[actionId] then
		return false
	end
	-- Close any currently open modal first
	if focusStack[#focusStack] and focusStack[#focusStack] ~= actionId then
		local prev = focusStack[#focusStack]
		local prevListeners = listeners[prev]
		if prevListeners and prevListeners.onClose then
			prevListeners.onClose()
		end
		openModals[prev] = false
		table.remove(focusStack)
	end

	openModals[actionId] = true
	table.insert(focusStack, actionId)

	local actionListeners = listeners[actionId]
	if actionListeners and actionListeners.onOpen then
		actionListeners.onOpen()
	end

	print("[UIRouter] Opened: " .. actionId .. " | Stack: " .. table.concat(focusStack, " -> "))
	return true
end

function UIRouter.close(actionId: string): boolean
	if not openModals[actionId] then
		return false
	end

	local actionListeners = listeners[actionId]
	if actionListeners and actionListeners.onClose then
		actionListeners.onClose()
	end

	openModals[actionId] = false
	for i = #focusStack, 1, -1 do
		if focusStack[i] == actionId then
			table.remove(focusStack, i)
			break
		end
	end

	print("[UIRouter] Closed: " .. actionId .. " | Stack: " .. table.concat(focusStack, " -> "))
	return true
end

function UIRouter.closeAll()
	for i = #focusStack, 1, -1 do
		local actionId = focusStack[i]
		local actionListeners = listeners[actionId]
		if actionListeners and actionListeners.onClose then
			actionListeners.onClose()
		end
		openModals[actionId] = false
	end
	table.clear(focusStack)
	print("[UIRouter] Closed all modals")
end

function UIRouter.isOpen(actionId: string): boolean
	return openModals[actionId] == true
end

function UIRouter.getCurrent(): string?
	return focusStack[#focusStack] or nil
end

function UIRouter.register(actionId: string, onOpen: (() -> ())?, onClose: (() -> ())?)
	listeners[actionId] = {
		onOpen = onOpen,
		onClose = onClose,
	}
end

function UIRouter.unregister(actionId: string)
	listeners[actionId] = nil
	openModals[actionId] = false
	for i = #focusStack, 1, -1 do
		if focusStack[i] == actionId then
			table.remove(focusStack, i)
		end
	end
end

-- ── Escape / B / Back handling ───────────────────────────────
local function onInputBegan(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		local current = UIRouter.getCurrent()
		if current then
			UIRouter.close(current)
		end
	end
end

game:GetService("UserInputService").InputBegan:Connect(onInputBegan)

-- Expose globally
_G.ZundaUIRouter = UIRouter
_G.UIRouter = UIRouter

print("[UIRouter] Modal exclusivity system ready")

return UIRouter