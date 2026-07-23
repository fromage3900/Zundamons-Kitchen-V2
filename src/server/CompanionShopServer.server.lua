-- [[Script] CompanionShopServer (ref: RBX9AC1C5F5123A408F978AA7077D298CC8)]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game.ReplicatedStorage
local RE = RS:WaitForChild("RemoteEvents")
local RF = RS:WaitForChild("RemoteFunctions")
local MarketplaceConfig = require(RS.ConfigurationFiles.MarketplaceConfig)
local CompanionConfig = require(RS.ConfigurationFiles.CompanionConfig)

local PurchaseCompanion = RE:WaitForChild("PurchaseCompanion")
local CompanionOwnedSync = RE:WaitForChild("CompanionOwnedSync")
local SetCompanionRE = RE:WaitForChild("SetCompanion")
local GetCompanionCatalog = RF:WaitForChild("GetCompanionCatalog")
local GetOwnedCompanions = RF:WaitForChild("GetOwnedCompanions")

-- Product IDs come from the canonical marketplace catalog and fail closed
-- until MarketplaceConfig.enabled is explicitly set for a verified release.
local DEVPRODUCT_IDS = MarketplaceConfig.companionDevProductIds

-- Map productId -> compType (built reverse)
local productToComp = {}
for k, v in pairs(DEVPRODUCT_IDS) do
	if v ~= 0 then
		productToComp[v] = k
	end
end

-- Pending purchases per player so we can credit on success
local pending = {}

local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)

PurchaseCompanion.OnServerEvent:Connect(function(player, compType)
	local cat = CompanionConfig.companions
	if not cat then
		return
	end
	local def = cat[compType]
	if not def or def.free then
		return
	end
	if PlayerDataService.get(player) and PlayerDataService.get(player)["companion_owned_" .. compType] then
		return -- already owned
	end
	local pid = DEVPRODUCT_IDS[compType]
	if MarketplaceConfig.enabled and pid and pid ~= 0 and MarketplaceConfig.isValidProductId(pid) then
		pending[player.UserId] = pending[player.UserId] or {}
		pending[player.UserId][pid] = compType
		local ok, err = pcall(function()
			MarketplaceService:PromptProductPurchase(player, pid)
		end)
		if not ok then
			warn("[CompanionShop] prompt failed:", err)
		end
	else
		warn(string.format("[CompanionShop] Purchase unavailable for %s; marketplace is not configured", compType))
	end
end)

-- ProcessReceipt delegated to MarketplaceService.lua (unified handler)

GetCompanionCatalog.OnServerInvoke = function(player)
	return CompanionConfig.companions
end

GetOwnedCompanions.OnServerInvoke = function(player)
	local owned = {}
	for compType, def in pairs(CompanionConfig.companions) do
		if def.free then
			owned[compType] = true
		end
	end
	local data = PlayerDataService.get(player)
	if data then
		for k, v in pairs(data) do
			if v == true then
				local pre, name = string.match(k, "(companion_owned_)(.+)")
				if pre then
					owned[name] = true
				end
			end
		end
		owned.__active = data.active_companion or "zundamon"
	end
	return owned
end

print("[CompanionShopServer] online")
