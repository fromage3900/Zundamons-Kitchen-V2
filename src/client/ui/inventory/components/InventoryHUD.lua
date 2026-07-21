local React = require(game.ReplicatedStorage.Packages.React)
local useInventory = require(script.Parent.Parent.hooks.useInventory)

local function InventoryHUD()
	local inventory, gold = useInventory()
	local itemCards = {}

	-- Populate the unified grid
	local index = 1
	for itemName, quantity in pairs(inventory) do
		table.insert(itemCards, React.createElement("Frame", {
			Key = itemName,
			BackgroundColor3 = Color3.fromRGB(30, 30, 35),
			BackgroundTransparency = 0.5, -- Glassmorphism
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(200, 200, 200),
				Transparency = 0.8,
			}),
			NameLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0.7, 0),
				BackgroundTransparency = 1,
				Text = itemName,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				TextWrapped = true,
			}),
			QuantityLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, -10, 0.3, 0),
				Position = UDim2.new(0, 0, 0.7, 0),
				BackgroundTransparency = 1,
				Text = "x" .. tostring(quantity),
				TextColor3 = Color3.fromRGB(255, 215, 0),
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Right,
			})
		}))
		index += 1
	end

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		MainPanel = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(600, 400),
			BackgroundColor3 = Color3.fromRGB(15, 15, 20),
			BackgroundTransparency = 0.3, -- Heavy Glassmorphism
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 215, 0),
				Thickness = 2,
				Transparency = 0.5,
			}),
			-- Header
			Header = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundTransparency = 1,
			}, {
				Title = React.createElement("TextLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0, 20, 0, 0),
					BackgroundTransparency = 1,
					Text = "Bag",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 24,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				GoldDisplay = React.createElement("TextLabel", {
					Size = UDim2.new(0.5, -20, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = "🪙 " .. tostring(gold),
					TextColor3 = Color3.fromRGB(255, 215, 0),
					Font = Enum.Font.GothamBold,
					TextSize = 20,
					TextXAlignment = Enum.TextXAlignment.Right,
				})
			}),
			-- Grid Layout
			GridContainer = React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, -40, 1, -70),
				Position = UDim2.new(0, 20, 0, 60),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				CanvasSize = UDim2.new(0, 0, 0, math.max(400, math.ceil(index/4) * 110)),
			}, {
				UIGridLayout = React.createElement("UIGridLayout", {
					CellSize = UDim2.fromOffset(100, 100),
					CellPadding = UDim2.fromOffset(10, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				React.createElement(React.Fragment, nil, itemCards)
			})
		})
	})
end

return InventoryHUD
