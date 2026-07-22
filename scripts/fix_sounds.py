#!/usr/bin/env python3
"""Wire ZundaSoundController into UI components."""

# 1. Add sounds to CozyModalShell
fp = "src/shared/ConfigurationFiles/CozyModalShell.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

old_open = """local function openShell()
\t\tif options.open then
\t\t\toptions.open()
\t\tend
\t\tspawnOpenSparkles(panel)
\tend"""

new_open = """local function openShell()
\t\t-- Play panel open sound
\t\tlocal zsc = _G.ZundaSoundController
\t\tif zsc and zsc.play then
\t\t\tzsc.play("PanelOpen")
\t\tend
\t\tif options.open then
\t\t\toptions.open()
\t\tend
\t\tspawnOpenSparkles(panel)
\tend"""

old_close = """local function closeShell()
\t\tif options.close then
\t\t\toptions.close()
\t\tend
\tend"""

new_close = """local function closeShell()
\t\t-- Play panel close sound
\t\tlocal zsc = _G.ZundaSoundController
\t\tif zsc and zsc.play then
\t\t\tzsc.play("PanelClose")
\t\tend
\t\tif options.close then
\t\t\toptions.close()
\t\tend
\tend"""

c = c.replace(old_open, new_open, 1)
c = c.replace(old_close, new_close, 1)
with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[CozyModalShell] Added sounds to open/close")

# 2. Add sounds to PeaWheelController
fp = "src/client/Controllers/PeaWheelController.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

old_wheel_open = "function PeaWheelController.open()\n\tif isOpen then return end\n\tif RunService:IsStudio() and RunService:IsEdit() then return end"
new_wheel_open = "function PeaWheelController.open()\n\tif isOpen then return end\n\tif RunService:IsStudio() and RunService:IsEdit() then return end\n\n\t-- Play wheel open sound\n\tlocal zsc = _G.ZundaSoundController\n\tif zsc and zsc.play then\n\t\tzsc.play(\"WheelOpen\")\n\tend"
c = c.replace(old_wheel_open, new_wheel_open, 1)

old_wheel_close = "function PeaWheelController.close()\n\tif not isOpen then return end\n\tisOpen = false\n\n\tif not hubButton or not tooltipLabel then return end"
new_wheel_close = "function PeaWheelController.close()\n\tif not isOpen then return end\n\tisOpen = false\n\n\t-- Play wheel close sound\n\tlocal zsc = _G.ZundaSoundController\n\tif zsc and zsc.play then\n\t\tzsc.play(\"WheelClose\")\n\tend\n\n\tif not hubButton or not tooltipLabel then return end"
c = c.replace(old_wheel_close, new_wheel_close, 1)

old_wheel_select = "function PeaWheelController.select(actionId)\n\tif not isOpen then return end\n\tlocal ok = ActionRegistry.dispatch(actionId)"
new_wheel_select = "function PeaWheelController.select(actionId)\n\tif not isOpen then return end\n\t-- Play wheel select sound\n\tlocal zsc = _G.ZundaSoundController\n\tif zsc and zsc.play then\n\t\tzsc.play(\"WheelSelect\")\n\tend\n\tlocal ok = ActionRegistry.dispatch(actionId)"
c = c.replace(old_wheel_select, new_wheel_select, 1)

with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[PeaWheelController] Added sounds to open/close/select")

print("\nAll sounds wired successfully!")