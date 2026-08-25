-- [[LocalScript] PerfectCookCinematic]
-- Magical-girl transformation beat that plays when the player lands a perfect cook.
-- Non-blocking overlay: flash, magical circle, Zundamon emoji burst, and voice line.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local FONTS = UIConfig.FONTS

local gui = ClientGuiBootstrap.createScreenGui(player, "PerfectCookCinematicGui", 95)

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 1
overlay.Parent = gui

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundColor3 = Color3.fromRGB(160, 210, 150)
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 2
vignette.Parent = overlay

local circle = Instance.new("Frame")
circle.Name = "MagicCircle"
circle.Size = UDim2.new(0, 0, 0, 0)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.BackgroundTransparency = 1
circle.ZIndex = 3
circle.Parent = overlay

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.fromRGB(255, 200, 80)
circleStroke.Thickness = 6
circleStroke.Transparency = 1
circleStroke.Parent = circle

local zundamon = Instance.new("TextLabel")
zundamon.Name = "Zundamon"
zundamon.Size = UDim2.new(0, 120, 0, 120)
zundamon.AnchorPoint = Vector2.new(0.5, 0.5)
zundamon.Position = UDim2.new(0.5, 0, 0.5, 0)
zundamon.BackgroundTransparency = 1
zundamon.Text = "🌱"
zundamon.FontFace = FONTS.Title
zundamon.TextSize = 80
zundamon.TextTransparency = 1
zundamon.ZIndex = 4
zundamon.Parent = overlay

local caption = Instance.new("TextLabel")
caption.Name = "Caption"
caption.Size = UDim2.new(1, 0, 0, 40)
caption.Position = UDim2.new(0, 0, 0.65, 0)
caption.BackgroundTransparency = 1
caption.Text = ""
caption.FontFace = FONTS.Heading
caption.TextSize = 24
caption.TextColor3 = Color3.fromRGB(80, 55, 35)
caption.TextTransparency = 1
caption.ZIndex = 5
caption.Parent = overlay

local PEALINES = {
	"PERFECT COOK! JUST LIKE A MAGICAL GIRL TRANSFORMATION! ✨🍳",
	"TASTE THE SPARKLE! THIS DISH IS PURE ZUNDA MAGIC! 💫🌱",
	"PERFECT TIMING! THE PEAS THEMSELVES ARE CHEERING! 🫛🎉",
	"A MASTERPIECE! EVEN THE STARS ARE JEALOUS! ⭐🍡",
}

local function spawnEmojiBurst()
	local centerX = overlay.AbsoluteSize.X / 2
	local centerY = overlay.AbsoluteSize.Y / 2
	local emojis = { "✨", "🌱", "🍡", "⭐", "🫛", "💖" }
	for i = 1, 12 do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0, 32, 0, 32)
		lbl.Position = UDim2.new(0, centerX, 0, centerY)
		lbl.BackgroundTransparency = 1
		lbl.Text = emojis[math.random(1, #emojis)]
		lbl.FontFace = FONTS.Body
		lbl.TextSize = math.random(18, 28)
		lbl.TextTransparency = 0
		lbl.ZIndex = 6
		lbl.Parent = overlay
		local angle = (i / 12) * math.pi * 2 + math.random() * 0.5
		local dist = math.random(120, 220)
		local target = UDim2.new(0, centerX + math.cos(angle) * dist, 0, centerY + math.sin(angle) * dist)
		TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
			TextTransparency = 1,
		}):Play()
		task.delay(0.8, function()
			lbl:Destroy()
		end)
	end
end

local isPlaying = false

local function playCinematic(recipeName: string)
	if isPlaying then
		return
	end
	isPlaying = true
	overlay.Visible = true

	-- Sound + voice
	local zsc = _G.ZundaSoundController
	if zsc and zsc.play then
		zsc.play("perfect_cook")
	end

	-- Flash in
	TweenService:Create(overlay, TweenInfo.new(0.12), { BackgroundTransparency = 0.2 }):Play()
	TweenService:Create(vignette, TweenInfo.new(0.25), { BackgroundTransparency = 0.7 }):Play()

	-- Magical circle expand + spin
	circle.Size = UDim2.new(0, 0, 0, 0)
	circleStroke.Transparency = 0
	TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 280, 0, 280),
	}):Play()

	local rotation = 0
	local spinConn = RunService.Heartbeat:Connect(function(dt)
		rotation += dt * 90
		circle.Rotation = rotation
	end)

	-- Zundamon pop
	zundamon.TextTransparency = 0
	zundamon.Size = UDim2.new(0, 40, 0, 40)
	TweenService:Create(zundamon, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 120, 0, 120),
	}):Play()

	-- Caption
	caption.Text = PEALINES[math.random(1, #PEALINES)]
	TweenService:Create(caption, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	spawnEmojiBurst()

	task.delay(1.2, function()
		-- Fade out
		TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(vignette, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(circleStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		TweenService:Create(zundamon, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(caption, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	end)

	task.delay(1.7, function()
		spinConn:Disconnect()
		overlay.Visible = false
		circle.Size = UDim2.new(0, 0, 0, 0)
		isPlaying = false
	end)
end

local RE = RS:WaitForChild("RemoteEvents")
local cookResultEv = RE:FindFirstChild("CookingResult")
if cookResultEv then
	cookResultEv.OnClientEvent:Connect(function(data)
		local quality = data.quality or "ok"
		if quality == "perfect" then
			playCinematic(data.recipe or "")
		end
	end)
end

print("[PerfectCookCinematic] Ready")
