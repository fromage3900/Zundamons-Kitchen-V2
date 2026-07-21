-- [[ModuleScript] TeleporterConfig (ref: RBX6B1E3DFF58104AD7BF096C9765EC97A9)]]
-- TeleporterConfig: Defines zone teleporter network and destinations

local TeleporterConfig = {
    -- Zone definitions: name, display name, emoji, description
    zones = {
        village = {name = "Village", emoji = "🏘", description = "Main settlement"},
        kitchen = {name = "Kitchen", emoji = "🍳", description = "Cooking area"},
        eastpeaks = {name = "Eastern Peaks", emoji = "⛰", description = "Mountain region"},
        mystic = {name = "Mystic Forest", emoji = "🌲", description = "Enchanted woodland"},
    },
    
    -- Teleporter pad positions and destinations
    -- Each zone has a teleporter pad that connects to other zones
    pads = {
        TPad_village = {
            zone = "village",
            destinations = {"kitchen", "eastpeaks", "mystic"},
            displayName = "Village Teleporter",
        },
        TPad_kitchen = {
            zone = "kitchen",
            destinations = {"village", "eastpeaks", "mystic"},
            displayName = "Kitchen Teleporter",
        },
        TPad_eastpeaks = {
            zone = "eastpeaks",
            destinations = {"village", "kitchen", "mystic"},
            displayName = "Eastern Peaks Teleporter",
        },
        TPad_mystic = {
            zone = "mystic",
            destinations = {"village", "kitchen", "eastpeaks"},
            displayName = "Mystic Forest Teleporter",
        },
    },
    
    -- Teleportation settings
    FADE_DURATION = 0.5,
    TELEPORT_DISTANCE = 30,  -- How close player needs to be
    DESTINATION_OFFSET = Vector3.new(5, 3, 5),  -- Offset from pad center
}

return TeleporterConfig