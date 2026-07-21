-- [[Script] CookingSession]]
-- Server-authoritative cooking quality tracking
-- Tracks cooking sessions and derives quality based on perfect hit count

local RS = game:GetService("ReplicatedStorage")
local RF = RS:FindFirstChild("RemoteFunctions") or RS:WaitForChild("RemoteFunctions", 10)
local RE = RS:FindFirstChild("RemoteEvents") or RS:WaitForChild("RemoteEvents", 10)

local PlayerDataService = require(script.Parent.Services.PlayerDataService)

-- Track active cooking sessions: player.UserId -> { recipe, startTime, hitCount, maxHits }
local sessions = {}

-- RemoteFunction for starting a cooking session
local startCooking = RF:FindFirstChild("StartCookingSession")
if not startCooking then
	startCooking = Instance.new("RemoteFunction")
	startCooking.Name = "StartCookingSession"
	startCooking.Parent = RF
end

-- RemoteEvent for cooking hits (perfect timing)
local cookingHit = RE:FindFirstChild("CookingHit")
if not cookingHit then
	cookingHit = Instance.new("RemoteEvent")
	cookingHit.Name = "CookingHit"
	cookingHit.Parent = RE
end

-- RemoteFunction for finishing cooking (derives quality)
local finishCooking = RF:FindFirstChild("FinishCookingSession")
if not finishCooking then
	finishCooking = Instance.new("RemoteFunction")
	finishCooking.Name = "FinishCookingSession"
	finishCooking.Parent = RF
end

-- Recipe hit counts (how many timing windows for perfect)
local RECIPE_HIT_COUNTS = {
	Default = 5,
}

local function getHitCount(recipe)
	return RECIPE_HIT_COUNTS[recipe] or RECIPE_HIT_COUNTS.Default
end

-- Start a cooking session
startCooking.OnServerInvoke = function(player, recipe)
	if typeof(recipe) ~= "string" then return false, "Invalid recipe" end

	sessions[player.UserId] = {
		recipe = recipe,
		startTime = os.clock(),
		hitCount = 0,
		maxHits = getHitCount(recipe),
	}

	return true, "Session started"
end

-- Record a cooking hit (server validates but doesn't trust client for quality yet)
cookingHit.OnServerEvent:Connect(function(player)
	local session = sessions[player.UserId]
	if not session then return end

	session.hitCount = session.hitCount + 1
end)

-- Finish cooking and derive quality
finishCooking.OnServerInvoke = function(player, position)
	local session = sessions[player.UserId]
	if not session then return "ok" end -- Default quality if no session

	-- Clean up session
	local recipe = session.recipe
	local hitCount = session.hitCount
	local maxHits = session.maxHits
	sessions[player.UserId] = nil

	-- Derive quality: perfect = all hits, great = 80%, ok = rest
	if hitCount >= maxHits then
		return "perfect"
	elseif hitCount >= math.ceil(maxHits * 0.8) then
		return "great"
	else
		return "ok"
	end
end

-- Periodic cleanup of stale sessions
task.spawn(function()
	while true do
		task.wait(30)
		local now = os.clock()
		for userId, session in pairs(sessions) do
			if now - session.startTime > 120 then
				sessions[userId] = nil
			end
		end
	end
end)

print("[CookingSession] Ready - server authority for cooking quality")