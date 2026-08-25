-- [[LocalScript] ZundamonReactionBuddy]
-- A tiny floating Zundamon face that reacts to player accomplishments.
-- Non-blocking; uses a short cooldown so it never spams.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local FONTS = UIConfig.FONTS

local gui = ClientGuiBootstrap.createScreenGui(player, "ZundamonReactionBuddyGui", 35)

local buddy = Instance.new("Frame")
buddy.Name = "Buddy"
buddy.Size = UDim2.new(0, 64, 0, 64)
buddy.Position = UDim2.new(1, -80, 0, 16)
buddy.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
buddy.BorderSizePixel = 0
buddy.AnchorPoint = Vector2.new(0.5, 0.5)
buddy.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = buddy

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160, 210, 150)
stroke.Thickness = 3
stroke.Parent = buddy

local face = Instance.new("TextLabel")
face.Name = "Face"
face.Size = UDim2.new(1, 0, 1, 0)
face.BackgroundTransparency = 1
face.Text = "🌱"
face.FontFace = FONTS.Title
face.TextSize = 36
face.TextColor3 = Color3.fromRGB(80, 80, 80)
face.Parent = buddy

local caption = Instance.new("TextLabel")
caption.Name = "Caption"
caption.Size = UDim2.new(0, 260, 0, 32)
caption.Position = UDim2.new(1, -160, 0, 82)
caption.BackgroundTransparency = 1
caption.Text = ""
caption.FontFace = FONTS.Heading
caption.TextSize = 14
caption.TextColor3 = Color3.fromRGB(80, 55, 35)
caption.TextWrapped = true
caption.TextTransparency = 1
caption.Parent = gui

local REACTIONS = {
	perfect = {
		emoji = "😤",
		lines = {
			"PERFECT! THE PEAS ARE PROUD! 🫛✨",
			"MAGICAL COOKING AT ITS FINEST! 🍳💫",
			"YOU'RE SHINING LIKE A STAR CHEF! ⭐🌱",
		},
	},
	great = {
		emoji = "😊",
		lines = {
			"GREAT JOB! KEEP THOSE PEAS ROLLING! 🍡",
			"SO CLOSE TO PERFECT! NEXT TIME! 🌱",
			"TASTY WORK, CHEF! 🥘",
		},
	},
	ok = {
		emoji = "🙂",
		lines = {
			"NOT BAD! PRACTICE MAKES PERFECT PEAS! 🫛",
			"EVERY COOK IS A STEP FORWARD! 🍳",
			"YOU'LL GET IT NEXT TIME! 💪",
		},
	},
	quest = {
		emoji = "🎉",
		lines = {
			"QUEST COMPLETE! ADVENTURE AWAITS! 📜✨",
			"ANOTHER TRIUMPH FOR THE KITCHEN! 🏆",
			"ZUNDAMON IS SO PROUD! 🌱💖",
		},
	},
	achievement = {
		emoji = "🏆",
		lines = {
			"ACHIEVEMENT UNLOCKED! YOU'RE LEGENDARY! 🏆",
			"A NEW MEDAL FOR THE HALL OF FAME! ⭐",
			"WOW! EVEN THE STARS ARE APPLAUDING! ✨",
		},
	},
	milestone = {
		emoji = "🌟",
		lines = {
			"A NEW DISCOVERY! THE WORLD GROWS BIGGER! 🗺️",
			"YOU'RE COLLECTING EVERYTHING! AMAZING! 📚",
			"MASTERY ONE STEP CLOSER! 💫",
		},
	},
}

local lastReaction = 0
local COOLDOWN = 1.5

local function react(kind: string, context: string?)
	local now = os.clock()
	if now - lastReaction < COOLDOWN then
		return
	end
	lastReaction = now

	local reaction = REACTIONS[kind]
	if not reaction then
		return
	end

	face.Text = reaction.emoji
	caption.Text = reaction.lines[math.random(1, #reaction.lines)]

	-- Hop animation
	local basePos = UDim2.new(1, -80, 0, 16)
	TweenService:Create(buddy, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -80, 0, 6),
		Size = UDim2.new(0, 72, 0, 72),
	}):Play()
	task.delay(0.15, function()
		TweenService:Create(buddy, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = basePos,
			Size = UDim2.new(0, 64, 0, 64),
		}):Play()
	end)

	-- Caption pop
	caption.TextTransparency = 0
	TweenService:Create(caption, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	-- Voice
	local zsc = _G.ZundaSoundController
	if zsc and zsc.play then
		zsc.play("reaction_" .. kind)
	end

	task.delay(2.2, function()
		TweenService:Create(caption, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
	end)
end

-- Hook existing events
local RE = RS:WaitForChild("RemoteEvents")
local RewardEvents = RS:WaitForChild("RewardEvents")

local cookResultEv = RE:FindFirstChild("CookingResult")
if cookResultEv then
	cookResultEv.OnClientEvent:Connect(function(data)
		local quality = data.quality or "ok"
		react(quality, data.recipe)
	end)
end

local qcBatch = RE:FindFirstChild("QuestCompletedBatch")
if qcBatch then
	qcBatch.OnClientEvent:Connect(function()
		react("quest")
	end)
end

local achievementEv = RewardEvents:FindFirstChild("AchievementUnlocked")
if achievementEv then
	achievementEv.OnClientEvent:Connect(function()
		react("achievement")
	end)
end

local previousSnapshot = nil
local snapshotEv = RE:FindFirstChild("CollectionSnapshot")
if snapshotEv then
	snapshotEv.OnClientEvent:Connect(function(snapshot)
		local counts = snapshot and snapshot.counts
		if not counts then
			return
		end
		local isFirstMilestone = false
		if previousSnapshot then
			for key, value in pairs(counts) do
				if value > 0 and (previousSnapshot[key] or 0) == 0 then
					isFirstMilestone = true
					break
				end
			end
		end
		previousSnapshot = {}
		for key, value in pairs(counts) do
			previousSnapshot[key] = value
		end
		if isFirstMilestone then
			react("milestone")
		end
	end)
end

print("[ZundamonReactionBuddy] Ready")
