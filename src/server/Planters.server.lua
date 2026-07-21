-- [[Script] Planters (ref: RBXCCC98DFCA91D42C796F8AF9AD71AD56E)]]
-- Planters: Seed planting + growth in designated planter boxes
-- Performance fix: Growth check now runs at 1Hz instead of Heartbeat
local CollectionService = game:GetService("CollectionService")
local myplanters = CollectionService:GetTagged("Planter")
local plantable = CollectionService:GetTagged("Plantable")
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local showmenu = RE:FindFirstChild("ShowPlantingMenu") or Instance.new("RemoteEvent")
showmenu.Name = "ShowPlantingMenu"
showmenu.Parent = RE
local plantingEvent = RE:FindFirstChild("plantEvent") or Instance.new("RemoteEvent")
plantingEvent.Name = "plantEvent"
plantingEvent.Parent = RE
local configFiles = RS:WaitForChild("ConfigurationFiles")
local plantsConfig = require(configFiles:WaitForChild("PlantConfig"))
local plantsList = plantsConfig.items
local PlayerDataService = require(game.ServerScriptService.Services.PlayerDataService)

local function clonePlant(item, plant)
	local newPlant = plant:Clone()
	newPlant:SetAttribute("Planted_at", tick())
	newPlant.Parent = item
	newPlant.Anchored = true
	newPlant.Position = Vector3.new(item.Position.X, item.Position.Y + newPlant.Size.Y/2, item.Position.Z)
end

local function activvateClickDetector()
	for _, item in ipairs(myplanters) do
		local clickDetector = item:FindFirstChild("ClickDetector")
		if clickDetector then
			clickDetector.MouseClick:Connect(function(player)
				local data = PlayerDataService.get(player)
				if not data then return end
				local myplantables = {}
				for _, plant in ipairs(plantable) do
					if data[plant.Name] then
						myplantables[plant.Name] = data[plant.Name]
					end
				end
				if next(myplantables) ~= nil and not item:GetAttribute("Seeded") then
					showmenu:FireClient(player, myplantables, item)
				end
			end)
		end
	end
end

-- Plant seed via RemoteEvent (player selects seed from menu)
plantingEvent.OnServerEvent:Connect(function(player, seedName, planter)
	local data = PlayerDataService.get(player)
	if not data then return end
	if not planter or planter:GetAttribute("Seeded") == true then return end
	if not data[seedName] or data[seedName] <= 0 then return end

	-- Server-authoritative distance check
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if (root.Position - planter.Position).Magnitude > 16 then return end

	PlayerDataService.update(player, function(d)
		d[seedName] = d[seedName] - 1
		if d[seedName] == 0 then
			d[seedName] = nil
		end
	end)

	-- Find and clone the plant model
	for _, plant in ipairs(plantable) do
		if plant.Name == seedName then
			planter:SetAttribute("Seeded", true)
			clonePlant(planter, plant)
			break
		end
	end
end)

local function growPlants()
	task.spawn(function()
		while true do
			task.wait(1)  -- Check once per second instead of every frame
			for _, item in ipairs(myplanters) do
				if not item.Parent then continue end
				local children = item:GetChildren()
				for _, val in ipairs(children) do
					if plantsList[val.Name] then
						local properties = plantsList[val.Name]
						if properties then
							local time_planted = val:GetAttribute("Planted_at")
							local time_to_grow = properties.Grow_Time
							-- Guard against nil/missing time_planted
							if time_planted and time_to_grow and time_planted > 0 then
								local time_passed = tick() - time_planted
								if time_passed > time_to_grow then
									val:Destroy()
									clonePlant(item, properties.Sprout)
								end
							end
						end
					end
				end
			end
		end
	end)
end

activvateClickDetector()
growPlants()
print("[Planters] Ready - " .. #myplanters .. " planters bound")