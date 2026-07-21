-- GuestDetector: Client-side detection for clicking guests to serve food
local player = game.Players.LocalPlayer
local character = script.Parent
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()

local INTERACTION_RANGE = 15
local DETECTION_INTERVAL = 0.5

local nearbyGuest = nil
local isDetectingNearbyGuestChanged = Instance.new("BindableEvent")

local function findNearbyGuest()
	local guestFolder = workspace:FindFirstChild("Guests")
	if not guestFolder then return nil end
	local closestGuest = nil
	local closestDistance = INTERACTION_RANGE
	for _, guest in pairs(guestFolder:GetChildren()) do
		local torso = guest:FindFirstChild("Torso")
		if torso then
			local distance = (torso.Position - humanoidRootPart.Position).Magnitude
			if distance < closestDistance then
				closestGuest = guest
				closestDistance = distance
			end
		end
	end
	return closestGuest
end

-- Handle mouse click on a guest — open serve confirmation UI
local function onMouseClick()
	if not nearbyGuest or not nearbyGuest.Parent then return end
	if _G.ZundaShowServeUI then
		_G.ZundaShowServeUI(nearbyGuest, _G.data or {})
	end
end

-- Detection loop
local function detectionLoop()
	while character and character.Parent do
		task.wait(DETECTION_INTERVAL)
		local newGuest = findNearbyGuest()
		if newGuest ~= nearbyGuest then
			nearbyGuest = newGuest
			isDetectingNearbyGuestChanged:Fire(nearbyGuest)
			if nearbyGuest then
				local recipe = nearbyGuest:GetAttribute("PreferredRecipe")
				local pay = nearbyGuest:GetAttribute("PayAmount")
				print("[Guest Nearby] " .. recipe .. " (" .. pay .. " gold)")
				mouse.Icon = "rbxasset://textures/Cursors/MouseLockedCursor.png"
			else
				mouse.Icon = ""
			end
		end
	end
end

mouse.Button1Down:Connect(onMouseClick)
spawn(detectionLoop)

print("[GuestDetector] Started for " .. player.Name)
