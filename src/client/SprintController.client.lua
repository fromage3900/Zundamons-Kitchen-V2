--!strict
-- Hold Left Shift to sprint. Replaces the old SprintOnShift.server.lua
-- bootstrap, which expected a cloneable LocalScript template that never
-- existed (Rojo doesn't cleanly own embedded script children in this
-- project's flat src/client/ convention) -- it always warned and no-opped.
-- Client-authoritative WalkSpeed is fine here: cosmetic movement speed, no
-- gameplay-authority implications (gathering/cooking/serving are all
-- server-validated regardless of how fast the player walked to get there).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local WALK_SPEED = 16
local SPRINT_SPEED = 26

local sprinting = false

local function setSprint(character: Model, on: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	sprinting = on
	humanoid.WalkSpeed = on and SPRINT_SPEED or WALK_SPEED
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		local character = player.Character
		if character then
			setSprint(character, true)
		end
	end
end

local function onInputEnded(input: InputObject, _gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		local character = player.Character
		if character then
			setSprint(character, false)
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

-- Reset to normal speed on respawn (fresh Humanoid, sprint state doesn't carry over)
player.CharacterAdded:Connect(function(character)
	sprinting = false
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		humanoid.WalkSpeed = WALK_SPEED
	end
end)

print("[SprintController] Ready — hold Shift to sprint")
