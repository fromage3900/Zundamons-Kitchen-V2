local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Companion = require(game.ReplicatedStorage.components.Companion)
local Owner = require(game.ReplicatedStorage.components.Owner)
local BuffProvider = require(game.ReplicatedStorage.components.BuffProvider)

local DataManager = require(game.ServerScriptService:WaitForChild("Services"):WaitForChild("DataManager"))

-- Infinity Nikki Lens:
-- Server-authoritative buff management. Players cannot spoof their pet stats.
local function CompanionBuffSystem(world)
	-- Every frame, we check if any active buffs need to be applied
	for id, companion, owner, buff in world:query(Companion, Owner, BuffProvider) do
		local player = game.Players:GetPlayerByUserId(owner.playerId)
		if not player then
			continue
		end

		local profile = DataManager.Profiles[player]
		if not profile then
			continue
		end

		-- In a real scenario, this system would inject the buff into a central "StatCalculator"
		-- before a cooking session finishes.

		-- Example:
		-- if buff.buffType == "GoldMultiplier" then
		--     StatCalculator:RegisterTemporaryBuff(player, buff.buffType, buff.value)
		-- end
	end
end

return CompanionBuffSystem
