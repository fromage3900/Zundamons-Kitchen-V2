-- Places 3D ambient zone sounds using AudioEmitter for positional audio.
-- Zones: Kitchen (crackling fire), Garden (birds), Pond (water stream)

local ZONE_AUDIO = {
	Kitchen = {
		soundId = "rbxassetid://9112780462",
		volume = 0.12,
		rollOffMin = 5,
		rollOffMax = 25,
		position = Vector3.new(40, 4, -72),
	},
	Garden = {
		soundId = "rbxassetid://9112832297",
		volume = 0.08,
		rollOffMin = 8,
		rollOffMax = 35,
		position = Vector3.new(56, 4, -64),
	},
	Pond = {
		soundId = "rbxassetid://9119646409",
		volume = 0.10,
		rollOffMin = 6,
		rollOffMax = 30,
		position = Vector3.new(52, 10, -88),
	},
}

for zoneName, cfg in pairs(ZONE_AUDIO) do
	local part = Instance.new("Part")
	part.Name = "AmbientZone_" .. zoneName
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Position = cfg.position
	part.Parent = workspace

	local sound = Instance.new("Sound")
	sound.Name = "ZoneAmbience"
	sound.SoundId = cfg.soundId
	sound.Volume = cfg.volume
	sound.Looped = true
	sound.RollOffMinDistance = cfg.rollOffMin
	sound.RollOffMaxDistance = cfg.rollOffMax
	sound.Parent = part
	sound:Play()

	-- AudioEmitter has no CFrame of its own; it must be parented to a BasePart
	-- (here, the positioned zone part) to inherit its position.
	local emitter = Instance.new("AudioEmitter")
	emitter.Name = "Emitter"
	emitter.Parent = part
end

local Players = game:GetService("Players")
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			local existing = hrp:FindFirstChild("ZoneAudioReceiver")
			if not existing then
				-- New audio API instances aren't enabled in every place; fail soft.
				pcall(function()
					local receiver = Instance.new("AudioReceiver")
					receiver.Name = "ZoneAudioReceiver"
					receiver.Parent = hrp
				end)
			end
		end
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

print("[AmbientZoneAudio] 3 zone audio emitters placed (Kitchen/Garden/Pond)")
