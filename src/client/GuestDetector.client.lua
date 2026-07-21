-- GuestDetector: Client-side detection for clicking guests to serve food
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local INTERACTION_RANGE = 15
local DETECTION_INTERVAL = 0.5

local nearbyGuest = nil
local isDetectingNearbyGuestChanged = Instance.new("BindableEvent")

-- Handle mouse click on a guest — open serve confirmation UI
local function onMouseClick()
	if not nearbyGuest or not nearbyGuest.Parent then return end
	if _G.ZundaShowServeUI then
		_G.ZundaShowServeUI(nearbyGuest, _G.data or {})
	end
end
mouse.Button1Down:Connect(onMouseClick)

local function startDetection(character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	task.spawn(function()
		while character and character.Parent do
			task.wait(DETECTION_INTERVAL)
			local guestFolder = workspace:FindFirstChild("Guests")
			local closestGuest = nil
			
			if guestFolder then
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
			end
			
			if closestGuest ~= nearbyGuest then
				nearbyGuest = closestGuest
				isDetectingNearbyGuestChanged:Fire(nearbyGuest)
				if nearbyGuest then
					local recipe = nearbyGuest:GetAttribute("PreferredRecipe")
					local pay = nearbyGuest:GetAttribute("PayAmount")
					print("[Guest Nearby] " .. (recipe or "?") .. " (" .. (pay or "?") .. " gold)")
					mouse.Icon = "rbxasset://textures/Cursors/MouseLockedCursor.png"
				else
					mouse.Icon = ""
				end
			end
		end
	end)
end

if player.Character then
	startDetection(player.Character)
end
player.CharacterAdded:Connect(startDetection)

print("[GuestDetector] Started for " .. player.Name)
