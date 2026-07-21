-- [[Script] Mineable (ref: RBXF2522A122CFA49CEA3F2FD0377BB82F8)]]
-- Mineable rocks/trees with harvest validator integration
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

local loot_module = require(RS.ConfigurationFiles.LootModule)
local mineableConfig = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("MineableConfig"))
local mineableList = mineableConfig.Mineables

-- HarvestValidator for distance + rate check
local HarvestValidator = SSS:FindFirstChild("Validation") and SSS.Validation:FindFirstChild("HarvestValidator")
local validateHarvest = HarvestValidator and require(HarvestValidator).validateHarvest

function hasWildcardTag(instance, prefix)
	local tags = CollectionService:GetTags(instance)
	for _, tag in ipairs(tags) do
		if string.sub(tag, 1, #prefix) == prefix then
			return tag
		end
	end
	return nil
end

function itemAttributes(item)
	local tags = CollectionService:GetTags(item)
	for _, tag in ipairs(tags) do
		if mineableList[tag] then
			item:SetAttribute("Health", mineableList[tag].Health)
			item:SetAttribute("MaxHealth", mineableList[tag].MaxHealth)
			item:SetAttribute("Respawn", mineableList[tag].Respawn)
			item:SetAttribute("Type", tag)
			break
		end
	end
end

function itemEvent(item)
	item:GetAttributeChangedSignal("Health"):Connect(function()
		local health = item:GetAttribute("Health")
		local mined = item:GetAttribute("Mined")
		if health <= 0 and not mined then
			item:SetAttribute("Mined", true)

			for _, player in pairs(Players:GetPlayers()) do
				local tag = hasWildcardTag(item, player.Name .. "|")
				if tag then
					-- Validate harvest before giving loot
					if validateHarvest then
						local valid, err = validateHarvest(player, item)
						if not valid then
							continue
						end
					else
						-- Fallback: basic distance check
						local char = player.Character
						if not char then
							continue
						end
						local rootpart = char:FindFirstChild("HumanoidRootPart")
						if not rootpart then
							continue
						end
						local dist = (rootpart.Position - item.Position).Magnitude
						if dist > 16 then
							continue
						end
					end

					local split_tag = string.split(tag, "|")
					local loottable = mineableList[item:GetAttribute("Type")].loot[split_tag[2]]
					local rootpart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if rootpart then
						loot_module.generateLoot(
							player,
							loottable,
							Vector3.new(item.Position.X, rootpart.Position.Y, item.Position.Z)
						)
					end
				end
			end

			local model = item:FindFirstAncestorOfClass("Model")
			local obj = model or item

			if item:HasTag("Destroy") then
				item.Parent:SetAttribute("Seeded", false)
				item:Destroy()
			elseif model and model:HasTag("Destroy") then
				model.Parent:SetAttribute("Seeded", false)
				model:Destroy()
			else
				local parent = obj.Parent
				obj.Parent = nil
				task.wait(item:GetAttribute("Respawn"))
				item:SetAttribute("Health", item:GetAttribute("MaxHealth"))
				item:SetAttribute("Mined", false)
				obj.Parent = parent
			end
		end
	end)
end

function addAttributes()
	for _, item in ipairs(CollectionService:GetTagged("Mineable")) do
		itemAttributes(item)
	end
end

function addEvent()
	for _, item in ipairs(CollectionService:GetTagged("Mineable")) do
		itemEvent(item)
	end
end

addAttributes()
addEvent()

CollectionService:GetInstanceAddedSignal("Mineable"):Connect(addAttributes)
