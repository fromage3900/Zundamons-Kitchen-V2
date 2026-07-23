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

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local companionModel = workspace:FindFirstChild("ZundaCompanion_" .. player.Name)
	if not companionModel then return end

	local primary = companionModel.PrimaryPart or companionModel:FindFirstChildWhichIsA("BasePart")
	if not primary then return end

	local dist = (hrp.Position - primary.Position).Magnitude
	if dist < COMPANION_DISTANCE then
		local sparkle = primary:FindFirstChild("CompanionSparkles")
		if sparkle and sparkle:IsA("ParticleEmitter") then
			if sparkle.Rate < 20 then
				sparkle.Rate = 25
				playSound(UIAssets.sounds.companion_pet, 0.3)
				task.delay(1, function()
					if sparkle.Parent then sparkle.Rate = 12 end
				end)
			end
		end
	end
end)

print("[CompanionAudio] Proximity audio ready")
