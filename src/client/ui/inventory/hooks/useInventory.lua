local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReplicaService = require(ReplicatedStorage.Packages.ReplicaService)

-- Infinity Nikki Lens: 
-- This hook automatically binds React state directly to the server's database via ReplicaService.
-- When a player picks up an item on the server, this hook updates the UI instantly.
local function useInventory()
	local inventory, setInventory = React.useState({})
	local gold, setGold = React.useState(0)

	React.useEffect(function()
		local connection
		
		-- Listen for when the server streams our Profile to us
		ReplicaService.ReplicaOfClassCreated("PlayerProfile", function(replica)
			if replica.Tags.Player == game.Players.LocalPlayer then
				-- Initial load
				setInventory(replica.Data.Inventory or {})
				setGold(replica.Data.Gold or 0)
				
				-- Listen for live updates from the server
				connection = replica:ListenToChange("Inventory", function(newInventory)
					setInventory(newInventory)
				end)
				
				replica:ListenToChange("Gold", function(newGold)
					setGold(newGold)
				end)
			end
		end)

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {})

	return inventory, gold
end

return useInventory
