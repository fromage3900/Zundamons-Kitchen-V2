-- GuestDetector: Client-side detection for clicking guests to serve food
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local INTERACTION_RANGE = 15
local DETECTION_INTERVAL = 0.5

local nearbyGuest = nil
local isDetectingNearbyGuestChanged = Instance.new("BindableEvent")

-- Reactive player data: subscribe to the projection remote so the serve UI
-- always has current inventory (cooking a dish after opening the UI now shows it).
local playerStateChanged = RS.RemoteEvents:WaitForChild("PlayerStateChanged")
local latestData = {}
playerStateChanged.OnClientEvent:Connect(function(projection)
	latestData = projection
end)

-- ── Guest Locator Beacon ────────────────────────────────────────────────────
-- Guests roam, so give the player a clear visual beacon above each waiting
-- guest so they're never "hard to locate". A floating "!" bubble + a HUD
-- counter showing how many guests are waiting.
local playerGui = player:WaitForChild("PlayerGui")
local beaconGui = Instance.new("ScreenGui")
beaconGui.Name = "GuestLocatorGui"
beaconGui.ResetOnSpawn = false
beaconGui.DisplayOrder = 60
beaconGui.Parent = playerGui

-- HUD counter (top-left, below any existing HUD)
local counterFrame = Instance.new("Frame", beaconGui)
counterFrame.Name = "GuestCounter"
counterFrame.Size = UDim2.new(0, 180, 0, 36)
counterFrame.Position = UDim2.new(0, 12, 0, 12)
counterFrame.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
counterFrame.BackgroundTransparency = 0.2
counterFrame.BorderSizePixel = 0
Instance.new("UICorner", counterFrame).CornerRadius = UDim.new(0, 10)
local counterStroke = Instance.new("UIStroke", counterFrame)
counterStroke.Color = Color3.fromRGB(255, 200, 80)
counterStroke.Thickness = 1.5

local counterLabel = Instance.new("TextLabel", counterFrame)
counterLabel.Size = UDim2.new(1, 0, 1, 0)
counterLabel.BackgroundTransparency = 1
counterLabel.Text = "👥 0 guests waiting"
counterLabel.Font = Enum.Font.GothamBold
counterLabel.TextSize = 14
counterLabel.TextColor3 = Color3.fromRGB(255, 240, 255)

-- Track beacons per guest so we can clean them up
local beacons = {} -- [guest] = BillboardGui

local function clearBeacons()
	for guest, bill in pairs(beacons) do
		if bill and bill.Parent then
			bill:Destroy()
		end
	end
	beacons = {}
end

local function updateCounter(count)
	counterLabel.Text = "👥 " .. count .. " guest" .. (count == 1 and "" or "s") .. " waiting"
end

-- Handle mouse click on a guest — open serve confirmation UI
local function onMouseClick()
	if not nearbyGuest or not nearbyGuest.Parent then
		return
	end
	if _G.ZundaShowServeUI then
		_G.ZundaShowServeUI(nearbyGuest, latestData)
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
			local guestCount = 0

			if guestFolder then
				local closestDistance = INTERACTION_RANGE
				for _, guest in pairs(guestFolder:GetChildren()) do
					local torso = guest:FindFirstChild("Torso")
					if torso then
						guestCount += 1
						-- Add/refresh a beacon above this guest so they're easy to spot.
						if not beacons[guest] then
							local bill = Instance.new("BillboardGui")
							bill.Name = "GuestBeacon"
							bill.Size = UDim2.new(0, 40, 0, 40)
							bill.StudsOffset = Vector3.new(0, 5, 0)
							bill.AlwaysOnTop = true
							bill.Adornee = torso
							bill.Parent = beaconGui

							local bubble = Instance.new("TextLabel", bill)
							bubble.Size = UDim2.new(1, 0, 1, 0)
							bubble.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
							bubble.BackgroundTransparency = 0.2
							bubble.Text = "!"
							bubble.Font = Enum.Font.GothamBlack
							bubble.TextSize = 24
							bubble.TextColor3 = Color3.fromRGB(60, 40, 10)
							Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)

							-- Gentle pulse so it draws the eye.
							local pulse = TweenService:Create(
								bubble,
								TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true),
								{ Size = UDim2.new(1.2, 0, 1.2, 0), BackgroundTransparency = 0.5 }
							)
							pulse:Play()

							beacons[guest] = bill
						end

						local distance = (torso.Position - humanoidRootPart.Position).Magnitude
						if distance < closestDistance then
							closestGuest = guest
							closestDistance = distance
						end
					end
				end
			end

			-- Clean up beacons for guests that despawned.
			for guest, bill in pairs(beacons) do
				if not guest.Parent then
					if bill and bill.Parent then
						bill:Destroy()
					end
					beacons[guest] = nil
				end
			end

			updateCounter(guestCount)

			if closestGuest ~= nearbyGuest then
				nearbyGuest = closestGuest
				isDetectingNearbyGuestChanged:Fire(nearbyGuest)
				if nearbyGuest then
					local recipe = nearbyGuest:GetAttribute("PreferredRecipe")
					local pay = nearbyGuest:GetAttribute("PayAmount")
					print("[Guest Nearby] " .. (recipe or "?") .. " (" .. (pay or "?") .. " gold)")
					-- Zunda cursor set: point at the servable guest.
					local zc = _G.ZundaCursors
					if zc then
						zc.setCursor("person")
					else
						local CursorConfig = require(RS.ConfigurationFiles.CursorConfig)
						mouse.Icon = CursorConfig.getCursor("person")
					end
				else
					local zc = _G.ZundaCursors
					if zc then
						zc.restore()
					else
						mouse.Icon = ""
					end
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
