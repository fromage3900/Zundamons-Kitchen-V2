local Matter = require(game.ReplicatedStorage.Packages.Matter)
local DataManager = require(game.ServerScriptService.Server.Services.DataManager)

-- We will create a pure data component to represent an item drop in the physical world
local ItemDrop = Matter.component("ItemDrop")

-- Infinity Nikki Lens: Gathering items safely via ECS
local function ItemGatherSystem(world)
	-- In a real game, this system would listen for a ProximityPrompt triggered on an ItemDrop entity
	for id, drop in world:query(ItemDrop) do
		-- FAKE TRIGGER: Auto-collect items for the Proof of Concept
		local player = game.Players:GetPlayerByUserId(drop.targetPlayerId)
		if player then
			local profile = DataManager.Profiles[player]
			if profile then
				-- We directly mutate the Data Layer.
				-- Because we wired ReplicaService in Phase 5, this ONE mutation
				-- will automatically trigger the `useInventory` React hook and re-render the player's screen!
				local currentQty = profile.Data.Inventory[drop.itemName] or 0
				profile.Data.Inventory[drop.itemName] = currentQty + drop.quantity
				
				print(string.format("[ItemGatherSystem] Granted %d %s to %s", drop.quantity, drop.itemName, player.Name))
				
				-- Destory the physical item
				world:despawn(id)
			end
		end
	end
end

return ItemGatherSystem
