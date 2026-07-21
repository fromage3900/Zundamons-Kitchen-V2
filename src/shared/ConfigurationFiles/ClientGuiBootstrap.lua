--!strict
-- ClientGuiBootstrap: create Rojo-owned ScreenGuis under PlayerGui (DecorationShop pattern).

local ClientGuiBootstrap = {}

function ClientGuiBootstrap.createScreenGui(player: Player, name: string, displayOrder: number?): ScreenGui
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		existing.Enabled = false
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if displayOrder then
		screenGui.DisplayOrder = displayOrder
	end
	screenGui.Parent = playerGui
	return screenGui
end

return ClientGuiBootstrap
