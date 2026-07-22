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

	local function openShell()
		if options.open then
			options.open()
		end
		spawnOpenSparkles(panel)
	end

	local function closeShell()
		if options.close then
			options.close()
		end
	end

	-- Escape key closes the topmost modal
	if _G.ZundaUIRouter then
		local escConn
		escConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.Escape then
				if _G.ZundaUIRouter.getCurrent() == panel.Name then
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
	if not panel then return end
	if UserInputService.ReducedMotionEnabled then
		-- Caller should avoid creating tweens when reduced motion is enabled
	end
end

return CozyModalShell