-- [[Script] FishingServer (ref: RBX239CFA74A4314C8BA4594D3791501D48)]]
local RS = game.ReplicatedStorage
local SSS = game.ServerScriptService
local toolRemotes = RS:WaitForChild("ToolRemotes")
local FishingCast = toolRemotes:WaitForChild("FishingCast")
local FishConfig = require(RS.ConfigurationFiles.FishConfig)
local CS = game:GetService("CollectionService")

local RewardCore = require(RS.ConfigurationFiles.RewardCore)
local ChefLevelConfig = require(RS.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(SSS.Services.PlayerDataService)

-- Player invokes FishingCast(action, payload). Two actions:
--   "begin" -> server picks a fish, returns { fishName, rarity, value, color, difficulty }
--   "result" -> client reports caught/escaped with success bool; server awards loot
local activeBites = {}  -- player.Name -> { fish, startTime }

FishingCast.OnServerInvoke = function(player, action, payload)
    if action == "begin" then
        -- Must be holding a FishingRod (Type attribute)
        local char = player.Character
        if not char then return nil end
        local rod
        for _, t in pairs(char:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("Type") == "FishingRod" then rod = t; break end
        end
        if not rod then return { ok = false, reason = "no rod equipped" } end

        local fish = FishConfig.rollFish()
        if not fish then return { ok = false, reason = "bad config" } end
        local diffTable = FishConfig.difficulty
        local diff = diffTable and diffTable[fish.rarity]
        activeBites[player.Name] = { fish = fish, startTime = os.clock() }
        return {
            ok = true,
            fish = fish,
            difficulty = diff or 1,
        }
    elseif action == "result" then
        local bite = activeBites[player.Name]
        if not bite then return { ok = false, reason = "no active bite" } end
        activeBites[player.Name] = nil
        if payload and payload.success then
            local fish = bite.fish
            -- Award gold, XP, popup, mastery
            RewardCore.bumpCombo(player)
            local goldAwarded = RewardCore.addGold(player, fish.value, "serve")
            RewardCore.addXP(player, fish.xp, "craft")
            -- Add to inventory (track count)
			local data = PlayerDataService.getOrCreate(player)
			if data then
				local key = "Fish_" .. fish.name
				data[key] = (data[key] or 0) + 1
			end
            -- Notify popup
            local popup = RS:FindFirstChild("RewardEvents") and RS.RewardEvents:FindFirstChild("PopupEvent")
            if popup then
                popup:FireClient(player, "item", "🎣 " .. fish.name, fish.color)
            end
            RewardCore.notify(player, "fish", { name = fish.name, rarity = fish.rarity, gold = goldAwarded })
            return { ok = true, gold = goldAwarded, fishName = fish.name, rarity = fish.rarity }
        else
            RewardCore.breakCombo(player)
            return { ok = false, reason = "fish escaped" }
        end
    end
    return { ok = false, reason = "unknown action" }
end

print("[FishingServer] online")
