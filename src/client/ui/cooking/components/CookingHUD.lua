local React = require(game.ReplicatedStorage.Packages.React)

-- Infinity Nikki Lens: UI must be glassmorphic, elegant, and highly responsive.
local function CookingHUD(props)
	local timeRemaining = props.duration - props.timeElapsed
	local progress = math.clamp(props.timeElapsed / props.duration, 0, 1)

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		MainPanel = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.8), -- Positioned near the bottom for rhythm tracks
			Size = UDim2.fromOffset(600, 150),
			BackgroundColor3 = Color3.fromRGB(20, 20, 25),
			BackgroundTransparency = 0.4, -- Glassmorphism
			Visible = props.visible == true, -- AGENTS.md Rule 2d compliance
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 16)
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 215, 0), -- Gold accent (Infinity Nikki vibe)
				Thickness = 2,
				Transparency = 0.5,
			}),
			Title = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				Text = "Cooking: " .. (props.recipeName or "Unknown Recipe"),
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamMedium,
				TextSize = 24,
			}),
			ProgressBarBG = React.createElement("Frame", {
				Position = UDim2.new(0.1, 0, 0.6, 0),
				Size = UDim2.new(0.8, 0, 0, 20),
				BackgroundColor3 = Color3.fromRGB(10, 10, 10),
				BackgroundTransparency = 0.5,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Fill = React.createElement("Frame", {
					Size = UDim2.fromScale(progress, 1),
					BackgroundColor3 = Color3.fromRGB(255, 215, 0),
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})
			})
		})
	})
end

return CookingHUD
