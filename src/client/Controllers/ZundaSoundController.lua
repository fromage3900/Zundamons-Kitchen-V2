--!strict
-- [[LocalScript] ZundaSoundController]]
-- Plays cute Zunda-themed sound effects using Nomagician's UI SFX pack (CC BY 4.0)
-- Sounds are stored in game.SoundService as letter-named Sound objects (a-w + h2, i2, u2)
-- Credit: Nomagician Music (nomagician.itch.io)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundConfig = require(ReplicatedStorage.ConfigurationFiles.SoundConfig)

local ZundaSoundController = {}

-- Master SoundGroup so the Settings volume slider can scale ALL game audio at
-- once. Sounds routed into this group have their effective volume multiplied by
-- group.Volume, and any sound that joins the group later inherits the current
-- setting automatically -- which is exactly what a master-volume control needs.
local function getMasterGroup(): SoundGroup
    local group = SoundService:FindFirstChild("Master")
    if group and group:IsA("SoundGroup") then
        return group
    end
    local newGroup = Instance.new("SoundGroup")
    newGroup.Name = "Master"
    newGroup.Volume = 1
    newGroup.Parent = SoundService
    return newGroup
end
local masterGroup = getMasterGroup()

-- Set the master volume (0-1). Scales every sound routed into the Master group.
function ZundaSoundController.setMasterVolume(v: number)
    masterGroup.Volume = math.clamp(v, 0, 1)
end

-- Get the current master volume (0-1).
function ZundaSoundController.getMasterVolume(): number
    return masterGroup.Volume
end

-- Cache of played sounds to avoid re-creating
local soundCache: { [string]: Sound } = {}

-- Get or create a Sound object for a UI action
local function getSound(actionName: string): Sound?
    local cached = soundCache[actionName]
    if cached and cached.Parent then
        return cached
    end

    local sound = SoundConfig.getSound(actionName)
    if not sound then
        return nil
    end

    sound.Volume = SoundConfig.getVolume(actionName)
    sound.SoundGroup = masterGroup
    soundCache[actionName] = sound
    return sound
end

-- Small per-play pitch wobble so repeated actions never sound mechanically
-- identical (ASMR-cozy feel). Reward stingers get a touch less wobble so they
-- stay recognizable as "the" reward sound.
local function applyWobble(sound: Sound, actionName: string)
    local spread = 0.05
    if actionName == "LevelUp" or actionName == "QuestComplete" or actionName == "Success" then
        spread = 0.02
    end
    sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * spread
end

-- Play a UI sound by action name
function ZundaSoundController.play(actionName: string)
    if actionName == "Bubbles" or SoundConfig.SoundMap[actionName] == "BUBBLES" then
        ZundaSoundController.playBubbles()
        return
    end
    local sound = getSound(actionName)
    if not sound then
        return
    end
    sound.Volume = SoundConfig.getVolume(actionName)
    applyWobble(sound, actionName)
    sound:Play()
end

-- Play a sound with a short delay (for staggered effects)
function ZundaSoundController.playDelayed(actionName: string, delaySeconds: number)
    task.delay(delaySeconds, function()
        ZundaSoundController.play(actionName)
    end)
end

-- Quick one-shot: create, play, destroy after duration
function ZundaSoundController.playOneShot(actionName: string, duration: number?)
    local sound = SoundConfig.getSound(actionName)
    if not sound then
        return
    end
    local clone = sound:Clone()
    clone.Volume = SoundConfig.getVolume(actionName)
    clone.SoundGroup = masterGroup
    clone.Parent = SoundService
    clone:Play()
    game:GetService("Debris"):AddItem(clone, duration or 2)
end

-- Preload common sounds into cache (call on game start)
function ZundaSoundController.preload()
    local actionNames = {
        "PanelOpen", "PanelClose",
        "ButtonHover", "ButtonClick", "ButtonConfirm", "ButtonCancel",
        "WheelOpen", "WheelClose", "WheelSelect", "WheelNavigate",
        "Notification", "Success", "Error", "Sparkle",
        "TabSwitch",
    }
    for _, name in ipairs(actionNames) do
        getSound(name)
    end
    print("[ZundaSoundController] Preloaded " .. #actionNames .. " sounds")
end

-- Play ambient loop (idempotent -- safe to call more than once)
function ZundaSoundController.playAmbient()
    if SoundService:FindFirstChild("AmbientLoop") then
        return
    end
    local ambient = Instance.new("Sound")
    ambient.Name = "AmbientLoop"
    ambient.SoundId = SoundConfig.AmbientLoop
    ambient.Volume = SoundConfig.AmbientLoopVolume or 0.3
    ambient.Looped = true
    ambient.SoundGroup = masterGroup
    ambient.Parent = SoundService
    ambient:Play()
    print("[ZundaSoundController] Ambient loop started")
end

-- One-shot bubbles SFX -- rhythm-cooking hits, fishing catches
function ZundaSoundController.playBubbles()
    local s = Instance.new("Sound")
    s.SoundId = SoundConfig.Bubbles
    s.Volume = SoundConfig.BubblesVolume or 0.5
    s.SoundGroup = masterGroup
    s.Parent = SoundService
    s:Play()
    game:GetService("Debris"):AddItem(s, 3)
end

-- Expose globally for easy access
_G.ZundaSoundController = ZundaSoundController

ZundaSoundController.playAmbient()

print("[ZundaSoundController] Ready — Nomagician UI SFX loaded (CC BY 4.0)")

return ZundaSoundController
