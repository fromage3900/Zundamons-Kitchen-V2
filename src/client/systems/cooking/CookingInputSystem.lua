local UserInputService = game:GetService("UserInputService")
local Matter = require(game.ReplicatedStorage.Packages.Matter)
local CookingSession = require(game.ReplicatedStorage.components.cooking.CookingSession)
local CookingScore = require(game.ReplicatedStorage.components.cooking.CookingScore)

-- Infinity Nikki Lens: Client system ONLY handles input prediction. It does not validate rewards.
local function CookingInputSystem(world)
	for id, session in world:query(CookingSession) do
		-- Only process inputs if this session belongs to the LocalPlayer
		if session.playerId ~= game.Players.LocalPlayer.UserId then
			continue
		end

		local score = world:get(id, CookingScore)
		if not score then
			continue
		end

		-- Listen for rhythm game inputs (e.g. Spacebar)
		for _, input in Matter.useEvent(UserInputService, "InputBegan") do
			if input.KeyCode == Enum.KeyCode.Space then
				-- In a real rhythm game, we would calculate the exact millisecond offset
				-- against the upcoming "Pea" note. For this PoC, we mock a random hit/miss.

				local isHit = math.random() > 0.3 -- 70% chance to hit for PoC

				local newScore = {
					perfectHits = score.perfectHits + (isHit and 1 or 0),
					misses = score.misses + (isHit and 0 or 1),
					totalNotes = score.totalNotes + 1,
				}

				-- Update the component locally. The React UI will automatically
				-- re-render when it sees this component change!
				world:insert(id, CookingScore(newScore))

				print(isHit and "PERFECT!" or "MISS!")
			end
		end
	end
end

return CookingInputSystem
