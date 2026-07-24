--!strict
-- [[ModuleScript] SoundConfig]]
-- Cute Zunda-themed sound definitions using Nomagician's UI SFX pack (CC BY 4.0)
-- Sounds are stored in game.SoundService as letter-named Sound objects (a-w + h2, i2, u2)
-- Credit: Nomagician Music (nomagician.itch.io)

local SoundConfig = {
    -- Master volume multiplier (0-1)
    MasterVolume = 0.7,

    -- Sound letter mapping: UI action -> letter(s) in SoundService
    -- Use table for multiple variants (random pick), or single letter
    SoundMap = {
        -- Panel open/close
        PanelOpen = "a",
        PanelClose = "b",

        -- Button interactions
        ButtonHover = "c",
        ButtonClick = "d",
        ButtonConfirm = "e",
        ButtonCancel = "f",

        -- Pea Wheel (variant tables → random pick per play, avoids repetition
        -- on the high-frequency wheel interactions)
        WheelOpen = "g",
        WheelClose = { "h", "h2" },
        WheelSelect = { "i", "i2" },
        WheelNavigate = "j",

        -- Notifications & feedback
        Notification = "k",
        Success = "l",
        Error = "m",
        Sparkle = "n",

        -- Tab switching
        TabSwitch = "o",

        -- Cooking
        CookingTick = "p",
        CookingPerfect = "q",
        CookingMiss = "r",

        -- Progression
        LevelUp = "s",
        QuestComplete = "t",
        CoinEarn = { "u", "u2" },

        -- Extra variants (random pick from table)
        -- Use {"u", "u2"} for 50/50 random between two variants
    },

    -- Per-sound volume multipliers (0-1, applied after MasterVolume)
    Volumes = {
        PanelOpen = 0.5,
        PanelClose = 0.4,
        ButtonHover = 0.3,
        ButtonClick = 0.5,
        ButtonConfirm = 0.6,
        ButtonCancel = 0.4,
        WheelOpen = 0.4,
        WheelClose = 0.3,
        WheelSelect = 0.6,
        WheelNavigate = 0.3,
        Notification = 0.5,
        Success = 0.6,
        Error = 0.5,
        Sparkle = 0.3,
        TabSwitch = 0.3,
        CookingTick = 0.3,
        CookingPerfect = 0.6,
        CookingMiss = 0.4,
        LevelUp = 0.7,
        QuestComplete = 0.6,
        CoinEarn = 0.4,
    },

    -- Ambient zone sounds (positioned 3D audio via AmbientZoneAudio)
    ZoneAmbient = {
        Kitchen = { soundId = "rbxassetid://9112780462", volume = 0.12, range = 20 },
        Garden  = { soundId = "rbxassetid://9112832297", volume = 0.08, range = 30 },
        Pond    = { soundId = "rbxassetid://9119646409", volume = 0.10, range = 25 },
    },

    -- Companion interaction sounds
    Companion = {
        pet       = "rbxassetid://4612374495",
        greeting  = "rbxassetid://4612374495",
        buff      = "rbxassetid://4612374495",
    },

    -- Ambient loop (background music) -- melusinabaseambience98bpm, user-uploaded 2026-07-24
    AmbientLoop = "rbxassetid://106967719074596",
    AmbientLoopVolume = 0.35,

    -- Bubbles SFX -- procs on rhythm-cooking hits and fishing catches
    Bubbles = "rbxassetid://136926771045300",
    BubblesVolume = 0.5,
}

-- Helper: get the Sound object for a UI action
function SoundConfig.getSound(actionName: string): Sound?
    local letter = SoundConfig.SoundMap[actionName]
    if not letter then
        return nil
    end

    -- Support table of variants (random pick)
    if type(letter) == "table" then
        letter = letter[math.random(1, #letter)]
    end

    local sound = game.SoundService:FindFirstChild(letter)
    if sound and sound:IsA("Sound") then
        return sound
    end

    -- Fallback: try to find any sound with the letter in its name
    for _, child in ipairs(game.SoundService:GetChildren()) do
        if child:IsA("Sound") and string.find(child.Name, letter) then
            return child
        end
    end

    return nil
end

-- Helper: get volume for a sound (MasterVolume * per-sound volume)
function SoundConfig.getVolume(actionName: string): number
    local vol = SoundConfig.Volumes[actionName] or 0.5
    return SoundConfig.MasterVolume * vol
end

return SoundConfig
