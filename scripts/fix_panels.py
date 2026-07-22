#!/usr/bin/env python3
"""Fix panel scripts: add ActionRegistry require, actionId to CozyModalShell.wrap, and UIRouter/ActionRegistry registrations."""

PANELS = [
    ("src/client/PouchScript.client.lua", "inventory"),
    ("src/client/QuestScript.client.lua", "quests"),
    ("src/client/CompendiumScript.client.lua", "compendium"),
]

for filepath, action_id in PANELS:
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    # 1. Add ActionRegistry require after UIRouter require
    old_require = "local UIRouter = require(RS.ConfigurationFiles.UIRouter)"
    new_require = old_require + "\nlocal ActionRegistry = require(RS.ConfigurationFiles.UIActionRegistry)"
    if "ActionRegistry" not in content:
        content = content.replace(old_require, new_require, 1)
        print(f"  [{action_id}] Added ActionRegistry require")
    else:
        print(f"  [{action_id}] ActionRegistry require already present")

    # 2. Add actionId to CozyModalShell.wrap call
    old_wrap = "CozyModalShell.wrap(panel, {"
    new_wrap = 'CozyModalShell.wrap(panel, { actionId = "' + action_id + '",'
    if 'actionId = "' + action_id + '"' not in content:
        content = content.replace(old_wrap, new_wrap, 1)
        print(f"  [{action_id}] Added actionId to CozyModalShell.wrap")
    else:
        print(f"  [{action_id}] actionId already present in CozyModalShell.wrap")

    # 3. Add UIRouter.register and ActionRegistry.registerCallback at end of file
    registration = '\n-- Register with UIRouter for modal exclusivity and Escape handling\nUIRouter.register("' + action_id + '", nil, function() shell.close() end)\n\n-- Register callback with ActionRegistry for Pea Wheel dispatch\nActionRegistry.registerCallback("' + action_id + '", toggle)\n'
    if 'ActionRegistry.registerCallback("' + action_id + '"' not in content:
        content = content.rstrip() + "\n" + registration
        print(f"  [{action_id}] Added UIRouter.register and ActionRegistry.registerCallback")
    else:
        print(f"  [{action_id}] Registrations already present")

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  [{action_id}] Saved: {filepath}")

print("\nAll panel scripts updated successfully!")
