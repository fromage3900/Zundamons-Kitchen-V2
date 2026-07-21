local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local CookingHUD = require(script.Parent.Parent.components.CookingHUD)

return {
	story = function(target)
		local root = ReactRoblox.createRoot(target)
		
		-- Mock the state for UI Designers to visualize without starting the ECS loop!
		local mockProps = {
			recipeName = "Zunda Apple Pie",
			duration = 10,
			timeElapsed = 4.5,
		}

		root:render(React.createElement(CookingHUD, mockProps))

		return function()
			root:unmount()
		end
	end,
}
