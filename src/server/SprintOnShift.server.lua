--!strict
-- SprintOnShift is retained as a compatibility bootstrap. The legacy place embedded
-- a SprintScript child that Rojo does not own, so missing templates are handled safely.
local Players = game:GetService("Players")

local sprintTemplate = script:FindFirstChild("SprintScript")
if not sprintTemplate or not sprintTemplate:IsA("LocalScript") then
	warn("[SprintOnShift] SprintScript template missing; sprint bootstrap disabled.")
	return
end

local function attach(character: Model)
	if character:FindFirstChild(sprintTemplate.Name) then
		return
	end
	local sprintScript = sprintTemplate:Clone()
	sprintScript.Disabled = false
	sprintScript.Parent = character
end

local function bindPlayer(player: Player)
	if player.Character then
		attach(player.Character)
	end
	player.CharacterAdded:Connect(attach)
end

for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end
Players.PlayerAdded:Connect(bindPlayer)
