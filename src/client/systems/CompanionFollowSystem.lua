local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Companion = require(game.ReplicatedStorage.Shared.Components.Companion)
local Owner = require(game.ReplicatedStorage.Shared.Components.Owner)

-- Infinity Nikki Lens: 
-- Purely Client-Side Follow Logic. This absolutely eliminates network lag for pets.
local function CompanionFollowSystem(world)
	for id, companion, owner in world:query(Companion, Owner) do
		local player = game.Players:GetPlayerByUserId(owner.playerId)
		if not player or not player.Character then continue end
		
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end
		
		-- In a real scenario, the Companion component would hold a reference to the loaded 3D Model.
		-- We would smoothly CFrame:Lerp() the model's position to a spot behind the rootPart here.
		
		-- Example Math:
		-- local targetPosition = rootPart.CFrame * CFrame.new(3, 2, 3)
		-- companion.model:PivotTo(companion.model:GetPivot():Lerp(targetPosition, 0.1))
	end
end

return CompanionFollowSystem
