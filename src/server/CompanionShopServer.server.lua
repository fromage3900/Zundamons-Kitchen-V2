-- [[Script] CompanionShopServer (ref: RBX9AC1C5F5123A408F978AA7077D298CC8)]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game.ReplicatedStorage
local RE = RS:WaitForChild("RemoteEvents")
local RF = RS:WaitForChild("RemoteFunctions")

local PurchaseCompanion = RE:WaitForChild("PurchaseCompanion")
local CompanionOwnedSync = RE:WaitForChild("CompanionOwnedSync")
local SetCompanionRE = RE:WaitForChild("SetCompanion")
local GetCompanionCatalog = RF:WaitForChild("GetCompanionCatalog")
local GetOwnedCompanions = RF:WaitForChild("GetOwnedCompanions")

-- Placeholder DevProduct IDs (replace with real IDs after creating in Roblox Studio's Asset Manager)
-- Pattern: each companion has its own DevProduct.
-- If you don't set these yet, the shop falls back to a "test purchase" path
-- that grants ownership immediately so the system can be developed without Robux.
local DEVPRODUCT_IDS = {
    ankomon     = 0,
    cardamon    = 0,
    antimon     = 0,
    sakuradamon = 0,
}

-- Map productId -> compType (built reverse)
local productToComp = {}
for k, v in pairs(DEVPRODUCT_IDS) do if v ~= 0 then productToComp[v] = k end end

-- Pending purchases per player so we can credit on success
local pending = {}

local PlayerDataService = require(script.Parent.Services.PlayerDataService)

PurchaseCompanion.OnServerEvent:Connect(function(player, compType)
    local cat = shared.ZundaCompanionCatalog
    if not cat then return end
    local def = cat[compType]
    if not def or def.free then return end
	if PlayerDataService.get(player) and PlayerDataService.get(player)["companion_owned_" .. compType] then
        return  -- already owned
    end
    local pid = DEVPRODUCT_IDS[compType]
    if pid and pid ~= 0 then
        pending[player.UserId] = pending[player.UserId] or {}
        pending[player.UserId][pid] = compType
        local ok, err = pcall(function()
            MarketplaceService:PromptProductPurchase(player, pid)
        end)
        if not ok then warn("[CompanionShop] prompt failed:", err) end
    else
        -- TEST MODE: grant immediately so dev/playtest flow works without real Robux products
		local data = PlayerDataService.getOrCreate(player)
		data["companion_owned_" .. compType] = true
        CompanionOwnedSync:FireClient(player, compType, true)
        print(string.format("[CompanionShop] TEST grant: %s -> %s", player.Name, compType))
    end
end)

-- ProcessReceipt delegated to MarketplaceService.lua (unified handler)

GetCompanionCatalog.OnServerInvoke = function(player)
    return shared.ZundaCompanionCatalog
end

GetOwnedCompanions.OnServerInvoke = function(player)
	local owned = { zundamon = true, zundacat = true, zundabunny = true, tantanmon = true }
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
