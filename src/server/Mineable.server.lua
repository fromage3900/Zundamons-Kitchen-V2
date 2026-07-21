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
local validateHarvest
local ok, hvMod = pcall(require, SSS.Validation.HarvestValidator)
if ok and hvMod then validateHarvest = hvMod.validateHarvest end

local function getItemPos(item: Instance): Vector3
	if not item then return Vector3.zero end
	return if item:IsA("BasePart")
		then item.Position
		else (if item:IsA("Model") then (item.PrimaryPart and item.PrimaryPart.Position or item:GetPivot().Position) else Vector3.zero)
end

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
	local found = false
	for _, tag in ipairs(tags) do
		if mineableList[tag] then
			item:SetAttribute("Health", mineableList[tag].Health)
			item:SetAttribute("MaxHealth", mineableList[tag].MaxHealth)
			item:SetAttribute("Respawn", mineableList[tag].Respawn)
			item:SetAttribute("Type", tag)
			found = true
			break
		end
	end
	if not found then
		if item:GetAttribute("Health") == nil then item:SetAttribute("Health", 30) end
		if item:GetAttribute("MaxHealth") == nil then item:SetAttribute("MaxHealth", 30) end
		if item:GetAttribute("Respawn") == nil then item:SetAttribute("Respawn", 10) end
		if item:GetAttribute("Type") == nil then item:SetAttribute("Type", "Rock") end
	end
end

function itemEvent(item)
	item:GetAttributeChangedSignal("Health"):Connect(function()
		local health = item:GetAttribute("Health")
		local mined = item:GetAttribute("Mined")
		if typeof(health) == "number" and health <= 0 and not mined then
			item:SetAttribute("Mined", true)

			local itemPos = getItemPos(item)

			for _, player in pairs(Players:GetPlayers()) do
				local tag = hasWildcardTag(item, tostring(player.UserId) .. "|")
				if tag then
					-- Validate harvest before giving loot (use node_break context to allow co-op)
					if validateHarvest then
						local valid, err = validateHarvest(player, item, "node_break")
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
						local dist = (rootpart.Position - itemPos).Magnitude
						if dist > 16 then
							continue
						end
					end

					local split_tag = string.split(tag, "|")
					local tierKey = (split_tag and split_tag[2]) or "Tier1"
					local nodeType = item:GetAttribute("Type") or "Rock"
					local mineableData = mineableList[nodeType] or mineableList["Rock"]
					local loottable = (mineableData and mineableData.loot and mineableData.loot[tierKey])
						or (mineableData and mineableData.loot and mineableData.loot.Tier1)
						or {}

					local rootpart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if rootpart then
						loot_module.generateLoot(
							player,
							loottable,
							Vector3.new(itemPos.X, rootpart.Position.Y, itemPos.Z)
						)
					end

					-- Clean up dynamic hit tag for this player
					CollectionService:RemoveTag(item, tag)
				end
			end

			-- Clean up any lingering player tags on the item
			for _, tag in ipairs(CollectionService:GetTags(item)) do
				if string.find(tag, "|") then
					CollectionService:RemoveTag(item, tag)
				end
			end

			local model = item:FindFirstAncestorOfClass("Model")
			local obj = model or item

			if item:HasTag("Destroy") then
				if item.Parent then item.Parent:SetAttribute("Seeded", false) end
				item:Destroy()
			elseif model and model:HasTag("Destroy") then
				if model.Parent then model.Parent:SetAttribute("Seeded", false) end
				model:Destroy()
			else
				local parent = obj.Parent
				obj.Parent = nil
				local respawnTime = item:GetAttribute("Respawn") or 10
				task.wait(respawnTime)
				item:SetAttribute("Health", item:GetAttribute("MaxHealth") or 30)
				item:SetAttribute("Mined", false)
				obj.Parent = parent
			end
		end
	end)
end

local boundItems = setmetatable({}, { __mode = "k" })

local function setupMineableItem(item)
	if not item or boundItems[item] then return end
	boundItems[item] = true
	itemAttributes(item)
	itemEvent(item)
end

function addAttributes()
	for _, item in ipairs(CollectionService:GetTagged("Mineable")) do
		setupMineableItem(item)
	end
end

addAttributes()

CollectionService:GetInstanceAddedSignal("Mineable"):Connect(setupMineableItem)
