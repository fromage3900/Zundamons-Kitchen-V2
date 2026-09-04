-- Fix Mineable node collision: ensure rocks/ores are solid AND properly sized
-- Runs at startup and listens for new nodes

print("[RockFix] === Rock collision fix START ===")

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local ROCK_TYPES = { Rock = true, MarbleRock = true, GoldRock = true }
local ROCK_HITBOX_SIZE = 13 -- Large hitbox for rocks
local DEFAULT_HITBOX_SIZE = 5 -- Smaller hitbox for other harvestables

local function fixPart(part)
	if not part:IsA("BasePart") then
		return
	end
	-- Only fix parts tagged as Mineable (rocks, ores, trees)
	if not CollectionService:HasTag(part, "Mineable") then
		return
	end

	-- Enable collision
	part.CanCollide = true

	-- Determine the appropriate hitbox size based on node type
	local nodeType = part:GetAttribute("Type") or "Unknown"
	local maxSize = ROCK_TYPES[nodeType] and ROCK_HITBOX_SIZE or DEFAULT_HITBOX_SIZE

	-- Shrink oversized Parts to match the appropriate size
	local maxDim = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	if maxDim > maxSize then
		part.Size = Vector3.new(maxSize, maxSize, maxSize)
		print(string.format("[RockFix] Shrank %s hitbox to %s (type: %s)", part.Name, tostring(part.Size), nodeType))
	end
end

-- Apply to all existing parts
for _, desc in ipairs(workspace:GetDescendants()) do
	fixPart(desc)
end

-- Apply to parts added later
workspace.DescendantAdded:Connect(fixPart)

-- Also re-apply every frame for Mineable parts (in case other scripts override it)
RunService.Heartbeat:Connect(function()
	for _, part in ipairs(CollectionService:GetTagged("Mineable")) do
		if part:IsA("BasePart") then
			if part.CanCollide == false then
				part.CanCollide = true
			end
			local nodeType = part:GetAttribute("Type") or "Unknown"
			local maxSize = ROCK_TYPES[nodeType] and ROCK_HITBOX_SIZE or DEFAULT_HITBOX_SIZE
			local maxDim = math.max(part.Size.X, part.Size.Y, part.Size.Z)
			if maxDim > maxSize then
				part.Size = Vector3.new(maxSize, maxSize, maxSize)
			end
		end
	end
end)

print("[RockFix] === Rock collision fix END ===")
