-- [[Script] Tools (ref: RBXD8A53484968D46A49B3B6C38EFCE1A4B)]]
-- Overhauled tool dispatcher (proximity-based hit detection, animation-optional)
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RS = game.ReplicatedStorage
local remotes = RS:WaitForChild("ToolRemotes")
local ConnectFunction = remotes:WaitForChild("ConnectFunction")
local configFiles = RS:WaitForChild("ConfigurationFiles")
local toolsConfig = require(configFiles:WaitForChild("ToolsConfig"))
local toolList = toolsConfig.tools

local HIT_RADIUS = 8       -- studs within which a swing connects
local SWING_DURATION = 0.5

function playHitSound(handle)
	if not handle then return end
	local preloaded = handle:FindFirstChild("HitSound")
	if preloaded then preloaded:Play(); return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://14133663945"
	s.Volume = 0.5
	s.Parent = handle
	s:Play()
	Debris:AddItem(s, 2)
end

function swingVisual(character)
	local shoulder
	for _, m in pairs(character:GetDescendants()) do
		if m:IsA("Motor6D") and (m.Name == "RightShoulder" or m.Name == "Right Shoulder") then
			shoulder = m
			break
		end
	end
	if not shoulder then return end
	local orig = shoulder.C0
	shoulder.C0 = orig * CFrame.Angles(math.rad(-110), 0, 0)
	TweenService:Create(shoulder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { C0 = orig }):Play()
end

local TOOL_NODE_MATCHES: { [string]: { [string]: boolean } } = {
	["PickAxe"] = { ["Rock"] = true, ["MarbleRock"] = true, ["GoldRock"] = true },
	["Axe"]     = { ["AppleTree"] = true, ["PineTree"] = true },
	["Sickle"]  = { ["Wheat"] = true, ["ZundaMushroom"] = true, ["ZundaBerry"] = true, ["ZundaRoot"] = true },
}

local function canToolHitNode(node: Instance, toolType: string): boolean
	if CollectionService:HasTag(node, toolType) then
		return true
	end
	local matches = TOOL_NODE_MATCHES[toolType]
	if matches then
		local nodeType = node:GetAttribute("Type")
		if nodeType and matches[nodeType] then
			return true
		end
		for _, tag in ipairs(CollectionService:GetTags(node)) do
			if matches[tag] then
				return true
			end
		end
	end
	return false
end

function findHitTargets(handle, toolType)
	local targets = {}
	if not handle then return targets end
	local origin = handle.Position
	for _, node in pairs(CollectionService:GetTagged("Mineable")) do
		if node.Parent and canToolHitNode(node, toolType) then
			local nodePos = if node:IsA("BasePart") then node.Position else (node:IsA("Model") and (node.PrimaryPart and node.PrimaryPart.Position or node:GetPivot().Position) or Vector3.zero)
			local dist = (nodePos - origin).Magnitude
			if dist <= HIT_RADIUS then
				table.insert(targets, { node = node, dist = dist })
			end
		end
	end
	table.sort(targets, function(a, b) return a.dist < b.dist end)
	return targets
end


function Activated(player, toolName)
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	local mytool = character:FindFirstChild(toolName)
	if not mytool or not mytool:IsA("Tool") then return false end
	if mytool:GetAttribute("Swinging") then return false end

	-- Resolve tool type and tier from attributes (with tag fallback)
	local tool_type = mytool:GetAttribute("Type")
	local usedTool = tool_type and toolList[tool_type]
	if not usedTool then
		for _, tag in ipairs(CollectionService:GetTags(mytool)) do
			if toolList[tag] then tool_type = tag; usedTool = toolList[tag]; break end
		end
	end
	if not usedTool then return false end

	local tier = mytool:GetAttribute("Tier") or "Tier1"
	local tierData = usedTool.Tiers[tier] or usedTool.Tiers.Tier1
	local damage = tierData and tierData.Damage or 10

	mytool:SetAttribute("Swinging", true)
	local hitAny = false

	local success, err = pcall(function()
		local handle = mytool:FindFirstChild("Handle")

		-- Visual swing (no Animation asset needed)
		swingVisual(character)

		-- Proximity-based hit at mid-swing
		task.wait(SWING_DURATION * 0.4)

		-- Verify character and tool validity after yield
		if not player.Character or player.Character ~= character or humanoid.Health <= 0 then
			return
		end
		if not mytool or mytool.Parent ~= character then
			return
		end

		local targets = findHitTargets(handle, tool_type)
		for _, t in ipairs(targets) do
			local node = t.node
			if node.Parent then
				hitAny = true
				CollectionService:AddTag(node, tostring(player.UserId) .. "|" .. tier)
				local health = node:GetAttribute("Health")
				if health then
					node:SetAttribute("Health", math.max(health - damage, 0))
				end
				playHitSound(handle)
				-- Small visual nudge for BasePart
				if node:IsA("BasePart") then
					local originCFrame = node.CFrame
					TweenService:Create(node, TweenInfo.new(0.08), { CFrame = originCFrame * CFrame.new(0, 0.2, 0) }):Play()
					task.delay(0.08, function()
						if node and node.Parent and node:IsA("BasePart") then
							TweenService:Create(node, TweenInfo.new(0.1), { CFrame = originCFrame }):Play()
						end
					end)
				end
				break -- only hit one per swing
			end
		end
		task.wait(SWING_DURATION * 0.6)
	end)

	mytool:SetAttribute("Swinging", false)
	if not success and err then
		warn("[Tools.server] Error during tool swing: " .. tostring(err))
	end
	return hitAny
end

ConnectFunction.OnServerInvoke = Activated
