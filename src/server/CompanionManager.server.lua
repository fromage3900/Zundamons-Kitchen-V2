-- [[Script] CompanionManager (ref: RBXA3D4133A29B940DFBEF7B3E9A3CDF820)]]
-- CompanionManager v4: loads full companion models with textures, sparkle VFX, VN click interaction
local Players    = game:GetService("Players")
local Tween      = game:GetService("TweenService")
local RS         = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local CompanionVisualConfig = require(RS.ConfigurationFiles.CompanionVisualConfig)

-- Cache loaded companion models
local companionModelCache = {}

local function sanitizeModel(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("LuaSourceContainer") or descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("ClickDetector") or descendant:IsA("ProximityPrompt") then
            descendant:Destroy()
        end
    end
end

local function studioVisual(compType)
    local catalog = ServerStorage:FindFirstChild("CompanionVisualCatalog")
    local entries = catalog and catalog:FindFirstChild("Entries")
    local entry = entries and entries:FindFirstChild(compType)
    if not entry then return nil end
    return {
        modelAssetId = entry:GetAttribute("ModelAssetId"),
        basePrefab = entry:GetAttribute("BasePrefab"),
        colorMap = entry:GetAttribute("ColorMap"),
        normalMap = entry:GetAttribute("NormalMap"),
        roughnessMap = entry:GetAttribute("RoughnessMap"),
        metalnessMap = entry:GetAttribute("MetalnessMap"),
    }
end

local function applyAppearance(model, visual)
    if not visual then return end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("MeshPart") then
            local appearance = descendant:FindFirstChildOfClass("SurfaceAppearance")
            if not appearance and (visual.colorMap or visual.normalMap) then
                appearance = Instance.new("SurfaceAppearance")
                appearance.Parent = descendant
            end
            if appearance then
                if visual.colorMap and visual.colorMap ~= "" then appearance.ColorMap = visual.colorMap end
                if visual.normalMap and visual.normalMap ~= "" then appearance.NormalMap = visual.normalMap end
                if visual.roughnessMap and visual.roughnessMap ~= "" then appearance.RoughnessMap = visual.roughnessMap end
                if visual.metalnessMap and visual.metalnessMap ~= "" then appearance.MetalnessMap = visual.metalnessMap end
            end
        end
    end
end

local function loadCompanionModel(compType)
    if companionModelCache[compType] then
        print("[CompanionManager.loadCompanionModel] Using cached model for", compType)
        return companionModelCache[compType]:Clone()
    end

    local visual = studioVisual(compType) or CompanionVisualConfig.get(compType)

    -- Studio-owned prefabs win. Put Models under
    -- ServerStorage.CompanionVisualCatalog.Prefabs using companion keys.
    local studioCatalog = ServerStorage:FindFirstChild("CompanionVisualCatalog")
    local studioPrefabs = studioCatalog and studioCatalog:FindFirstChild("Prefabs")
    local studioPrefab = studioPrefabs and (studioPrefabs:FindFirstChild(compType) or studioPrefabs:FindFirstChild(visual.basePrefab or ""))
    if studioPrefab and studioPrefab:IsA("Model") then
        local clone = studioPrefab:Clone()
        sanitizeModel(clone)
        clone.PrimaryPart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
        if clone.PrimaryPart then
            applyAppearance(clone, visual)
            companionModelCache[compType] = clone
            return clone:Clone()
        end
        clone:Destroy()
    end

    -- Repository-authored variants win over asset IDs. Add a Model named for
    -- the companion key under src/shared/Models/Companions.
    local models = RS:FindFirstChild("Models")
    local variants = models and models:FindFirstChild("Companions")
    local authored = variants and variants:FindFirstChild(compType)
    if authored and authored:IsA("Model") then
        local clone = authored:Clone()
        sanitizeModel(clone)
        clone.PrimaryPart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
        if clone.PrimaryPart then
            applyAppearance(clone, visual)
            companionModelCache[compType] = clone
            return clone:Clone()
        end
        clone:Destroy()
        warn("[CompanionManager] Authored companion has no BasePart:", compType)
    end

    -- In-world model wins (zundapal already placed in workspace)
    local worldModel = workspace:FindFirstChild("zundapalupdate2") or workspace:FindFirstChild("zundapalupdate4")
    if compType == "zundapal" and worldModel then
        print("[CompanionManager.loadCompanionModel] Using in-world zundapalupdate2")
        local clone = worldModel:Clone()
        clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
        if clone.PrimaryPart then
            companionModelCache[compType] = clone
            return clone:Clone()
        end
    end

    local meshId = visual.modelAssetId or CompanionVisualConfig.defaultAssetId
    print("[CompanionManager.loadCompanionModel] Loading model for", compType, "meshId:", meshId)

    local success, model = pcall(function()
        local assetId = tonumber(meshId:match("%d+"))
        return InsertService:LoadAsset(assetId)
    end)

    if not success or not model then
        warn("[CompanionManager.loadCompanionModel] Failed to load model:", compType, model)
        return nil
    end

    sanitizeModel(model)
    applyAppearance(model, visual)

    -- Find the primary part for positioning
    local primaryPart = model:FindFirstChildWhichIsA("BasePart", true)
    if not primaryPart then
        warn("[CompanionManager.loadCompanionModel] Model has no BasePart:", compType)
        model:Destroy()
        return nil
    end

    model.PrimaryPart = primaryPart
    companionModelCache[compType] = model
    print("[CompanionManager.loadCompanionModel] Model cached successfully for", compType)
    return model:Clone()
end

-- Companion catalog sourced from Canonical CompanionConfig
local CompanionConfig = require(RS.ConfigurationFiles.CompanionConfig)
local COMPANIONS = CompanionConfig.companions

-- ── RemoteEvents ───────────────────────────────────────────────
local RE      = RS:WaitForChild("RemoteEvents")
local setCompEv = RE:WaitForChild("SetCompanion")
local vnEv    = RE:FindFirstChild("OpenCompanionVN")
if not vnEv then
    vnEv = Instance.new("RemoteEvent"); vnEv.Name="OpenCompanionVN"; vnEv.Parent=RE
end

local activeCompanions = {}

-- ── Build companion ────────────────────────────────────────────
local function buildCompanion(player, compType)
    print("[CompanionManager.buildCompanion] Building companion for", player.Name, "type:", compType)
    local def = COMPANIONS[compType] or COMPANIONS.zundamon
    local name = "ZundaCompanion_" .. player.Name

    -- Remove existing
    local existing = workspace:FindFirstChild(name)
    if existing then
        print("[CompanionManager.buildCompanion] Removing existing companion")
        existing:Destroy()
    end
    local prev = activeCompanions[player.Name]
    if prev then pcall(function() prev:Destroy() end) end

    -- Load the full companion model with all parts and textures
    local companionModel = loadCompanionModel(compType)

    if not companionModel then
        warn("[CompanionManager.buildCompanion] Failed to load companion model, using fallback")
        -- Create fallback model
        companionModel = Instance.new("Model")
        local body = Instance.new("Part")
        body.Name = "Body"
        body.Shape = Enum.PartType.Ball
        body.Size = Vector3.new(3, 3, 3)
        body.Material = Enum.Material.SmoothPlastic
        body.Color = def.glow
        body.Anchored = false
        body.CanCollide = false
        body.CastShadow = false
        body.Massless = true
        body.Parent = companionModel
        companionModel.PrimaryPart = body
    end

    companionModel.Name = name
    companionModel.Parent = workspace
    print("[CompanionManager.buildCompanion] Model loaded and parented to workspace")

    local body = companionModel.PrimaryPart
    if not body then
        body = companionModel:FindFirstChildWhichIsA("BasePart")
        companionModel.PrimaryPart = body
    end

    -- Start near player
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    body.CFrame = hrp and (hrp.CFrame * CFrame.new(4, 1, 0)) or CFrame.new(47, 8, -74)

    -- Make all parts non-collidable and massless
    for _, part in ipairs(companionModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Massless = true
            part.CastShadow = false
        end
    end

    print("[CompanionManager.buildCompanion] Body positioned and configured")

    -- ── Sparkle ParticleEmitter ────────────────────────────────
    local sparkle = Instance.new("ParticleEmitter", body)
    sparkle.Name = "CompanionSparkles"
    sparkle.Texture = "rbxassetid://241685484"
    sparkle.Rate = 10
    sparkle.LightEmission = 0.3
    sparkle.LightInfluence = 0.4
    sparkle.SpreadAngle = Vector2.new(180, 180)
    sparkle.Speed = NumberRange.new(1.5, 4)
    sparkle.Lifetime = NumberRange.new(0.6, 1.8)
    sparkle.RotSpeed = NumberRange.new(-180, 180)
    sparkle.Rotation = NumberRange.new(0, 360)
    local sc = def.sparkleColors
    sparkle.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   sc[1]),
        ColorSequenceKeypoint.new(0.5, sc[2]),
        ColorSequenceKeypoint.new(1,   sc[3]),
    })
    sparkle.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.25),
        NumberSequenceKeypoint.new(0.4, 0.45),
        NumberSequenceKeypoint.new(1,   0),
    })
    sparkle.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1,   1),
    })

    -- ── Point light glow ──────────────────────────────────────
    local pl = Instance.new("PointLight", body)
    pl.Brightness = 0.6
    pl.Range      = def.glowRange
    pl.Color      = def.glow
    Tween:Create(pl, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Brightness = 1.0}):Play()

    -- ── Face emoji BillboardGui ────────────────────────────────
    local sz = body.Size.Z / 2 + 0.2
    local faceBg = Instance.new("BillboardGui", body)
    faceBg.Name = "FaceBg"
    faceBg.Size = UDim2.new(0, 72, 0, 72)
    faceBg.StudsOffset = Vector3.new(0, 0, sz)
    faceBg.AlwaysOnTop = false
    faceBg.LightInfluence = 0.25
    local faceLabel = Instance.new("TextLabel", faceBg)
    faceLabel.Size = UDim2.new(1,0,1,0)
    faceLabel.BackgroundTransparency = 1
    faceLabel.Text = def.emoji
    faceLabel.Font = Enum.Font.GothamBold
    faceLabel.TextSize = 42

    -- ── Name tag ──────────────────────────────────────────────
    local halfH = body.Size.Y / 2 + 2.2
    local nameBg = Instance.new("BillboardGui", body)
    nameBg.Name = "NameTag"
    nameBg.Size = UDim2.new(0, 140, 0, 28)
    nameBg.StudsOffset = Vector3.new(0, halfH, 0)
    nameBg.AlwaysOnTop = false
    local pill = Instance.new("Frame", nameBg)
    pill.Size = UDim2.new(1,0,1,0)
    pill.BackgroundColor3 = Color3.fromRGB(30,24,40)
    pill.BackgroundTransparency = 0.15
    pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0.5, 0)
    local nLbl = Instance.new("TextLabel", pill)
    nLbl.Size = UDim2.new(1,-8,1,0); nLbl.Position = UDim2.new(0,4,0,0)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = player.Name .. "'s " .. (def.displayName or "Companion") .. " ✨"
    nLbl.Font = Enum.Font.FredokaOne
    nLbl.TextSize = 12
    nLbl.TextColor3 = Color3.fromRGB(240,230,255)
    nLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- ── ClickDetector for VN dialogue ─────────────────────────
    local cd = Instance.new("ClickDetector", body)
    cd.MaxActivationDistance = 20
    local lastClick = 0
    cd.MouseClick:Connect(function(clicker)
        local now = os.clock()
        if now - lastClick < 3 then return end
        lastClick = now
        sparkle.Rate = 60
        task.delay(0.6, function() if sparkle.Parent then sparkle.Rate = 10 end end)
        vnEv:FireClient(clicker, compType, def.emoji)
    end)

    activeCompanions[player.Name] = companionModel
    print("[CompanionManager.buildCompanion] Companion added to activeCompanions")

    -- ── Smooth follow loop ─────────────────────────────────────
    task.spawn(function()
        print("[CompanionManager.follow] Starting follow loop for", player.Name)
        local t = 0
        while body and body.Parent and companionModel.Parent do
            t = t + 0.05
            local char2 = player.Character
            local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                local floatY  = math.sin(t * 1.1) * 0.7 + 1.8
                local sideOff = hrp2.CFrame.RightVector * (3.5 + math.sin(t * 0.3) * 0.4)
                local target  = hrp2.Position + sideOff + Vector3.new(0, floatY, 0)
                local dist    = (body.Position - target).Magnitude
                if dist > 0.3 then
                    body.AssemblyLinearVelocity = (target - body.Position).Unit * math.min(dist * 5, 35)
                end
            end
            task.wait(0.05)
        end
        print("[CompanionManager.follow] Follow loop ended for", player.Name)
    end)

    print("[CompanionManager.buildCompanion] Companion build complete for", player.Name)
    return companionModel
end

-- ── Player lifecycle ───────────────────────────────────────────
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)

local function onPlayerAdded(player)
    print("[CompanionManager.onPlayerAdded] Player added:", player.Name)
    player.CharacterAdded:Connect(function()
        print("[CompanionManager.onPlayerAdded] Character added for", player.Name)
        task.wait(2)
        local data = PlayerDataService.getOrCreate(player)
        local compType = data.active_companion or "zundapal"
        print("[CompanionManager.onPlayerAdded] Building companion type:", compType)
        buildCompanion(player, compType)
    end)
end

setCompEv.OnServerEvent:Connect(function(player, compType)
	if not COMPANIONS[compType] then
		return
	end
	local data = PlayerDataService.getOrCreate(player)
	local def = COMPANIONS[compType]
	local isFree = def.free == true
	if not isFree and not data["companion_owned_" .. compType] then
		return
	end
	if not data.companions_set then data.companions_set = {} end
	data.companions_set[compType] = true
	data.active_companion = compType
	buildCompanion(player, compType)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

Players.PlayerRemoving:Connect(function(player)
    local m = activeCompanions[player.Name]
    if m then m:Destroy(); activeCompanions[player.Name] = nil end
end)

print("[CompanionManager v4] Full model loading with textures + sparkles + VN click ready")
print("[CompanionManager v4] Rojo live sync active - changes will appear in Studio automatically")
