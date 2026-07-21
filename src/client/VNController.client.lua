-- [[LocalScript] VNController (ref: RBX965534933CC64EAD957097D7586E4B35)]]
-- ══════════════════════════════════════════════════════════════
-- ZundaVN Unified Controller — drives ALL visual-novel dialogue
-- Speakers: companion, quest system, zone entry, NPC, welcome
-- API exposed via _G.ZundaVN = { show, hide, isOpen }
-- ══════════════════════════════════════════════════════════════
local Players  = game:GetService("Players")
local TweenS   = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local VNDialogueData = require(RS.ConfigurationFiles:WaitForChild("VNDialogueData"))
local SPEAKERS = VNDialogueData.SPEAKERS
local COMPANION_DIALOGUE = VNDialogueData.COMPANION_DIALOGUE
local SIDE_DIALOGUES = VNDialogueData.SIDE_DIALOGUES

local function RGB(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local playerGui = player:WaitForChild("PlayerGui")
local gui = ClientGuiBootstrap.createScreenGui(player, "ZundaVNGui", 40)

local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)

-- Expose side dialogues for other scripts to trigger
_G.ZundaSideDialogues = SIDE_DIALOGUES

-- ── Build UI (Animal Crossing inspired) ─────────────────────────
local PANEL_W = 780
local PANEL_H = 185
local PORT_W  = 110

local C_cream = UIConfig.COLORS.PanelBg
local C_border = UIConfig.COLORS.PanelBorder
local C_text = UIConfig.COLORS.TextDark
local C_textLight = UIConfig.COLORS.TextDarkSec
local C_close = UIConfig.COLORS.Danger

-- Very subtle dimmer
local dimmer = Instance.new("Frame", gui)
dimmer.Name = "Dimmer"
dimmer.Size = UDim2.new(1, 0, 1, 0)
dimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dimmer.BackgroundTransparency = 1
dimmer.BorderSizePixel = 0
dimmer.ZIndex = 9
dimmer.Visible = false

-- Main panel
local panel = Instance.new("Frame", gui)
panel.Name = "VNPanel"
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, 20)
panel.BackgroundColor3 = C_cream
panel.BorderSizePixel = 0
panel.ZIndex = 10
panel.Active = true
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 24)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = C_border; pStroke.Thickness = 3

-- Portrait box
local portrait = Instance.new("Frame", panel)
portrait.Name = "Portrait"
portrait.Size = UDim2.new(0, PORT_W, 1, 0)
portrait.BackgroundColor3 = UIConfig.GAME_COLORS.CookingTrack
portrait.BorderSizePixel = 0
portrait.ZIndex = 11
Instance.new("UICorner", portrait).CornerRadius = UDim.new(0, 18)

-- Portrait emoji
local pEmoji = Instance.new("TextLabel", portrait)
pEmoji.Name = "Emoji"
pEmoji.Size = UDim2.new(0.9, 0, 0.7, 0)
pEmoji.AnchorPoint = Vector2.new(0.5, 0.5)
pEmoji.Position = UDim2.new(0.5, 0, 0.5, 0)
pEmoji.BackgroundTransparency = 1
pEmoji.Text = "🍙"
pEmoji.Font = Enum.Font.GothamBold
pEmoji.TextSize = 52
pEmoji.ZIndex = 13

-- Text area
local textArea = Instance.new("Frame", panel)
textArea.Name = "TextArea"
textArea.Size = UDim2.new(1, -(PORT_W + 16), 1, -16)
textArea.Position = UDim2.new(0, PORT_W + 12, 0, 8)
textArea.BackgroundTransparency = 1
textArea.ZIndex = 11

-- Speaker name banner (tab style)
local nameBanner = Instance.new("Frame", textArea)
nameBanner.Name = "NameBanner"
nameBanner.Size = UDim2.new(0, 160, 0, 26)
nameBanner.Position = UDim2.new(0, 0, 0, 0)
nameBanner.BackgroundColor3 = Color3.fromRGB(160, 210, 150)
nameBanner.BorderSizePixel = 0
nameBanner.ZIndex = 12
Instance.new("UICorner", nameBanner).CornerRadius = UDim.new(0, 8)
local nameLabel = Instance.new("TextLabel", nameBanner)
nameLabel.Size = UDim2.new(1, -12, 1, 0)
nameLabel.Position = UDim2.new(0, 6, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Zundamon"
nameLabel.Font = Enum.Font.FredokaOne
nameLabel.TextSize = 15
nameLabel.TextColor3 = Color3.fromRGB(60, 40, 20)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.ZIndex = 13

-- Main dialogue text
local dlgText = Instance.new("TextLabel", textArea)
dlgText.Name = "DialogueText"
dlgText.Size = UDim2.new(1, -8, 0, 100)
dlgText.Position = UDim2.new(0, 4, 0, 30)
dlgText.BackgroundTransparency = 1
dlgText.Text = ""
dlgText.Font = Enum.Font.GothamMedium
dlgText.TextSize = 16
dlgText.TextColor3 = C_text
dlgText.TextXAlignment = Enum.TextXAlignment.Left
dlgText.TextYAlignment = Enum.TextYAlignment.Top
dlgText.TextWrapped = true
dlgText.ZIndex = 12
dlgText.LineHeight = 1.15

-- Advance indicator
local advArrow = Instance.new("TextLabel", textArea)
advArrow.Name = "AdvArrow"
advArrow.Size = UDim2.new(0, 20, 0, 18)
advArrow.AnchorPoint = Vector2.new(1, 1)
advArrow.Position = UDim2.new(1, -2, 1, -2)
advArrow.BackgroundTransparency = 1
advArrow.Text = "▼"
advArrow.Font = Enum.Font.GothamBold
advArrow.TextSize = 12
advArrow.TextColor3 = C_textLight
advArrow.ZIndex = 12
advArrow.Visible = false

-- Close button
local closeBtn = Instance.new("TextButton", panel)
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -4, 0, -4)
closeBtn.BackgroundColor3 = C_close
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = UIConfig.GAME_COLORS.HUDText
closeBtn.ZIndex = 100
closeBtn.Active = true
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5, 0)

-- Invisible advance button
local advBtn = Instance.new("TextButton", panel)
advBtn.Name = "AdvBtn"
advBtn.Size = UDim2.new(1, -(PORT_W + 50), 1, -42)
advBtn.Position = UDim2.new(0, PORT_W + 4, 0, 36)
advBtn.BackgroundTransparency = 1
advBtn.Text = ""; advBtn.BorderSizePixel = 0
advBtn.ZIndex = 12

-- ── State ─────────────────────────────────────────────────────
local isOpen     = false
local typing     = false
local typeThread = nil
local seqQueue   = {}   -- pending sequences to play after current
local seqLines   = {}
local seqIdx     = 0
local completeCb = nil

local SHOW_POS = UDim2.new(0.5, 0, 1, -(PANEL_H + 18))
local HIDE_POS = UDim2.new(0.5, 0, 1,  PANEL_H + 80)  -- push well below screen

-- ── BRANCHING CHOICE UI (built once, reused per choice prompt) ───────────
local choiceFrame = Instance.new("Frame", panel)
choiceFrame.Name = "Choices"
choiceFrame.Size = UDim2.new(1, -(PORT_W + 50), 0, 0)
choiceFrame.Position = UDim2.new(0, PORT_W + 8, 1, -6)
choiceFrame.AnchorPoint = Vector2.new(0, 1)
choiceFrame.BackgroundTransparency = 1
choiceFrame.ZIndex = 15
choiceFrame.Visible = false
local choiceLayout = Instance.new("UIListLayout", choiceFrame)
choiceLayout.FillDirection = Enum.FillDirection.Vertical
choiceLayout.Padding = UDim.new(0, 6)
choiceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

-- Free chat bar (LLM mode)
local chatBar = Instance.new("Frame", panel)
chatBar.Name = "ChatBar"
chatBar.Size = UDim2.new(1, -(PORT_W + 50), 0, 36)
chatBar.Position = UDim2.new(0, PORT_W + 8, 1, -8)
chatBar.AnchorPoint = Vector2.new(0, 1)
chatBar.BackgroundTransparency = 1
chatBar.Visible = false
chatBar.ZIndex = 17

local chatInput = Instance.new("TextBox", chatBar)
chatInput.Name = "ChatInput"
chatInput.Size = UDim2.new(1, -118, 1, 0)
chatInput.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
chatInput.TextColor3 = C_text
chatInput.PlaceholderText = "Ask Zundapal anything…"
chatInput.PlaceholderColor3 = C_textLight
chatInput.Font = Enum.Font.Gotham
chatInput.TextSize = 14
chatInput.ClearTextOnFocus = false
chatInput.BorderSizePixel = 0
Instance.new("UICorner", chatInput).CornerRadius = UDim.new(0, 8)
local chatInputStroke = Instance.new("UIStroke", chatInput)
chatInputStroke.Color = C_border
chatInputStroke.Thickness = 1.5

local chatSend = Instance.new("TextButton", chatBar)
chatSend.Name = "Send"
chatSend.Size = UDim2.new(0, 52, 1, 0)
chatSend.Position = UDim2.new(1, -52, 0, 0)
chatSend.BackgroundColor3 = UIConfig.COLORS.Success
chatSend.Text = "Send"
chatSend.Font = Enum.Font.GothamBold
chatSend.TextSize = 13
chatSend.TextColor3 = C_text
chatSend.BorderSizePixel = 0
Instance.new("UICorner", chatSend).CornerRadius = UDim.new(0, 8)

local chatExit = Instance.new("TextButton", chatBar)
chatExit.Name = "ExitChat"
chatExit.Size = UDim2.new(0, 58, 1, 0)
chatExit.Position = UDim2.new(1, -118, 0, 0)
chatExit.BackgroundColor3 = C_close
chatExit.Text = "Back"
chatExit.Font = Enum.Font.GothamBold
chatExit.TextSize = 12
chatExit.TextColor3 = UIConfig.GAME_COLORS.HUDText
chatExit.BorderSizePixel = 0
Instance.new("UICorner", chatExit).CornerRadius = UDim.new(0, 8)

local freeChatActive = false

local function setChatBarVisible(visible: boolean)
	chatBar.Visible = visible
	advBtn.Visible = not visible
	if not visible then
		advArrow.Visible = false
	end
end

local function submitFreeChat()
	if not freeChatActive then
		return
	end
	local text = chatInput.Text
	if text == "" then
		return
	end
	chatInput.Text = ""
	if _G.ZundaPalChat and _G.ZundaPalChat.submit then
		_G.ZundaPalChat.submit(text)
	end
end

chatSend.MouseButton1Click:Connect(submitFreeChat)
chatInput.FocusLost:Connect(function(enter)
	if enter and freeChatActive then
		submitFreeChat()
	end
end)
chatExit.MouseButton1Click:Connect(function()
	if _G.ZundaVN and _G.ZundaVN.exitFreeChat then
		_G.ZundaVN.exitFreeChat()
	end
end)

local function setSpeaker(key)
    local sp = SPEAKERS[key] or SPEAKERS.zundamon
    pEmoji.Text = sp.emoji
    portrait.BackgroundColor3 = sp.portrait
    nameBanner.BackgroundColor3 = sp.accent
    pStroke.Color = C_border
    if sp.name == "" then
        nameBanner.Visible = false
    else
        nameBanner.Visible = true
        nameLabel.Text = sp.name
    end
    dlgText.TextColor3 = C_text
end

local function openPanel()
    print("[VN.openPanel] Opening panel")
    isOpen = true
    panel.Visible = true
    dimmer.Visible = true
    print("[VN.openPanel] Panel visible:", panel.Visible)
    TweenS:Create(dimmer, TweenInfo.new(0.25), {BackgroundTransparency = 0.85}):Play()
    panel.Position = HIDE_POS
    TweenS:Create(panel, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = SHOW_POS}):Play()
    print("[VN.openPanel] Panel opened")
end

-- closePanel(force): when called from a user dismiss action (close X or Escape),
--   pass force=true to ALSO drop any queued sequences so the panel really stays
--   closed. Otherwise the next queued sequence will play after the close tween.
local function closePanel(force)
    if freeChatActive then
        setChatBarVisible(false)
        freeChatActive = false
        chatInput.Text = ""
    end
    isOpen = false
    typing = false
    if typeThread then
        pcall(task.cancel, typeThread)
        typeThread = nil
    end
    advArrow.Visible = false
    for _, c in ipairs(choiceFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    choiceFrame.Visible = false
    if force then
        seqQueue = {}
    end
    TweenS:Create(dimmer, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenS:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = HIDE_POS}):Play()
    task.delay(0.25, function()
        if isOpen then return end
        dimmer.Visible = false
        panel.Visible = false
        dlgText.Text = ""
        if completeCb then pcall(completeCb); completeCb = nil end
        if #seqQueue > 0 then
            local nxt = table.remove(seqQueue, 1)
            _G.ZundaVN.show(nxt.speaker, nxt.lines, nxt.onComplete)
        end
    end)
end

-- Typewriter effect
local function typeWrite(text)
    print("[VN.typeWrite] Starting with text:", text)
    text = text:gsub("{player}", Players.LocalPlayer and Players.LocalPlayer.Name or "Chef")
    typing = true
    advArrow.Visible = false
    dlgText.Text = ""
    for i = 1, #text do
        if not typing then break end
        dlgText.Text = text:sub(1, i)
        local ch = text:sub(i, i)
        local delay = ch == "," and 0.07 or (ch == "." or ch == "!" or ch == "?") and 0.1 or 0.028
        task.wait(delay)
    end
    dlgText.Text = text
    print("[VN.typeWrite] Complete, final text:", dlgText.Text)
    typing = false
    advArrow.Visible = true
    -- Blink arrow
    task.spawn(function()
        while advArrow.Visible do
            TweenS:Create(advArrow, TweenInfo.new(0.45), {TextTransparency = 0.85}):Play()
            task.wait(0.45)
            if not advArrow.Visible then break end
            TweenS:Create(advArrow, TweenInfo.new(0.45), {TextTransparency = 0}):Play()
            task.wait(0.45)
        end
    end)
end

local function skipTyping()
    if typing and seqLines[seqIdx] then
        typing = false
        if typeThread then task.cancel(typeThread); typeThread = nil end
        local entry = seqLines[seqIdx]
        dlgText.Text = type(entry) == "string" and entry or (entry.text or "")
        advArrow.Visible = true
    end
end

local function showLine(idx)
    print("[VN.showLine] Showing line", idx, "of", #seqLines)
    if idx > #seqLines then
        print("[VN.showLine] No more lines, closing panel")
        closePanel()
        return
    end
    local entry = seqLines[idx]
    local speakerKey, text
    if type(entry) == "string" then
        text = entry
        speakerKey = seqLines._defaultSpeaker or "zundamon"
    else
        speakerKey = entry.speaker or "zundamon"
        text = entry.text or ""
    end
    print("[VN.showLine] Speaker:", speakerKey, "Text:", text)
    setSpeaker(speakerKey)
    typeThread = task.spawn(function() typeWrite(text) end)
    print("[VN.showLine] TypeWrite spawned")
end

local function advanceLine()
    if typing then
        skipTyping()
    else
        seqIdx = seqIdx + 1
        showLine(seqIdx)
    end
end

-- ── Public API ────────────────────────────────────────────────
-- show(speakerOrKey, lines, onComplete?)
-- lines can be:
--   {"text", "text", ...}  (all use speakerOrKey)
--   {{speaker="key",text="..."}, ...}  (multi-speaker)
--
-- ── BRANCHING CHOICES helpers ───────────────────────────────────────
local clearChoices, showChoicesUI, playNode  -- forward decls

clearChoices = function()
    for _, c in ipairs(choiceFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    choiceFrame.Visible = false
    choiceFrame.Size = UDim2.new(1, -(PORT_W + 50), 0, 0)
end

showChoicesUI = function(choices, onPick)
    if type(choices) ~= "table" or #choices == 0 then return end
    clearChoices()
    advArrow.Visible = false
    local h = 0
    for i, c in ipairs(choices) do
        local btn = Instance.new("TextButton", choiceFrame)
        btn.Name = "Choice" .. i
        btn.Size = UDim2.new(1, -6, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(245, 235, 215)
        btn.BorderSizePixel = 0
        btn.Text = "  \u{276F} " .. (c.text or "...")
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextColor3 = C_text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 16
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local stk = Instance.new("UIStroke", btn)
        stk.Color = C_border; stk.Thickness = 1.5
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(235, 210, 180)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(245, 235, 215)
        end)
        btn.MouseButton1Click:Connect(function()
            clearChoices()
            if c.freeChat and _G.ZundaVN and _G.ZundaVN.enterFreeChat then
                _G.ZundaVN.enterFreeChat()
                return
            end
            if onPick then pcall(onPick, i, c) end
        end)
        h = h + 34
    end
    choiceFrame.Size = UDim2.new(1, -(PORT_W + 50), 0, h)
    choiceFrame.Visible = true
end

-- Walk a dialogue node:
--   node = { speaker="key", lines={...}, prompt="?", choices={{text,next},..} }
playNode = function(node)
    if type(node) == "function" then node = node() end
    if type(node) ~= "table" then return end
    local speakerKey = node.speaker or "zundapal"

    local function presentChoices()
        if not node.choices then return end
        if not isOpen then openPanel() end
        setSpeaker(speakerKey)
        if node.prompt then
            -- Type the prompt as a final line, then show choices
            seqLines = {{speaker=speakerKey, text=node.prompt}}
            seqIdx = 1
            showLine(1)
            task.spawn(function()
                while typing do task.wait(0.05) end
                showChoicesUI(node.choices, function(_, choice)
                    if choice.next then playNode(choice.next) end
                end)
            end)
        else
            showChoicesUI(node.choices, function(_, choice)
                if choice.next then playNode(choice.next) end
            end)
        end
    end

    if type(node.lines) == "table" and #node.lines > 0 then
        _G.ZundaVN.show(speakerKey, node.lines, function()
            presentChoices()
        end)
    else
        presentChoices()
    end
end

-- ── Public API ───────────────────────────────────────────────
_G.ZundaVN = {
    show = function(speakerKey, lines, onComplete)
        print("[VN.show] Called with speaker:", speakerKey, "lines count:", #lines)
        if type(lines) ~= "table" or #lines == 0 then 
            warn("[VN.show] Invalid lines parameter")
            return 
        end
        if isOpen then
            print("[VN.show] Panel already open, queuing")
            table.insert(seqQueue, {speaker=speakerKey, lines=lines, onComplete=onComplete})
            return
        end
        seqLines = lines
        seqLines._defaultSpeaker = speakerKey
        seqIdx = 1
        completeCb = onComplete
        print("[VN.show] Opening panel")
        openPanel()
        print("[VN.show] Setting speaker")
        setSpeaker(speakerKey)
        print("[VN.show] Showing line 1")
        showLine(1)
        print("[VN.show] Complete")
    end,
    showBranching = function(rootNode)
        playNode(rootNode)
    end,
    hide = function()
        if isOpen then closePanel(true) end
    end,
    isOpen = function() return isOpen end,
    enterFreeChat = function()
        freeChatActive = true
        openPanel()
        setSpeaker("zundapal")
        dlgText.Text = "Free chat mode~ Ask me about recipes, quests, or the village! 🍡"
        typing = false
        advArrow.Visible = false
        setChatBarVisible(true)
        task.defer(function()
            chatInput:CaptureFocus()
        end)
    end,
    exitFreeChat = function()
        freeChatActive = false
        setChatBarVisible(false)
        chatInput.Text = ""
        closePanel(true)
    end,
    isFreeChat = function()
        return freeChatActive
    end,
    showCompanionLine = function(text)
        if not isOpen then
            openPanel()
        end
        setSpeaker("zundapal")
        seqIdx = 1
        seqLines = { text }
        seqLines._defaultSpeaker = "zundapal"
        if typeThread then
            pcall(task.cancel, typeThread)
        end
        typeThread = task.spawn(function()
            typeWrite(text)
        end)
    end,
    setThinking = function(thinking)
        if thinking then
            typing = false
            dlgText.Text = "Zundapal is thinking… ✨"
            advArrow.Visible = false
        end
    end,
}

-- ── Input handlers ────────────────────────────────────────────
advBtn.MouseButton1Click:Connect(function()
    advanceLine()
    local pos = advBtn.AbsolutePosition
    local sz = advBtn.AbsoluteSize
    UIHelper.spawnSparkles(panel, pos.X + sz.X / 2, pos.Y + sz.Y / 2, Color3.fromRGB(180, 150, 110), 3)
end)
closeBtn.MouseButton1Click:Connect(function()
    if isOpen then closePanel(true) end
    local pos = closeBtn.AbsolutePosition
    UIHelper.spawnSparkles(panel, pos.X + 15, pos.Y + 15, Color3.fromRGB(200, 140, 120), 4)
end)
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if not isOpen then return end
    if inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.Return
       or inp.KeyCode == Enum.KeyCode.E then
        advanceLine()
    elseif inp.KeyCode == Enum.KeyCode.Escape then
        closePanel(true)
    end
end)

-- ── Event listeners ───────────────────────────────────────────
local RE = RS:WaitForChild("RemoteEvents")

-- ── BRANCHING ZUNDAPAL DIALOGUE TREE ─────────────────────────────
local function buildCompanionTree()
    local hour = tonumber(Lighting:GetAttribute("CurrentHour")) or 12
    local slot = hour>=5 and hour<12 and "morning"
              or hour>=12 and hour<18 and "afternoon"
              or hour>=18 and hour<21 and "evening"
              or "night"
    local greeting = COMPANION_DIALOGUE[slot]

    -- LEAVES
    local leafEnd = {
        speaker = "zundapal",
        lines = {
            {speaker="zundapal", text="Talk to me anytime, "..player.Name.."~ \u{1F49B}"},
        },
    }

    local cookingTipsNode = {
        speaker = "zundapal",
        lines = {
            {speaker="zundapal", text="Cooking tip time! \u{1F468}\u{200D}\u{1F373}"},
            {speaker="zundapal", text="Watch the timing bar carefully. When the indicator hits the bright-green middle…"},
            {speaker="zundapal", text="…that’s a PERFECT cook — you get bonus gold AND a chance at a free extra dish! ✨"},
        },
        prompt = "Want to hear more?",
        choices = {
            {text="What about Zunda Mochi?", next={
                speaker="zundapal",
                lines={
                    {speaker="zundapal", text="Zunda Mochi needs 5 Zunda Peas and 8 Wheat \u{1F361}"},
                    {speaker="zundapal", text="Pick the peas in the Kitchen Garden — they sparkle pink!"},
                },
            }},
            {text="And the legendary Zunda Paradise?", next={
                speaker="zundapal",
                lines={
                    {speaker="zundapal", text="Oooh you ambitious chef! \u{2728}"},
                    {speaker="zundapal", text="Zunda Paradise wants 15 Zunda Peas, 10 Edamame Pods, 5 Sweet Peas and 3 Pea Flowers."},
                    {speaker="zundapal", text="Only true masters can pull it off!"},
                },
            }},
            {text="Thanks, that's all.", next=leafEnd},
        },
    }

    local questHintsNode = {
        speaker = "zundapal",
        lines = {
            {speaker="zundapal", text="Let me check the quest board… \u{1F4DC}"},
        },
        prompt = "What are you curious about?",
        choices = {
            {text="Where do I find Zunda Peas?", next={
                speaker="zundapal",
                lines={
                    {speaker="zundapal", text="In the Kitchen Garden, behind the bakery!"},
                    {speaker="zundapal", text="They sparkle pink — you can’t miss them \u{1F495}"},
                },
            }},
            {text="How do I serve guests?", next={
                speaker="zundapal",
                lines={
                    {speaker="zundapal", text="Cook the dish they want, then walk over with it in your pouch."},
                    {speaker="zundapal", text="Click the guest — they’ll pay in gold and a smile~"},
                },
            }},
            {text="Tell me about the village.", next={
                speaker="elder",
                lines={
                    {speaker="elder", text="Ah, Zunda Village… founded long ago by chef-monks."},
                    {speaker="elder", text="Every dish here carries a little of their patience."},
                },
            }},
            {text="Never mind.", next=leafEnd},
        },
    }

    -- ROOT
    local greetingLines = {}
    if math.random() < 0.5 then
        table.insert(greetingLines, {speaker="narrator", text="[ Zundapal looks up with sparkling eyes. ]"})
    end
    for _, l in ipairs(greeting) do
        table.insert(greetingLines, {speaker="zundapal", text=l})
    end

    return {
        speaker = "zundapal",
        lines   = greetingLines,
        prompt  = "What would you like to talk about?",
        choices = {
            {text="Give me a cooking tip \u{1F373}",   next=cookingTipsNode},
            {text="I need quest help \u{1F4DC}",      next=questHintsNode},
            {text="Just saying hi \u{1F495}",          next={
                speaker="zundapal",
                lines={
                    {speaker="zundapal", text="Hehe — hi! \u{1F49A}"},
                    {speaker="zundapal", text="It’s really nice to see your face today, "..player.Name.."."},
                },
            }},
            {text="Just chat freely with me \u{1F4AC}", freeChat = true},
            {text="Bye for now",                       next=leafEnd},
        },
    }
end

-- Companion click → branching tree
RE:WaitForChild("OpenCompanionVN").OnClientEvent:Connect(function(compType, emoji)
    if isOpen then closePanel(true); return end
    _G.ZundaVN.showBranching(buildCompanionTree())
end)

-- Quest completed
local qcRE = RE:FindFirstChild("QuestCompleted")
if qcRE then
    qcRE.OnClientEvent:Connect(function(quest)
        local lines = {
            {speaker="zundamon", text="Quest complete! 🎉  \""..quest.title.."\""},
            {speaker="zundapal", text="You did it, "..player.Name.."! ✨ +"..(quest.reward or 0).." gold~"},
            {speaker="zundamon", text=quest.unlock_hint or "Keep exploring — new surprises await!"},
        }
        _G.ZundaVN.show("zundamon", lines)
    end)
end

-- Zone entry lore (BindableEvent fired by client zone ClickDetector handler)
local showZoneVNBindable = playerGui:FindFirstChild("ShowZoneVN")
if not showZoneVNBindable then
    showZoneVNBindable = Instance.new("BindableEvent")
    showZoneVNBindable.Name = "ShowZoneVN"
    showZoneVNBindable.Parent = player.PlayerGui
end
showZoneVNBindable.Event:Connect(function(zoneKey)
    local ok, loreCfg = pcall(function()
        return require(RS.ConfigurationFiles.ZoneLoreConfig)
    end)
    if not ok or not loreCfg then return end
    local lore = loreCfg[zoneKey]
    if not lore then return end
    local lines = {}
    for _, l in ipairs(lore.lines) do
        table.insert(lines, {speaker=lore.speaker, text=l})
    end
    _G.ZundaVN.show(lore.speaker, lines)
end)

-- Wait for _G.ZundaVN to be ready then fire welcome dialogue
task.delay(2.5, function()
    print("[VN] Starting welcome dialogue...")
    print("[VN] _G.ZundaVN exists:", _G.ZundaVN ~= nil)
    if _G.ZundaVN and _G.ZundaVN.show then
        print("[VN] Calling show with welcome text")
        _G.ZundaVN.show("zundamon", {
            "Welcome to Zunda Village, "..player.Name.."! 🌸",
            "I'm Zundamon — I'll guide you through your culinary adventure!",
            "Press M for the map  •  I for your pouch  •  J for quests~",
            "Your Zundapal companion is right beside you — click them to chat! 🍡",
        })
        print("[VN] Welcome dialogue triggered")
    else
        warn("[VN] _G.ZundaVN.show not available!")
    end
end)

print("[ZundaVN] Unified VN controller ready — all triggers wired")
