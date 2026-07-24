--!strict
-- DecorationCatalog: Data-driven blueprints for all procedural decorations
-- Used by ZundaWorldDecorator plugin

local DecorationCatalog = {}

-- ============================================================
-- HELPER: Create a standardized part
-- ============================================================
local function partDef(className: string, size: Vector3, color: Color3, position: Vector3, options: any?)
    options = options or {}
    local def = {
        type = className,
        size = size,
        color = color,
        position = position,
        rotation = options.rotation or Vector3.new(0, 0, 0),
        transparency = options.transparency or 0,
        canCollide = if options.canCollide == nil then false else options.canCollide,
        material = options.material or Enum.Material.SmoothPlastic,
    }
    return def
end

-- ============================================================
-- HELPER: Light definition
-- ============================================================
local function lightDef(type: string, color: Color3, range: number, brightness: number)
    return {
        type = type,
        color = color,
        range = range,
        brightness = brightness,
    }
end

-- ============================================================
-- DECORATION BLUEPRINTS
-- ============================================================

-- 1. LANTERN POST
-- A pastel street lamp with warm glow
DecorationCatalog.lantern_post = {
    name = "Pastel Street Lamp",
    tags = {"village", "pagoda", "path", "garden"},
    baseSize = Vector3.new(1, 4.5, 1),
    parts = {
        partDef("Cylinder", Vector3.new(0.25, 3.8, 0.25), Color3.fromRGB(255, 200, 80), Vector3.new(0, 1.9, 0)),
        partDef("Sphere", Vector3.new(0.55, 0.55, 0.55), Color3.fromRGB(255, 200, 100), Vector3.new(0, 4.1, 0), { transparency = 0.2 }),
        partDef("Cylinder", Vector3.new(0.2, 0.25, 0.2), Color3.fromRGB(255, 180, 60), Vector3.new(0, 4.45, 0)),
    },
    lights = {
        lightDef("PointLight", Color3.fromRGB(255, 200, 80), 10, 2.5),
    },
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.9, max = 1.15 },
    rotationJitter = true,
}

-- 2. CHERRY BLOSSOM TREE
-- Soft pink canopy on pastel trunk
DecorationCatalog.cherry_tree = {
    name = "Cherry Blossom Tree",
    tags = {"village", "pagoda", "garden"},
    baseSize = Vector3.new(5, 6, 5),
    parts = {
        partDef("Cylinder", Vector3.new(0.4, 2.5, 0.4), Color3.fromRGB(200, 180, 160), Vector3.new(0, 1.25, 0)),
        partDef("Cylinder", Vector3.new(0.3, 1.8, 0.3), Color3.fromRGB(190, 170, 150), Vector3.new(0, 3.4, 0)),
        -- Canopy layers
        partDef("Sphere", Vector3.new(1.8, 1.6, 1.8), Color3.fromRGB(255, 192, 203), Vector3.new(0, 4.8, 0)),
        partDef("Sphere", Vector3.new(1.4, 1.3, 1.4), Color3.fromRGB(255, 180, 200), Vector3.new(0.3, 5.0, 0.2)),
        partDef("Sphere", Vector3.new(1.2, 1.1, 1.2), Color3.fromRGB(255, 200, 210), Vector3.new(-0.2, 5.2, -0.1)),
        partDef("Sphere", Vector3.new(1.0, 0.9, 1.0), Color3.fromRGB(255, 210, 215), Vector3.new(0.1, 5.4, -0.2)),
    },
    lights = {},
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.85, max = 1.25 },
    rotationJitter = true,
}

-- 3. FLOWER CLUSTER
-- Mixed pastel flowers on a small patch
DecorationCatalog.flower_cluster = {
    name = "Pastel Flower Cluster",
    tags = {"village", "garden", "forest", "all"},
    baseSize = Vector3.new(1.5, 0.5, 1.5),
    parts = {
        partDef("Sphere", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(255, 150, 200), Vector3.new(0.3, 0.15, 0.2)),
        partDef("Sphere", Vector3.new(0.18, 0.18, 0.18), Color3.fromRGB(255, 200, 150), Vector3.new(-0.2, 0.12, 0.3)),
        partDef("Sphere", Vector3.new(0.22, 0.22, 0.22), Color3.fromRGB(200, 180, 255), Vector3.new(0.1, 0.18, -0.2)),
        partDef("Sphere", Vector3.new(0.15, 0.15, 0.15), Color3.fromRGB(255, 180, 220), Vector3.new(-0.3, 0.1, -0.1)),
        partDef("Sphere", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(255, 210, 180), Vector3.new(0.2, 0.2, -0.3)),
    },
    lights = {},
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.8, max = 1.3 },
    rotationJitter = false,
}

-- 4. GLOWING MUSHROOM
-- Bioluminescent mushroom cluster
DecorationCatalog.glow_mushroom = {
    name = "Glowing Mushroom",
    tags = {"forest", "mystic", "ruins"},
    baseSize = Vector3.new(2, 3, 2),
    parts = {
        partDef("Cylinder", Vector3.new(0.3, 1.5, 0.3), Color3.fromRGB(200, 210, 220), Vector3.new(0, 0.75, 0)),
        partDef("Part", Vector3.new(1.4, 0.6, 1.4), Color3.fromRGB(180, 200, 255), Vector3.new(0, 2.2, 0), { transparency = 0.15 }),
        partDef("Sphere", Vector3.new(0.15, 0.15, 0.15), Color3.fromRGB(220, 230, 255), Vector3.new(0.4, 2.5, 0.3)),
        partDef("Sphere", Vector3.new(0.12, 0.12, 0.12), Color3.fromRGB(200, 220, 255), Vector3.new(-0.3, 2.6, -0.2)),
    },
    lights = {
        lightDef("PointLight", Color3.fromRGB(180, 200, 255), 7, 1.8),
    },
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.8, max = 1.4 },
    rotationJitter = true,
}

-- 5. FLOATING CRYSTAL
-- Pink/blue crystal shards
DecorationCatalog.floating_crystal = {
    name = "Floating Crystal",
    tags = {"ruins", "mystic", "peaks"},
    baseSize = Vector3.new(1.5, 2.5, 1.5),
    parts = {
        partDef("Wedge", Vector3.new(0.4, 1.2, 0.4), Color3.fromRGB(255, 182, 193), Vector3.new(0, 1.0, 0), { rotation = Vector3.new(0, 0, 15) }),
        partDef("Wedge", Vector3.new(0.35, 1.0, 0.35), Color3.fromRGB(200, 182, 255), Vector3.new(0.15, 0.9, 0.1), { rotation = Vector3.new(0, 45, -10) }),
        partDef("Wedge", Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(173, 216, 230), Vector3.new(-0.1, 0.7, -0.15), { rotation = Vector3.new(15, 90, 5) }),
    },
    lights = {
        lightDef("PointLight", Color3.fromRGB(200, 182, 255), 5, 1.2),
    },
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.7, max = 1.2 },
    rotationJitter = true,
}

-- 6. STONE MEDITATION CIRCLE
-- Ring of standing stones
DecorationCatalog.meditation_circle = {
    name = "Meditation Circle",
    tags = {"pagoda", "ruins", "peaks"},
    baseSize = Vector3.new(4, 0.3, 4),
    parts = {},
    lights = {},
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.9, max = 1.1 },
    rotationJitter = false,
    customBuild = "meditation_circle",
}

-- 7. PASTEL ARCHWAY
-- Decorative arch for zone entrances
DecorationCatalog.pastel_archway = {
    name = "Pastel Archway",
    tags = {"village", "pagoda", "garden"},
    baseSize = Vector3.new(4, 4, 1.5),
    parts = {
        partDef("Cylinder", Vector3.new(0.3, 4, 0.3), Color3.fromRGB(255, 240, 245), Vector3.new(-1.7, 2, 0)),
        partDef("Cylinder", Vector3.new(0.3, 4, 0.3), Color3.fromRGB(255, 240, 245), Vector3.new(1.7, 2, 0)),
        partDef("Cylinder", Vector3.new(3.4, 0.35, 0.35), Color3.fromRGB(255, 240, 245), Vector3.new(0, 3.9, 0), { rotation = Vector3.new(0, 0, 90) }),
        partDef("Cylinder", Vector3.new(3.4, 0.35, 0.35), Color3.fromRGB(255, 240, 245), Vector3.new(0, 3.5, 0), { rotation = Vector3.new(0, 0, 90) }),
        partDef("Cylinder", Vector3.new(3.4, 0.35, 0.35), Color3.fromRGB(255, 240, 245), Vector3.new(0, 0.2, 0), { rotation = Vector3.new(0, 0, 90) }),
    },
    lights = {},
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.95, max = 1.15 },
    rotationJitter = false,
}

-- 8. WIND CHIME
-- Delicate hanging chimes for Pagoda/Village
DecorationCatalog.wind_chime = {
    name = "Wind Chime",
    tags = {"pagoda", "village", "garden"},
    baseSize = Vector3.new(0.8, 2, 0.8),
    parts = {
        partDef("Cylinder", Vector3.new(0.1, 0.8, 0.1), Color3.fromRGB(255, 200, 80), Vector3.new(0, 0.4, 0)),
        partDef("Cylinder", Vector3.new(0.6, 0.05, 0.6), Color3.fromRGB(255, 220, 100), Vector3.new(0, 0.85, 0)),
        partDef("Cylinder", Vector3.new(0.05, 0.5, 0.05), Color3.fromRGB(200, 220, 255), Vector3.new(-0.15, 1.3, 0)),
        partDef("Cylinder", Vector3.new(0.05, 0.4, 0.05), Color3.fromRGB(255, 200, 220), Vector3.new(0, 1.2, 0)),
        partDef("Cylinder", Vector3.new(0.05, 0.55, 0.05), Color3.fromRGB(200, 255, 220), Vector3.new(0.15, 1.4, 0)),
    },
    lights = {},
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.9, max = 1.1 },
    rotationJitter = false,
}

-- 9. CRYSTAL SPIRE
-- Tall crystalline formation
DecorationCatalog.crystal_spire = {
    name = "Crystal Spire",
    tags = {"ruins", "mystic", "peaks"},
    baseSize = Vector3.new(1, 5, 1),
    parts = {
        partDef("Wedge", Vector3.new(0.5, 2.5, 0.5), Color3.fromRGB(200, 182, 255), Vector3.new(0, 1.25, 0), { rotation = Vector3.new(0, 0, 0) }),
        partDef("Wedge", Vector3.new(0.4, 1.8, 0.4), Color3.fromRGB(173, 216, 230), Vector3.new(0.1, 0.9, 0.1), { rotation = Vector3.new(0, 30, 8) }),
        partDef("Wedge", Vector3.new(0.3, 1.2, 0.3), Color3.fromRGB(255, 182, 193), Vector3.new(-0.05, 0.6, -0.08), { rotation = Vector3.new(10, 60, -5) }),
    },
    lights = {
        lightDef("PointLight", Color3.fromRGB(200, 182, 255), 8, 1.5),
    },
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.8, max = 1.3 },
    rotationJitter = true,
}

-- 10. SIGNPOST
-- Directional signpost
DecorationCatalog.signpost = {
    name = "Pastel Signpost",
    tags = {"village", "path", "garden"},
    baseSize = Vector3.new(0.8, 3, 0.8),
    parts = {
        partDef("Cylinder", Vector3.new(0.15, 2.5, 0.15), Color3.fromRGB(200, 180, 160), Vector3.new(0, 1.25, 0)),
        partDef("Part", Vector3.new(0.6, 0.4, 0.05), Color3.fromRGB(145, 215, 195), Vector3.new(0, 2.3, 0.3)),
    },
    lights = {},
    anchored = true,
    canCollide = false,
    scaleRange = { min = 0.9, max = 1.1 },
    rotationJitter = true,
}

-- ============================================================
-- PUBLIC API
-- ============================================================
function DecorationCatalog.getAllNames()
    local names = {}
    for name, _ in DecorationCatalog do
        if name ~= "getAllNames" and name ~= "getBlueprint" and name ~= "getByTag" then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

function DecorationCatalog.getBlueprint(name: string)
    return DecorationCatalog[name]
end

function DecorationCatalog.getByTag(tag: string)
    local results = {}
    for name, blueprint in pairs(DecorationCatalog) do
        if blueprint.tags and table.find(blueprint.tags, tag) then
            table.insert(results, name)
        end
    end
    return results
end

return DecorationCatalog