-- [[LocalScript] FishingRodClient (ref: RBX58EB7B19047740BDA82070D53BAE6511)]]
local player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local FishingCast = RS:WaitForChild("ToolRemotes"):WaitForChild("FishingCast")
local boundTools = setmetatable({}, { __mode = "k" })

local function isFishingRod(tool)
	-- Match the server's identity check (FishingService.equippedRod uses the
	-- "Type" attribute), not the display Name. Baked rods ship as e.g.
	-- "Driftwood Rod" with Type="FishingRod"; binding on Name alone silently
	-- never wired Activated, so casting did nothing.
	return tool:GetAttribute("Type") == "FishingRod" or tool.Name == "FishingRod"
end

local function bindFishingRod(tool)
	if not tool:IsA("Tool") or not isFishingRod(tool) or boundTools[tool] then
		return
	end
	boundTools[tool] = true

	local cooldown = 0
	tool.Activated:Connect(function()
		local now = os.clock()
		if now - cooldown < 3 then
			return
		end -- can't recast for 3s
		cooldown = now
		-- Ask server to start a bite
		local ok, resp = pcall(function()
			return FishingCast:InvokeServer("begin")
		end)
		if not ok then
			return
		end
		if not resp or not resp.ok then
			return
		end
		if _G.FishingMinigame and _G.FishingMinigame.start then
			_G.FishingMinigame.start(resp.sessionId, resp.presentation, function(reeling)
				task.spawn(function()
					pcall(function()
						FishingCast:InvokeServer("input", {
							sessionId = resp.sessionId,
							reeling = reeling,
						})
					end)
				end)
			end)
		else
			FishingCast:InvokeServer("cancel", { sessionId = resp.sessionId })
		end
	end)
end

-- Bind existing
if player.Character then
	for _, child in ipairs(player.Character:GetChildren()) do
		if child:IsA("Tool") then
			bindFishingRod(child)
		end
	end
end
local backpack = player:WaitForChild("Backpack")
for _, child in ipairs(backpack:GetChildren()) do
	if child:IsA("Tool") then
		bindFishingRod(child)
	end
end

-- Bind future
player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bindFishingRod(child)
		end
	end)
end)
backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		bindFishingRod(child)
	end
end)

-- Proximity water volume: a subtle bubbling loop that swells as the player nears
-- the pond and fades out with distance. Anchored to AmbientZone_Pond (the same
-- water anchor the server gates fishing on) so the audio cue matches where
-- fishing actually becomes usable.
do
	local RunService = game:GetService("RunService")

	local PROX_NEAR = 12 -- fully audible within this many studs of the water
	local PROX_FAR = 60 -- silent beyond this
	local PROX_MAX_VOLUME = 0.25 -- keep it ambient, never intrusive

	local waterSound = Instance.new("Sound")
	waterSound.Name = "FishingWaterProximity"
	waterSound.SoundId = "rbxassetid://136926771045300" -- Bubbles (SoundConfig.Bubbles)
	waterSound.Looped = true
	waterSound.Volume = 0
	waterSound.Parent = script
	pcall(function()
		waterSound:Play()
	end)

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local pond = workspace:FindFirstChild("AmbientZone_Pond")
		if not root or not pond or not pond:IsA("BasePart") then
			waterSound.Volume = 0
			return
		end
		local distance = (root.Position - pond.Position).Magnitude
		local proximity = math.clamp((PROX_FAR - distance) / (PROX_FAR - PROX_NEAR), 0, 1)
		-- Ease toward the target so entering/leaving the zone glides instead of snapping.
		waterSound.Volume += (proximity * PROX_MAX_VOLUME - waterSound.Volume) * 0.1
	end)
end
