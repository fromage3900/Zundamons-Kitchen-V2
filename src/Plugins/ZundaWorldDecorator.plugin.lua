--!strict
-- ZundaWorldDecorator — AAA Studio Plugin
-- Entry point: Script saved as Local Plugin in Roblox Studio
-- Requires: plugin global (Studio only), PluginSecurity

local plugin = script:FindFirstAncestorWhichIsA("Plugin")
if not plugin then
    error("[ZundaWorldDecorator] This script must be saved as a Local Plugin in Roblox Studio")
end

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================
-- MODULE LOADER
-- ============================================================
-- Direct module cache to satisfy Studio plugin require semantics
local Modules = {}
local function req(name: string)
    if not Modules[name] then
        local child = script:FindFirstChild(name)
        if not child then
            error("[ZundaWorldDecorator] Module not found: " .. name)
        end
        Modules[name] = require(child)
    end
    return Modules[name]
end

local DecorationCatalog = req("DecorationCatalog")
local ZoneProfiles = req("ZoneProfiles")
local MaterialPalette = req("MaterialPalette")

local ScatterEngine = req("ScatterEngine")
local ProceduralGeometry = req("ProceduralGeometry")
local MaterialVariantSystem = req("MaterialVariantSystem")
local LODManager = req("LODManager")
local SetDressingRules = req("SetDressingRules")
local UndoManager = req("UndoManager")

local MainWidget = req("MainWidget")

-- ============================================================
-- PLUGIN STATE
-- ============================================================
local PLUGIN_ID = "ZundaWorldDecorator_v1"
local state = {
    selectedZone = nil,
    density = 0.35,
    selectedDecorations = {"lantern_post", "cherry_tree", "flower_cluster", "glowing_mushroom"},
    applyMaterials = true,
    applyVistas = true,
    dryRun = false,
    isProcessing = false,
}

-- ============================================================
-- PERSISTENCE (Plugin Settings)
-- ============================================================
local function loadSettings()
    local saved = plugin:GetSetting("lastZone")
    if saved then state.selectedZone = saved end

    local density = plugin:GetSetting("density")
    if density then state.density = density end

    local decs = plugin:GetSetting("decorations")
    if decs then state.selectedDecorations = decs end

    local mats = plugin:GetSetting("applyMaterials")
    if mats ~= nil then state.applyMaterials = mats end

    local vistas = plugin:GetSetting("applyVistas")
    if vistas ~= nil then state.applyVistas = vistas end
end

local function saveSettings()
    plugin:SetSetting("lastZone", state.selectedZone or "")
    plugin:SetSetting("density", state.density)
    plugin:SetSetting("decorations", state.selectedDecorations)
    plugin:SetSetting("applyMaterials", state.applyMaterials)
    plugin:SetSetting("applyVistas", state.applyVistas)
end

-- ============================================================
-- TOOLBAR + WIDGET
-- ============================================================
local toolbar = plugin:CreateToolbar("Zunda Decorator")

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Float,
    true,   -- enabled
    false,  -- don't override previous state
    320,    -- width
    600,    -- height
    280,    -- min width
    500     -- min height
)

local widget = plugin:CreateDockWidgetPluginGuiAsync(
    PLUGIN_ID .. "_MainWidget",
    widgetInfo
)
widget.Title = "🌸 Zunda World Decorator"

-- Close button behavior
widget:BindToClose(function()
    widget.Enabled = false
end)

-- ============================================================
-- UI CONSTRUCTION
-- ============================================================
local mainWidget = MainWidget.new(widget, plugin, {
    zones = ZoneProfiles.getZoneNames(),
    decorations = DecorationCatalog.getAllNames(),
    state = state,
    onDecorate = function(zoneName, config)
        if state.isProcessing then
            warn("[ZundaWorldDecorator] Already processing — please wait")
            return
        end
        state.isProcessing = true
        saveSettings()

        local success, err = pcall(function()
            local zoneProfile = ZoneProfiles.getZone(zoneName)
            if not zoneProfile then
                error("Zone not found: " .. tostring(zoneName))
            end

            -- Scan zone boundaries
            local zoneBounds = ScatterEngine.scanZone(zoneName)
            if not zoneBounds then
                error("Could not detect zone bounds for: " .. tostring(zoneName))
            end

            -- Generate surface samples
            local samples = ScatterEngine.sampleSurface(
                zoneBounds,
                config.density,
                zoneProfile.exclusionTags or {"NoScatter", "Building", "Interior"}
            )

            if #samples == 0 then
                warn("[ZundaWorldDecorator] No valid surface points found — check exclusion tags")
                return
            end

            -- Place decorations
            local placed = {}
            for _, sample in ipairs(samples) do
                local decoType = ScatterEngine.pickDecoration(
                    config.selectedDecorations,
                    zoneProfile.decorationWeights
                )
                if decoType then
                    local instances = ProceduralGeometry.build(
                        decoType,
                        sample.position,
                        sample.normal,
                        zoneProfile.styleVariant or "default"
                    )
                    if instances then
                        for _, inst in ipairs(instances) do
                            table.insert(placed, inst)
                        end
                    end
                end
            end

            -- Apply terrain materials
            if config.applyMaterials and zoneProfile.materialVariant then
                MaterialVariantSystem.paintZone(zoneName, zoneProfile.materialVariant, zoneBounds)
            end

            -- Generate distant vistas
            if config.applyVistas and zoneProfile.vista then
                SetDressingRules.generateVista(zoneProfile.vista)
            end

            -- Apply weather-reactive set dressing
            SetDressingRules.applyWeatherReactions(zoneName, zoneProfile.weatherReactions)

            -- Register with undo manager
            if #placed > 0 then
                UndoManager.registerBatch(placed, zoneName)
            end

            -- Update LOD
            LODManager.registerDecorations(placed)

            print(string.format("[ZundaWorldDecorator] Placed %d decorations in %s", #placed, zoneName))
        end)

        state.isProcessing = false

        if not success then
            warn("[ZundaWorldDecorator] Error: " .. tostring(err))
        end
    end,
    onUndo = function(zoneName)
        UndoManager.undoZone(zoneName)
    end,
    onClearAll = function()
        UndoManager.clearAll()
    end,
})

-- ============================================================
-- TOOLBAR BUTTONS
-- ============================================================
local toggleBtn = toolbar:CreateButton(
    "Toggle Decorator",
    "Open/Close Zunda World Decorator",
    "rbxassetid://111378866841838"
)
toggleBtn.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

-- ============================================================
-- EVENT HANDLERS
-- ============================================================
local selectionChangedConn = game.Selection.SelectionChanged:Connect(function()
    -- Could auto-detect zone from selected object
end)

-- ============================================================
-- CLEANUP
-- ============================================================
local function cleanup()
    if selectionChangedConn then
        selectionChangedConn:Disconnect()
    end

    UndoManager.clearAll()
    LODManager.shutdown()

    if mainWidget and mainWidget.destroy then
        mainWidget:destroy()
    end

    print("[ZundaWorldDecorator] Plugin unloaded cleanly")
end

plugin.Unloading:Connect(cleanup)

-- ============================================================
-- INITIALIZATION
-- ============================================================
local function init()
    loadSettings()

    -- Initialize subsystems
    MaterialPalette.registerAll()
    LODManager.init()

    print("[ZundaWorldDecorator] Plugin initialized v1.0")
    print("  Zones available: " .. table.concat(ZoneProfiles.getZoneNames(), ", "))
    print("  Decorations: " .. #DecorationCatalog.getAllNames())
end

task.spawn(init)

return {
    name = "ZundaWorldDecorator",
    version = "1.0.0",
    plugin = plugin,
    state = state,
}