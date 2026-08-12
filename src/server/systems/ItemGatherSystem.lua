--!strict
-- [[DEPRECATED]] ItemGatherSystem
-- This proof-of-concept system was a "FAKE TRIGGER" that directly mutated
-- profile.Data.Inventory, bypassing PlayerDataService.mutate (no revision bump,
-- no projection emit). It was never registered in ServerMain and is dead code.
--
-- The real gather path is:
--   ZundaGatherServer (click-to-gather) -> LootModule.generateLoot (physical
--   claim tokens) -> LootModule.GiveLoot (RewardCore.settle -> PlayerDataService.mutate)
--
-- Kept as a stub so any stale require() doesn't error, but it does nothing.

local ItemGatherSystem = function(_world)
	-- Intentionally empty. See deprecation note above.
end

return ItemGatherSystem
