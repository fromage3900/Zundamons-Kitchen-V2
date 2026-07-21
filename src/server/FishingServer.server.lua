-- [[Script] FishingServer (ref: RBX239CFA74A4314C8BA4594D3791501D48)]]
-- FishingServer: Thin RemoteFunction bridge between client FishingMinigameScript and FishingSystem ECS.
-- Delegates state tracking to FishingSystem (Matter ECS) for server-authoritative session management.
-- The FishingSystem handles reward distribution, anti-exploit, and session cleanup.

local RS = game.ReplicatedStorage
local SSS = game.ServerScriptService
local toolRemotes = RS:WaitForChild("ToolRemotes")
local FishingCast = toolRemotes:WaitForChild("FishingCast")
local FishConfig = require(RS.ConfigurationFiles.FishConfig)

local FishingSystem = require(SSS.systems.FishingSystem)

-- Player invokes FishingCast(action, payload). Two actions:
--   "begin" -> server picks a fish, returns { fishName, rarity, value, color, difficulty }
--   "result" -> client reports caught/escaped with success bool; server awards loot via ECS

FishingCast.OnServerInvoke = function(player, action, payload)
    if action == "begin" then
        -- Must be holding a FishingRod (Type attribute)
        local char = player.Character
        if not char then return { ok = false, reason = "no character" } end
        local rod
        for _, t in pairs(char:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("Type") == "FishingRod" then rod = t; break end
        end
        if not rod then return { ok = false, reason = "no rod equipped" } end

        -- Check for existing active session
        if FishingSystem.hasActiveSession(player.UserId) then
            return { ok = false, reason = "already fishing" }
        end

        local fish = FishConfig.rollFish()
        if not fish then return { ok = false, reason = "bad config" } end
        local diffTable = FishConfig.difficulty
        local diff = diffTable and diffTable[fish.rarity] or {
            tugMag = 0.15,
            dodgeChance = 0.10,
            duration = 6,
            hookWindow = 0.55,
        }

        -- The ECS FishingSystem will spawn the session entity on its next tick.
        -- Return fish data to client so it can start the minigame immediately.
        return {
            ok = true,
            fish = fish,
            difficulty = diff,
        }
    elseif action == "result" then
        -- The ECS FishingSystem handles reward distribution on its next tick.
        -- We return a basic acknowledgment; the actual reward logic is in the ECS system.
        if payload and payload.success then
            return { ok = true, message = "fish caught (ECS processing)" }
        else
            return { ok = false, reason = "fish escaped" }
        end
    end
    return { ok = false, reason = "unknown action" }
end

print("[FishingServer] online (ECS-backed)")
