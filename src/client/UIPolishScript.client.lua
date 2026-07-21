-- [[LocalScript] UIPolishScript (ref: RBX71127CE9B5AC441A8095CFC1E2FE5375)]]
-- UIPolish: Sparkle click effects + restaurant font system
local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local RunSvc    = game:GetService("RunService")
local Tween     = game:GetService("TweenService")
local player    = Players.LocalPlayer
local gui       = script.Parent

-- ── FONT CONSTANTS ──────────────────────────────────────────────────────────
-- Applied to every panel on first load via applyFonts()
local F = {
    heading = Enum.Font.FredokaOne,   -- round, friendly restaurant logo
    subhead = Enum.Font.GothamBlack,  -- bold, weighty menu-section headers
    body    = Enum.Font.Gotham,       -- clean body text
}
-- Merriweather as premium subhead via new font API (graceful fallback)
local function setSubheadFont(obj, size)
    local ok = pcall(function()
        obj.FontFace = Font.new(
            "rbxasset://fonts/families/Merriweather.json",
            Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    end)
    if not ok then obj.Font = F.subhead end
    if size then obj.TextSize = size end
end

-- Label classifiers by name patterns
local function classifyLabel(obj)
    local n = obj.Name:lower()
    if n:find("title") or n:find("heading") or n:find("name")
        or obj.TextSize >= 24 then return "heading"
    elseif n:find("sub") or n:find("section") or n:find("cat")
        or (obj.TextSize >= 16 and obj.TextSize < 24) then return "subhead"
    else return "body" end
end

local function applyFontsToGui(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
            -- Respect objects that explicitly use Code (they're data labels)
            if obj.Font ~= Enum.Font.Code then
                local cls = classifyLabel(obj)
                if cls == "heading" then
                    obj.Font = F.heading
                elseif cls == "subhead" then
                    setSubheadFont(obj)
                else
                    obj.Font = F.body
                end
            end
        end
    end
end

-- Apply fonts to every ScreenGui in PlayerGui
local function applyAllFonts()
    local pg = player:WaitForChild("PlayerGui")
    for _, sg in ipairs(pg:GetChildren()) do
        if sg:IsA("ScreenGui") and sg.Name ~= "UIPolish" then
            pcall(applyFontsToGui, sg)
        end
    end
end

task.delay(2, applyAllFonts)  -- wait for other GUIs to load first

-- ── SPARKLE PARTICLES ───────────────────────────────────────────────────────
-- Pool of sparkle frames reused for performance
local SPARKLE_POOL = {}
local POOL_SIZE    = 24
local SPARKLE_COLORS = {
    Color3.fromRGB(255, 200, 80),   -- gold
    Color3.fromRGB(255, 180, 220),  -- pink
    Color3.fromRGB(180, 220, 255),  -- sky blue
    Color3.fromRGB(180, 255, 200),  -- mint
    Color3.fromRGB(255, 240, 140),  -- yellow
    Color3.fromRGB(220, 170, 255),  -- lavender
}

local sparkleContainer = Instance.new("Frame", gui)
sparkleContainer.Name               = "SparkleContainer"
sparkleContainer.Size               = UDim2.new(1,0,1,0)
sparkleContainer.BackgroundTransparency = 1
sparkleContainer.BorderSizePixel    = 0
sparkleContainer.ZIndex             = 999

local function getSparkle()
    for _, s in ipairs(SPARKLE_POOL) do
        if not s:GetAttribute("InUse") then
            s:SetAttribute("InUse", true)
            return s
        end
    end
    -- Create new if pool exhausted
    local s = Instance.new("Frame", sparkleContainer)
    s.Size              = UDim2.new(0,0,0,0)
    s.AnchorPoint       = Vector2.new(0.5, 0.5)
    s.BackgroundColor3  = Color3.new(1,1,1)
    s.BorderSizePixel   = 0
    s.ZIndex            = 999
    Instance.new("UICorner", s).CornerRadius = UDim.new(0.5,0)
    s:SetAttribute("InUse", true)
    table.insert(SPARKLE_POOL, s)
    return s
end

local STAR_SHAPES = {"★","✦","✧","·","✶","✸"}

local function spawnSparkles(screenX, screenY)
    local count = math.random(6, 10)
    for i = 1, count do
        local spark = getSparkle()
        local color = SPARKLE_COLORS[math.random(#SPARKLE_COLORS)]
        local angle = (i / count) * math.pi * 2 + math.random() * 0.8
        local dist  = math.random(25, 70)
        local size  = math.random(6, 14)
        local dur   = 0.35 + math.random() * 0.25

        spark.Position          = UDim2.new(0, screenX, 0, screenY)
        spark.Size              = UDim2.new(0, size, 0, size)
        spark.BackgroundColor3  = color
        spark.Transparency      = 0
        spark.BackgroundTransparency = 0

        -- Animate outward + fade
        local targetX = screenX + math.cos(angle) * dist
        local targetY = screenY + math.sin(angle) * dist
        local tw = Tween:Create(spark, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position             = UDim2.new(0, targetX, 0, targetY),
            BackgroundTransparency = 1,
            Size                 = UDim2.new(0, 2, 0, 2),
        })
        tw:Play()
        task.delay(dur, function()
            spark:SetAttribute("InUse", false)
        end)
    end

    -- Also spawn a TextLabel star burst
    for i = 1, 3 do
        local lbl = Instance.new("TextLabel", sparkleContainer)
        lbl.Position         = UDim2.new(0, screenX + math.random(-20,20), 0, screenY + math.random(-20,20))
        lbl.Size             = UDim2.new(0, 22, 0, 22)
        lbl.AnchorPoint      = Vector2.new(0.5,0.5)
        lbl.BackgroundTransparency = 1
        lbl.Text             = STAR_SHAPES[math.random(#STAR_SHAPES)]
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextSize         = math.random(14, 22)
        lbl.TextColor3       = SPARKLE_COLORS[math.random(#SPARKLE_COLORS)]
        lbl.ZIndex           = 999
        Tween:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position     = UDim2.new(0, screenX+math.random(-40,40), 0, screenY-math.random(30,60)),
            TextTransparency = 1,
        }):Play()
        task.delay(0.55, function() lbl:Destroy() end)
    end
end

-- Hook all TextButton clicks across all GUIs
local function hookButton(btn)
    if btn:GetAttribute("SparkleHooked") then return end
    btn:SetAttribute("SparkleHooked", true)
    btn.MouseButton1Click:Connect(function()
        -- Get button's absolute screen position center
        local abs = btn.AbsolutePosition
        local siz = btn.AbsoluteSize
        spawnSparkles(abs.X + siz.X/2, abs.Y + siz.Y/2)
    end)
end

local function hookGui(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            hookButton(obj)
        end
    end
    root.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            task.wait() hookButton(obj)
        end
    end)
end

-- Hook all current + future PlayerGui ScreenGuis
local function hookAll()
    local pg = player:WaitForChild("PlayerGui")
    for _, sg in ipairs(pg:GetChildren()) do
        if sg:IsA("ScreenGui") then hookGui(sg) end
    end
    pg.ChildAdded:Connect(function(sg)
        if sg:IsA("ScreenGui") then
            task.wait(0.1) hookGui(sg)
        end
    end)
end

task.delay(1, hookAll)

print("[UIPolish] Sparkles + font system active")
