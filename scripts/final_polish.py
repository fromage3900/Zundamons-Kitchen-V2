#!/usr/bin/env python3
"""Final polish: sound wiring, keyboard fixes, Ollama workers, commit."""

import os
import json

# ============================================================
# 1. Update SoundConfig with letter-based sound mapping
# ============================================================
sound_config = '''--!strict
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

        -- Pea Wheel
        WheelOpen = "g",
        WheelClose = "h",
        WheelSelect = "i",
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
        CoinEarn = "u",

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

    -- Ambient loop (background music)
    AmbientLoop = "rbxassetid://87341474417325",
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
'''

with open("src/shared/ConfigurationFiles/SoundConfig.lua", "w", encoding="utf-8") as f:
    f.write(sound_config)
print("[SoundConfig] Updated with letter-based sound mapping")

# ============================================================
# 2. Update ZundaSoundController to use letter-based sounds
# ============================================================
sound_controller = '''--!strict
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
'''

with open("src/client/Controllers/ZundaSoundController.lua", "w", encoding="utf-8") as f:
    f.write(sound_controller)
print("[ZundaSoundController] Updated with letter-based sound lookup")

# ============================================================
# 3. Check UIActionRegistry for keyboard duplicates
# ============================================================
print("\n[Keyboard] Checking UIActionRegistry for duplicates...")
with open("src/client/ConfigurationFiles/UIActionRegistry.lua", "r", encoding="utf-8", errors="replace") as f:
    registry = f.read()

# Find all keyboard shortcuts
import re
shortcuts = re.findall(r'(\w+)\s*=\s*Enum\.KeyCode\.(\w+)', registry)
key_map = {}
dupes = []
for action, key in shortcuts:
    if key in key_map:
        dupes.append(f"{key}: {key_map[key]} and {action}")
    key_map[key] = action

if dupes:
    print(f"  DUPLICATES FOUND:")
    for d in dupes:
        print(f"    - {d}")
else:
    print(f"  No duplicates found. {len(key_map)} unique keys registered.")
    for action, key in sorted(shortcuts):
        print(f"    {key}: {action}")

# ============================================================
# 4. Check Ollama daemon and list available models
# ============================================================
print("\n[Ollama] Checking daemon status...")
import subprocess
try:
    result = subprocess.run(["ollama", "list"], capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        print("  Ollama is running. Available models:")
        print(result.stdout)
    else:
        print(f"  Ollama error: {result.stderr}")
except Exception as e:
    print(f"  Ollama not accessible: {e}")

# ============================================================
# 5. Summary
# ============================================================
print("\n=== POLISH COMPLETE ===")
print(f"  - SoundConfig: letter-based mapping (26 sounds, CC BY 4.0)")
print(f"  - ZundaSoundController: letter lookup + ambient loop")
print(f"  - Keyboard: checked for duplicates")
print(f"  - Ollama: daemon status checked")
print(f"\nNext: Run autonomous workers and commit all changes")