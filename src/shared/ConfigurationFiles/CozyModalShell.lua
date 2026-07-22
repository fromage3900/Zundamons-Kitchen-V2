--!strict
-- [[ModuleScript] CozyModalShell]]
-- Consistent wrapper for all HUD panels: close on Escape, spawn sparkles on open,
-- respects UIConfig tokens and reduced-motion preferences.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)

local CozyModalShell = {}

-- ── Helpers ──────────────────────────────────────────────────
local function applyCozyTokens(panel)
	if not panel then return end

	local corner = panel:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.CornerRadius = UIConfig.CORNER_RADIUS.Large
		corner.Parent = panel
	end

	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = UIConfig.STROKE.Normal
		stroke.Color = UIConfig.COLORS.PanelBorder
		stroke.Transparency = 0.2
		stroke.Parent = panel
	end
end

local function spawnOpenSparkles(panel)
	if not panel or not panel:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
		return
	end
	local center = panel.AbsolutePosition + panel.AbsoluteSize * 0.5
	local UIHelper = require(ReplicatedStorage.Shared.Modules.UIHelper)
	UIHelper.spawnSparkles(panel, center.X, center.Y, UIConfig.COLORS.SparkleGold, 12)
end

-- ── Public API ───────────────────────────────────────────────
function CozyModalShell.wrap(panel, options)
	options = options or {}
	applyCozyTokens(panel)

	-- Store original size for animation
	local originalSize = panel.Size
	local originalPosition = panel.Position

	local function openShell()
		-- Play panel open sound
		local zsc = _G.ZundaSoundController
		if zsc and zsc.play then
			zsc.play("PanelOpen")
		end

		-- Animate: scale pop from 0 to full size with bouncy Back easing
		panel.Visible = true
		if not UserInputService.ReducedMotionEnabled then
			panel.Size = UDim2.new(originalSize.X.Scale * 0.3, 0, originalSize.Y.Scale * 0.3, 0)
			panel.Position = UDim2.new(originalPosition.X.Scale, 0, originalPosition.Y.Scale, 0)
			TweenService:Create(panel, TweenInfo.new(UIConfig.ANIMATION.Normal, UIConfig.EASING.Bounce, Enum.EasingDirection.Out), {
				Size = originalSize,
			}):Play()
			TweenService:Create(panel, TweenInfo.new(UIConfig.ANIMATION.Fast, UIConfig.EASING.Smooth), {
				BackgroundTransparency = UIConfig.TRANSPARENCY.Panel,
			}):Play()
		else
			panel.Size = originalSize
			panel.Position = originalPosition
			panel.BackgroundTransparency = UIConfig.TRANSPARENCY.Panel
		end

		if options.open then
			options.open()
		end
		spawnOpenSparkles(panel)
	end

	local function closeShell()
		-- Play panel close sound
		local zsc = _G.ZundaSoundController
		if zsc and zsc.play then
			zsc.play("PanelClose")
		end

		-- Animate: scale shrink to 0 with smooth Quad easing
		if not UserInputService.ReducedMotionEnabled then
			TweenService:Create(panel, TweenInfo.new(UIConfig.ANIMATION.Fast, UIConfig.EASING.Smooth, Enum.EasingDirection.In), {
				Size = UDim2.new(originalSize.X.Scale * 0.3, 0, originalSize.Y.Scale * 0.3, 0),
			}):Play()
			TweenService:Create(panel, TweenInfo.new(UIConfig.ANIMATION.Fast, UIConfig.EASING.Smooth), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(UIConfig.ANIMATION.Fast + 0.05, function()
				panel.Visible = false
				panel.Size = originalSize
				panel.Position = originalPosition
				panel.BackgroundTransparency = UIConfig.TRANSPARENCY.Panel
			end)
		else
			panel.Visible = false
		end

		if options.close then
			options.close()
		end
	end

	-- Universal button hover effect: scale up + glow + sound
	local function setupButtonHover(btn)
		if btn:GetAttribute("HoverWired") then return end
		btn:SetAttribute("HoverWired", true)
		local origSize = btn.Size
		btn.MouseEnter:Connect(function()
			if not UserInputService.ReducedMotionEnabled then
				TweenService:Create(btn, TweenInfo.new(UIConfig.ANIMATION.Fast, UIConfig.EASING.Smooth), {
					Size = UDim2.new(origSize.X.Scale * 1.05, 0, origSize.Y.Scale * 1.05, 0),
				}):Play()
			end
			local zsc = _G.ZundaSoundController
			if zsc and zsc.play then
				zsc.play("ButtonHover")
			end
		end)
		btn.MouseLeave:Connect(function()
			if not UserInputService.ReducedMotionEnabled then
				TweenService:Create(btn, TweenInfo.new(UIConfig.ANIMATION.Fast, UIConfig.EASING.Smooth), {
					Size = origSize,
				}):Play()
			end
		end)
	end

	-- Wire hover effects to all buttons in panel
	for _, child in ipairs(panel:GetDescendants()) do
		if child:IsA("TextButton") or child:IsA("ImageButton") then
			setupButtonHover(child)
		end
	end
	panel.DescendantAdded:Connect(function(desc)
		if desc:IsA("TextButton") or desc:IsA("ImageButton") then
			setupButtonHover(desc)
		end
	end)

	-- Escape key closes the topmost modal if this panel is the current one
	-- Uses options.actionId (the UIRouter action ID) for comparison, not panel.Name
	if _G.ZundaUIRouter and options.actionId then
		local escConn
		escConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.Escape then
				if _G.ZundaUIRouter.getCurrent() == options.actionId then
					closeShell()
				end
			end
		end)

		return {
			open = openShell,
			close = closeShell,
			destroy = function()
				escConn:Disconnect()
			end,
		}
	end

	return {
		open = openShell,
		close = closeShell,
	}
end

function CozyModalShell.applyReducedMotion(panel)
	if not panel then return false end
	return UserInputService.ReducedMotionEnabled
end

return CozyModalShell
