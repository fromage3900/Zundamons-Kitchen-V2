-- [[LocalScript] ChefAura (combo-reactive player glow)]
-- A soft "chef's flow" aura around the player that reacts to the cooking loop:
--   * combo climbs  -> aura brightens, shifts through a warm->hot color ramp
--   * each serve     -> quick pulse
--   * level up       -> full bloom burst + ring shockwave
-- Pure client-side; hooks existing RewardEvents remotes (no new network).
-- Respects ReducedMotion.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local rewardEvents = RS:WaitForChild("RewardEvents")
local ComboUpdate = rewardEvents:WaitForChild("ComboUpdate")
local PopupEvent = rewardEvents:WaitForChild("PopupEvent")
local LevelUpEvent = rewardEvents:WaitForChild("LevelUpEvent")

local reducedMotion = GuiService.ReducedMotionEnabled

-- ── Aura colour ramp by combo tier ────────────────────────────
-- Warm "low heat" (fresh kitchen) -> blazing gold on a big combo.
local COMBO_COLORS = {
	Color3.fromRGB(255, 190, 120), --  0-3  : warm ember
	Color3.fromRGB(255, 220, 130), --  4-7  : simmer gold
	Color3.fromRGB(255, 240, 160), --  8-14 : sizzle
	Color3.fromRGB(255, 200, 80), --  15+  : full blaze
}

-- Light + glow assets, created once and reused across respawns.
local glowLight = Instance.new("PointLight")
glowLight.Name = "ChefAuraLight"
glowLight.Range = 22
glowLight.Brightness = 0
glowLight.Color = COMBO_COLORS[1]
glowLight.Parent = Lighting

local aura = Instance.new("Part")
aura.Name = "ChefAura"
aura.Size = Vector3.new(1, 1, 1)
aura.Transparency = 1
aura.Anchored = true
aura.CanCollide = false
aura.CanQuery = false
aura.CanTouch = false
aura.CastShadow = false
aura.Parent = Lighting

local auraParticle = Instance.new("ParticleEmitter")
auraParticle.Name = "AuraSpark"
auraParticle.Parent = aura
auraParticle.Texture = "rbxassetid://241685484" -- soft spark
auraParticle.Lifetime = NumberRange.new(0.6, 1.2)
auraParticle.Speed = NumberRange.new(0.5, 1.5)
auraParticle.SpreadAngle = Vector2.new(180, 180)
auraParticle.EmissionDirection = Enum.NormalId.Top
auraParticle.Rate = 0
auraParticle.LightEmission = 0.4
auraParticle.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(1, 0.1),
})
auraParticle.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})

local function lerpColor(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function comboColor(combo)
	local n = #COMBO_COLORS
	local idx = math.clamp(math.floor(combo / 4) + 1, 1, n)
	return COMBO_COLORS[idx]
end

-- Current visual intensity target (0..1)
local target = 0
local current = 0

local function setTarget(v)
	target = math.clamp(v, 0, 1)
end

-- ── React to combo ────────────────────────────────────────────
ComboUpdate.OnClientEvent:Connect(function(count)
	local mult = count or 0
	-- Only glow meaningfully once you have a real combo going.
	local t = mult <= 0 and 0 or math.min(0.35 + mult * 0.08, 1)
	setTarget(t)
	glowLight.Color = comboColor(mult)
	auraParticle.Color = ColorSequence.new(comboColor(mult))
	auraParticle.Rate = mult > 0 and math.min(10 + mult * 4, 60) or 0
end)

-- ── Pulse on every serve / reward pop ─────────────────────────
PopupEvent.OnClientEvent:Connect(function()
	setTarget(current > 0.5 and 1 or 0.6)
	-- quick sparkle pop
	auraParticle:Emit(4)
end)

-- ── Full burst on level up ────────────────────────────────────
LevelUpEvent.OnClientEvent:Connect(function(level, tierName, tierColor)
	local burst = Instance.new("Part")
	burst.Name = "ChefAuraBurst"
	burst.Shape = Enum.PartType.Cylinder
	burst.Size = Vector3.new(0.1, 0.1, 0.1)
	burst.CFrame = aura.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	burst.Transparency = 1
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.CastShadow = false
	burst.Parent = aura
	Tween:Create(burst, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(26, 0.4, 26),
	}):Play()
	task.delay(0.9, function()
		burst:Destroy()
	end)
	setTarget(1)
	task.delay(2.5, function()
		setTarget(0.4)
	end)
end)

-- ── Follow the character, animate the glow ────────────────────
local function findRoot(character)
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

RunService.Heartbeat:Connect(function(dt)
	-- smooth current toward target
	current = current + (target - current) * math.min(1, dt * 4)
	if reducedMotion then
		current = 0
	end

	local char = player.Character
	local root = findRoot(char)
	if root then
		local pos = root.Position + Vector3.new(0, 1.4, 0)
		aura.CFrame = CFrame.new(pos)
		auraParticle.Position = Vector3.zero -- part-relative origin
	else
		-- No character: fade the aura out
		current = current * 0.9
	end

	glowLight.Position = aura.Position
	glowLight.Brightness = current * 3.2
end)

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	-- gently re-prime the aura on respawn
	setTarget(0.5)
end)

-- watch runtime ReducedMotion toggle
if GuiService.ReducedMotionEnabled ~= nil then
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		reducedMotion = GuiService.ReducedMotionEnabled
	end)
end

print("[ChefAura] combo-reactive player glow active")
