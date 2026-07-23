local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- SoundService.AmbientReverb is an Enum.ReverbType. The old code referenced a
-- non-existent Enum.AmbientReverbType, which errored on load — the script never ran.
local presets = {
	Kitchen = Enum.ReverbType.PaddedCell,
	Garden = Enum.ReverbType.Forest,
	Pond = Enum.ReverbType.UnderWater,
}

local defaultPreset = Enum.ReverbType.NoReverb
SoundService.AmbientReverb = defaultPreset

local PREFIX = "ReverbZone_"

-- Cache reverb-zone parts instead of scanning the whole workspace every frame.
-- The list is maintained reactively as zones are added/removed.
local zones = {}
local function trackIfZone(inst)
	if inst:IsA("BasePart") and inst.Name:sub(1, #PREFIX) == PREFIX then
		zones[inst] = true
	end
end
for _, inst in ipairs(workspace:GetDescendants()) do
	trackIfZone(inst)
end
workspace.DescendantAdded:Connect(trackIfZone)
workspace.DescendantRemoving:Connect(function(inst)
	zones[inst] = nil
end)

-- Position check does not need per-frame precision; throttle to ~10 Hz.
local CHECK_INTERVAL = 0.1
local accum = CHECK_INTERVAL
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < CHECK_INTERVAL then return end
	accum = 0

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local pos = hrp.Position
	local active = defaultPreset

	for zone in pairs(zones) do
		if not zone.Parent then continue end
		local half = zone.Size / 2
		local localPos = pos - zone.Position
		if math.abs(localPos.X) <= half.X and
		   math.abs(localPos.Y) <= half.Y and
		   math.abs(localPos.Z) <= half.Z then
			active = presets[zone.Name:sub(#PREFIX + 1)] or defaultPreset
			break
		end
	end

	if SoundService.AmbientReverb ~= active then
		SoundService.AmbientReverb = active
	end
end)

print("[ReverbHandler] Ambient reverb zone detection active")
