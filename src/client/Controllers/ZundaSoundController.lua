--!strict
-- [[LocalScript] ZundaSoundController]]
-- Plays cute Zunda-themed sound effects using Nomagician's UI SFX pack (CC BY 4.0)
-- Sounds are stored in game.SoundService as letter-named Sound objects (a-w + h2, i2, u2)
-- Credit: Nomagician Music (nomagician.itch.io)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundConfig = require(ReplicatedStorage.ConfigurationFiles.SoundConfig)

local ZundaSoundController = {}

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
    soundCache[actionName] = sound
    return sound
end

-- Play a UI sound by action name
function ZundaSoundController.play(actionName: string)
    local sound = getSound(actionName)
    if not sound then
        return
    end
    sound.Volume = SoundConfig.getVolume(actionName)
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

-- Play ambient loop
function ZundaSoundController.playAmbient()
    local ambient = Instance.new("Sound")
    ambient.Name = "AmbientLoop"
    ambient.SoundId = SoundConfig.AmbientLoop
    ambient.Volume = 0.3
    ambient.Looped = true
    ambient.Parent = SoundService
    ambient:Play()
    print("[ZundaSoundController] Ambient loop started")
end

-- Expose globally for easy access
_G.ZundaSoundController = ZundaSoundController

print("[ZundaSoundController] Ready — Nomagician UI SFX loaded (CC BY 4.0)")

return ZundaSoundController
