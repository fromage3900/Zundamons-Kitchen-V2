local CollectionService = game:GetService("CollectionService")
local Matter = require(game.ReplicatedStorage.Packages.Matter)

-- Infinity Nikki Lens: StreamingEnabled Architecture
-- When players walk across the massive map, the server streams instances in and out.
-- If an instance streams out, we must safely remove it from the ECS World to prevent memory leaks!
local function StreamingSystem(world)
	-- Listen for new Interactive objects streaming IN
	for _, instance in Matter.useEvent(CollectionService, "GetInstanceAddedSignal", "Interactive") do
		-- The server sent this model to the client's memory. Add it to ECS.
		-- world:spawn(...)
	end

	-- Listen for Interactive objects streaming OUT (player walked too far away)
	for _, instance in Matter.useEvent(CollectionService, "GetInstanceRemovedSignal", "Interactive") do
		-- The server removed this model from the client's memory to save RAM.
		-- We must find its corresponding Entity ID and remove it from the Matter World!
		
		-- for id in world:query(...) do
		-- 	world:despawn(id)
		-- end
	end
end

return StreamingSystem
