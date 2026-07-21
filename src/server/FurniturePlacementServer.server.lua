-- Server-side furniture placement: purchase, place, remove.
local RS = game:GetService("ReplicatedStorage")
local RF = RS:WaitForChild("RemoteFunctions")
local DecorationConfig = require(RS.ConfigurationFiles.DecorationConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local function allItems()
	local out = {}
	for _, item in ipairs(DecorationConfig.garden_items) do table.insert(out, item) end
	for _, item in ipairs(DecorationConfig.cottage_items) do table.insert(out, item) end
	return out
end

local function findItem(itemId)
	for _, item in ipairs(allItems()) do if item.id == itemId then return item end end
	return nil
end

local function recomputeDecorBuffs(player)
	local d = PlayerDataService.get(player)
	if not d then return end
	d.active_decor_buffs = { patience = 0, gold = 0, xp = 0 }
	for _, p in ipairs(d.placed_furniture or {}) do
		local item = findItem(p.itemId)
		if item and item.buff then
			local m = d.active_decor_buffs[item.buff.stat]
			if m ~= nil then
				d.active_decor_buffs[item.buff.stat] = m + item.buff.magnitude
			end
		end
	end
end

-- PurchaseFurniture(player, itemId) → success, message
local purchaseRF = RF:FindFirstChild("PurchaseFurniture")
if not purchaseRF then purchaseRF = Instance.new("RemoteFunction"); purchaseRF.Name = "PurchaseFurniture"; purchaseRF.Parent = RF end
purchaseRF.OnServerInvoke = function(player, itemId)
	local d = PlayerDataService.get(player)
	if not d then return false, "Data not ready" end
	local item = findItem(itemId)
	if not item then return false, "Item not found" end
	if not d.furniture_unlocked then d.furniture_unlocked = {} end
	if table.find(d.furniture_unlocked, itemId) then return false, "Already owned" end
	if (d.gold or 0) < (item.price or 0) then return false, "Need " .. item.price .. " gold" end
	d.gold = d.gold - item.price
	table.insert(d.furniture_unlocked, itemId)
	print("[Furniture] " .. player.Name .. " bought " .. itemId .. " for " .. item.price .. "g")
	return true, "Purchased " .. item.name
end

-- PlaceFurniture(player, itemId, position, rotation) → success, message
local placeRF = RF:FindFirstChild("PlaceFurniture")
if not placeRF then placeRF = Instance.new("RemoteFunction"); placeRF.Name = "PlaceFurniture"; placeRF.Parent = RF end
placeRF.OnServerInvoke = function(player, itemId, posX, posY, posZ, rotX, rotY, rotZ)
	local d = PlayerDataService.get(player)
	if not d then return false, "Data not ready" end
	if not d.owned_plot then return false, "No plot owned" end
	local item = findItem(itemId)
	if not item then return false, "Item not found" end
	if not d.furniture_unlocked or not table.find(d.furniture_unlocked, itemId) then return false, "Not owned" end
	if not d.placed_furniture then d.placed_furniture = {} end
	if #d.placed_furniture >= 10 then return false, "Max 10 items placed" end
	if typeof(posX) ~= "number" then return false, "Invalid position" end
	local pos = Vector3.new(posX, posY, posZ)
	local rot = Vector3.new(rotX or 0, rotY or 0, rotZ or 0)
	if (pos - Vector3.new(155, -508, -430)).Magnitude > 30 then return false, "Too far from plot area" end
	table.insert(d.placed_furniture, {
		itemId = itemId,
		x = posX, y = posY, z = posZ,
		rx = rotX or 0, ry = rotY or 0, rz = rotZ or 0,
	})
	recomputeDecorBuffs(player)
	print("[Furniture] " .. player.Name .. " placed " .. itemId .. " at " .. tostring(pos))
	return true, "Placed!"
end

-- RemoveFurniture(player, index) → success, message
local removeRF = RF:FindFirstChild("RemoveFurniture")
if not removeRF then removeRF = Instance.new("RemoteFunction"); removeRF.Name = "RemoveFurniture"; removeRF.Parent = RF end
removeRF.OnServerInvoke = function(player, index)
	local d = PlayerDataService.get(player)
	if not d then return false, "Data not ready" end
	if not d.placed_furniture or not d.placed_furniture[index] then return false, "Not found" end
	table.remove(d.placed_furniture, index)
	recomputeDecorBuffs(player)
	print("[Furniture] " .. player.Name .. " removed placement index " .. index)
	return true, "Removed"
end

-- GetPlacedFurniture(player) → list of placements
local getRF = RF:FindFirstChild("GetPlacedFurniture")
if not getRF then getRF = Instance.new("RemoteFunction"); getRF.Name = "GetPlacedFurniture"; getRF.Parent = RF end
getRF.OnServerInvoke = function(player)
	local d = PlayerDataService.get(player)
	if not d then return {} end
	return d.placed_furniture or {}
end

print("[FurniturePlacementServer] Ready")
