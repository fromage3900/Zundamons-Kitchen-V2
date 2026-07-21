local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = script.Parent

local STEPS = {
	{
		id = "welcome",
		title = "🌸  Welcome to Zunda's Kitchen!",
		desc = "You're the newest chef in Zunda Village! Gather ingredients, cook dishes, and serve guests to grow your reputation.",
		target = nil,
		waitFor = nil,
		auto = 6,
	},
	{
		id = "harvest",
		title = "🌿  Gather Ingredients",
		desc = "Walk up to glowing plants, rocks, and trees to harvest materials. Each node gives different resources!",
		target = nil,
		waitFor = nil,
		auto = 5,
	},
	{
		id = "craft",
		title = "🍳  Cook Dishes (K)",
		desc = "Press K to open the crafting panel. Combine ingredients to make dishes — the better your timing, the better the result!",
		target = nil,
		waitFor = nil,
		auto = 5,
	},
	{
		id = "quests",
		title = "📋  Complete Quests (J)",
		desc = "Press J to check your quests. Completing quests earns gold and unlocks new recipes and zones!",
		target = nil,
		waitFor = nil,
		auto = 5,
	},
	{
		id = "compendium",
		title = "📚  Compendium (C)",
		desc = "Press C to browse all recipes, items, and zones. Track your collection progress!",
		target = nil,
		waitFor = nil,
		auto = 4,
	},
	{
		id = "companion",
		title = "✨  Your Companion",
		desc = "A Zundapal follows you everywhere! Click on them to chat and build your bond. Premium companions give special buffs!",
		target = nil,
		waitFor = nil,
		auto = 5,
	},
	{
		id = "final",
		title = "🎉  You're Ready!",
		desc = "Cook delicious meals, serve happy guests, and discover all the secrets of Zunda Village. Good luck, Chef!",
		target = nil,
		waitFor = nil,
		auto = 5,
	},
}

local C = {
	overlay = Color3.fromRGB(0, 0, 0),
	card    = Color3.fromRGB(255, 248, 235),
	border  = Color3.fromRGB(180, 150, 110),
	title   = Color3.fromRGB(80, 55, 35),
	text    = Color3.fromRGB(100, 75, 55),
	button  = Color3.fromRGB(180, 150, 110),
}

local function checkTutorialDone()
    print("[Tutorial.checkTutorialDone] Checking...")
    local rf = RS:WaitForChild("RemoteFunctions"):FindFirstChild("MarkTutorialDone")
    print("[Tutorial.checkTutorialDone] MarkTutorialDone exists:", rf ~= nil)
    if not rf then return false end
    local ok, result = pcall(function()
        local req = RS:WaitForChild("RemoteFunctions"):FindFirstChild("RequestData")
        print("[Tutorial.checkTutorialDone] RequestData exists:", req ~= nil)
        if req then
            local data = req:InvokeServer()
            print("[Tutorial.checkTutorialDone] Data received:", data ~= nil)
            return data and data.tutorial_done
        end
        return false
    end)
    print("[Tutorial.checkTutorialDone] Result:", ok and result or false)
    return ok and result or false
end

local function markTutorialDone()
	local rf = RS:WaitForChild("RemoteFunctions"):FindFirstChild("MarkTutorialDone")
	if rf then
		pcall(function() rf:InvokeServer() end)
	end
end

-- Wait for character spawn before checking tutorial status
local function waitForSpawn()
	player.CharacterAdded:Wait()
	task.wait(1.5)
end

local overlay = Instance.new("Frame", gui)
overlay.Name = "TutorialOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = C.overlay
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.ZIndex = 999

local card = Instance.new("Frame", gui)
card.Name = "TutorialCard"
card.Size = UDim2.new(0, 440, 0, 200)
card.Position = UDim2.new(0.5, -220, 0.7, -100)
card.BackgroundColor3 = C.card; card.BorderSizePixel = 0
card.ZIndex = 1000; card.Visible = false
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 22)
local cStroke = Instance.new("UIStroke", card)
cStroke.Thickness = 3; cStroke.Color = C.border; cStroke.ZIndex = 1000

local titleLbl = Instance.new("TextLabel", card)
titleLbl.Name = "Title"
titleLbl.Size = UDim2.new(1, -40, 0, 48); titleLbl.Position = UDim2.new(0, 20, 0, 16)
titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.FredokaOne
titleLbl.TextSize = 22; titleLbl.TextColor3 = C.title
titleLbl.TextXAlignment = Enum.TextXAlignment.Center

local descLbl = Instance.new("TextLabel", card)
descLbl.Name = "Desc"
descLbl.Size = UDim2.new(1, -48, 0, 72); descLbl.Position = UDim2.new(0, 24, 0, 68)
descLbl.BackgroundTransparency = 1; descLbl.Font = Enum.Font.Gotham
descLbl.TextSize = 15; descLbl.TextColor3 = C.text; descLbl.TextWrapped = true
descLbl.TextXAlignment = Enum.TextXAlignment.Center; descLbl.TextYAlignment = Enum.TextYAlignment.Top

local navFrame = Instance.new("Frame", card)
navFrame.Name = "Nav"
navFrame.Size = UDim2.new(1, -32, 0, 44); navFrame.Position = UDim2.new(0, 16, 1, -52)
navFrame.BackgroundTransparency = 1; navFrame.BorderSizePixel = 0

local dots = {}
local function buildDots()
	for i = 1, #STEPS do
		local dot = Instance.new("Frame", navFrame)
		dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = UDim2.new(0.5, - (#STEPS * 14 / 2) + (i - 1) * 28, 0.5, -5)
		dot.BackgroundColor3 = i == 1 and C.button or Color3.fromRGB(210, 200, 185)
		dot.BorderSizePixel = 0
		Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)
		table.insert(dots, dot)
	end
end
buildDots()

local buttonFrame = Instance.new("Frame", card)
buttonFrame.Name = "Buttons"
buttonFrame.Size = UDim2.new(1, -32, 0, 36); buttonFrame.Position = UDim2.new(0, 16, 1, -100)
buttonFrame.BackgroundTransparency = 1; buttonFrame.BorderSizePixel = 0

local skipBtn = Instance.new("TextButton", buttonFrame)
skipBtn.Size = UDim2.new(0.48, -4, 1, 0); skipBtn.Position = UDim2.new(0, 0, 0, 0)
skipBtn.BackgroundColor3 = Color3.fromRGB(210, 200, 185); skipBtn.Text = "Skip ✕"
skipBtn.Font = Enum.Font.GothamBold; skipBtn.TextSize = 14
skipBtn.TextColor3 = Color3.fromRGB(100, 75, 55); skipBtn.BorderSizePixel = 0
Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 10)

local nextBtn = Instance.new("TextButton", buttonFrame)
nextBtn.Size = UDim2.new(0.48, -4, 1, 0); nextBtn.Position = UDim2.new(0.52, 4, 0, 0)
nextBtn.BackgroundColor3 = C.button; nextBtn.Text = "Next →"
nextBtn.Font = Enum.Font.FredokaOne; nextBtn.TextSize = 16
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255); nextBtn.BorderSizePixel = 0
Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 10)

local currentStep = 1
local animating = false

local function showStep(idx)
    print("[Tutorial.showStep] Showing step", idx)
    if idx < 1 or idx > #STEPS then 
        warn("[Tutorial.showStep] Invalid step index:", idx)
        return 
    end
    currentStep = idx
    local step = STEPS[idx]
    print("[Tutorial.showStep] Step title:", step.title)
    titleLbl.Text = step.title
    descLbl.Text = step.desc

    for i, dot in ipairs(dots) do
        dot.BackgroundColor3 = i == idx and C.button or Color3.fromRGB(210, 200, 185)
        dot:TweenSize(UDim2.new(i == idx and 14 or 10, 0, 10, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.2, true)
    end

    local isLast = idx == #STEPS
    nextBtn.Text = isLast and "Done! ✨" or "Next →"
    skipBtn.Visible = not isLast

    card.Visible = true
    print("[Tutorial.showStep] Card visible:", card.Visible)
    card.Size = UDim2.new(0, 440, 0, 10)
    Tween:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 440, 0, 220) }):Play()
    print("[Tutorial.showStep] Step shown")
end

local function dismiss()
	Tween:Create(card, TweenInfo.new(0.2), { Size = UDim2.new(0, 440, 0, 0) }):Play()
	task.delay(0.25, function()
		card.Visible = false
		overlay:Destroy()
		card:Destroy()
		markTutorialDone()
	end)
end

nextBtn.MouseButton1Click:Connect(function()
	if currentStep >= #STEPS then
		dismiss()
	else
		showStep(currentStep + 1)
	end
end)

skipBtn.MouseButton1Click:Connect(dismiss)

-- Automatically advance for timed steps
local autoTimer
local function resetAutoTimer(step)
	if autoTimer then autoTimer:Cancel() end
	if step.auto and step.auto > 0 then
		autoTimer = task.delay(step.auto, function()
			if currentStep >= #STEPS then
				dismiss()
			else
				showStep(currentStep + 1)
			end
		end)
	end
end

-- Override showStep to include auto timer
local origShowStep = showStep
showStep = function(idx)
	origShowStep(idx)
	resetAutoTimer(STEPS[idx])
end

-- Wait for character spawn + PlayerGui, then start
task.spawn(function()
    print("[Tutorial] Starting initialization...")
    player:WaitForChild("PlayerGui")
    print("[Tutorial] PlayerGui ready, waiting for spawn...")
    waitForSpawn()
    print("[Tutorial] Character spawned, checking if tutorial done...")
    local tutorialDone = checkTutorialDone()
    print("[Tutorial] Tutorial done:", tutorialDone)
    if tutorialDone then 
        print("[Tutorial] Tutorial already completed, skipping")
        return 
    end
    task.wait(1.5)
    print("[Tutorial] Showing step 1")
    showStep(1)
    print("[TutorialController] Onboarding sequence ready — 7 steps")
end)
