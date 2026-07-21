-- [[LocalScript] FishingRodClient (ref: RBX58EB7B19047740BDA82070D53BAE6511)]]
local player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local FishingCast = RS:WaitForChild("ToolRemotes"):WaitForChild("FishingCast")
local boundTools = setmetatable({}, { __mode = "k" })

local function bindFishingRod(tool)
	if tool.Name ~= "FishingRod" or boundTools[tool] then
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
