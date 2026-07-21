local React = require(game.ReplicatedStorage.Packages.React)

-- Infinity Nikki Lens: Presentational component. It takes purely props and renders visual "Peas" scrolling.
local function PeaRhythmTrack(props)
	local peas = {}

	-- Render mock peas along the track based on time elapsed
	for i = 1, props.totalPeas do
		local offset = (i / props.totalPeas) * 100
		
		table.insert(peas, React.createElement("TextLabel", {
			Key = "Pea_" .. i,
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(1 - (props.timeElapsed / props.duration) + (offset / 100), 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "🫛",
			TextSize = 32,
			-- Fade out peas that have passed the "hit zone"
			TextTransparency = (1 - (props.timeElapsed / props.duration) + (offset / 100)) < 0.1 and 1 or 0,
		}))
	end

	return React.createElement("Frame", {
		Size = UDim2.new(1, -40, 0, 60),
		Position = UDim2.fromScale(0.5, 0.7),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
		HitZone = React.createElement("Frame", {
			Size = UDim2.fromOffset(50, 50),
			Position = UDim2.fromScale(0.1, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.8,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 215, 0),
				Thickness = 3,
			})
		}),
		PeasContainer = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, peas)
	})
end

return PeaRhythmTrack
