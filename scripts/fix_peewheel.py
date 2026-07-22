#!/usr/bin/env python3
"""Fix PeaWheelController: add hub button click handler in buildWheelGui(), remove redundant bottom section."""

filepath = "src/client/Controllers/PeaWheelController.lua"

with open(filepath, "r", encoding="utf-8", errors="replace") as f:
    content = f.read()

# 1. Add hub button click handler in buildWheelGui() after the stroke setup
old_stroke = "\thubStroke.Transparency = 0.2\n\n\t-- Tooltip"
new_stroke = """\thubStroke.Transparency = 0.2

\t-- Hub button click handler (connected when hub is created)
\thubButton.MouseButton1Click:Connect(function()
\t\tif RunService:IsStudio() and RunService:IsEdit() then return end
\t\tif _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
\t\tPeaWheelController.toggle()
\t\tif not reducedMotion then
\t\t\tlocal UIHelper = require(ReplicatedStorage.Shared.Modules.UIHelper)
\t\t\tif UIHelper and UIHelper.spawnSparkles then
\t\t\t\tUIHelper.spawnSparkles(hubButton, hubButton.AbsoluteSize.X/2, hubButton.AbsoluteSize.Y/2, Color3.fromRGB(255,255,255), 8)
\t\t\tend
\t\tend
\tend)

\t-- Tooltip"""

if old_stroke in content:
    content = content.replace(old_stroke, new_stroke, 1)
    print("Added hub button click handler in buildWheelGui()")
else:
    print("WARNING: Could not find stroke setup pattern - skipping handler addition")

# 2. Remove the redundant bottom section (from "-- Hub button\nif hubButton then" to just before "-- Expose Globals")
bottom_section = """-- Hub button
if hubButton then
\thubButton.MouseButton1Click:Connect(function()
\t\tif RunService:IsStudio() and RunService:IsEdit() then return end
\t\tif _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
\t\tPeaWheelController.toggle()
\t\t-- Cute sparkle frill on hub click
\t\tif not reducedMotion then
\t\t\tlocal UIHelper = require(ReplicatedStorage.Shared.Modules.UIHelper)
\t\t\tif UIHelper and UIHelper.spawnSparkles then
\t\t\t\tUIHelper.spawnSparkles(hubButton, hubButton.AbsoluteSize.X/2, hubButton.AbsoluteSize.Y/2, Color3.fromRGB(255,255,255), 8)
\t\t\tend
\t\tend
\tend)
else
\t-- Build on first require
\ttask.spawn(function()
\t\tlocal gui = buildWheelGui()
\t\tif gui and hubButton then
\t\t\thubButton.MouseButton1Click:Connect(function()
\t\t\t\tif RunService:IsStudio() and RunService:IsEdit() then return end
\t\t\t\tif _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
\t\t\t\tPeaWheelController.toggle()
\t\t\tend)
\t\tend
\tend)
end

-- Expose Globals"""

replacement = """-- Expose Globals"""

if bottom_section in content:
    content = content.replace(bottom_section, replacement, 1)
    print("Removed redundant bottom section")
else:
    print("WARNING: Could not find bottom section pattern - skipping removal")

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Saved: {filepath}")
