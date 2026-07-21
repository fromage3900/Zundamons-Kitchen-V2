local Matter = require(game.ReplicatedStorage.Packages.Matter)
local CookingSession = require(game.ReplicatedStorage.Shared.Components.Cooking.CookingSession)
local CookingScore = require(game.ReplicatedStorage.Shared.Components.Cooking.CookingScore)

-- Wait, the path to components depends on Rojo mapping. We will use absolute paths for the require later if needed, but for now we mock it.
local function CookingValidationSystem(world)
	-- Every frame, check all active cooking sessions
	for id, session in world:query(CookingSession) do
		local timeElapsed = os.clock() - session.startTime
		
		-- If the cooking session has exceeded the duration, end it!
		if timeElapsed >= session.duration then
			local score = world:get(id, CookingScore)
			
			-- Infinity Nikki Lens: Process rewards based on perfect hits vs misses securely on the server
			if score then
				local accuracy = score.perfectHits / score.totalNotes
				print(string.format("Player %d finished cooking with %.2f%% accuracy!", session.playerId, accuracy * 100))
				
				-- TODO: Award items via ProfileService here.
			end

			-- Remove the session component to end the minigame state
			world:remove(id, CookingSession)
		end
	end
end

return CookingValidationSystem
