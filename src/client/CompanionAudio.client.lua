-- Companion proximity audio: greeting + sparkle + buff sounds when near companion

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local UIAssets = require(RS.Shared.Config.UIAssets)

local COMPANION_DISTANCE = 8

local function playSound(id, vol)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol or 0.6
	s.Parent = player:FindFirstChild("PlayerGui") or player
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(3, function()
		if s.Parent then s:Destroy() end
	end)
end

-- The companion FOLLOWS the player, so "within range" is the steady state.
-- Chime only on the rising edge (re-entering range) with a long cooldown —
-- the old rate-based re-arm played the sound every ~1s forever.
local wasNear = false
local lastChime = 0
local CHIME_COOLDOWN = 30

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local companionModel = workspace:FindFirstChild("ZundaCompanion_" .. player.Name)
	if not companionModel then return end

	local primary = companionModel.PrimaryPart or companionModel:FindFirstChildWhichIsA("BasePart")
	if not primary then return end

	local dist = (hrp.Position - primary.Position).Magnitude
	local isNear = dist < COMPANION_DISTANCE
	if isNear and not wasNear and os.clock() - lastChime >= CHIME_COOLDOWN then
		lastChime = os.clock()
		local sparkle = primary:FindFirstChild("CompanionSparkles")
		if sparkle and sparkle:IsA("ParticleEmitter") then
			sparkle.Rate = 25
			task.delay(1, function()
				if sparkle.Parent then sparkle.Rate = 12 end
			end)
		end
		playSound(UIAssets.sounds.companion_pet, 0.3)
	end
	wasNear = isNear
end)

print("[CompanionAudio] Proximity audio ready")
