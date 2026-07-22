import os
import glob
import re

client_dir = r'g:\Zundamons-kItchen-V2\src\client'
files = glob.glob(os.path.join(client_dir, '**', '*.lua'), recursive=True)

print("=== MODAL & DIALOGUE PANEL STARTUP VISIBILITY AUDIT ===")

# Keywords for modal / dialogue panels:
# Frame/Panel creation and initial Visible state

for f in sorted(files):
    rel = os.path.relpath(f, client_dir)
    with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
        lines = fp.readlines()
    content = ''.join(lines)
    
    # Identify UI panels, frames, dialogs, ScreenGuis created or managed
    panel_creations = []
    for i, line in enumerate(lines):
        line_str = line.strip()
        # Look for Frame creation or panel variables
        if 'Instance.new("Frame"' in line_str or 'Instance.new("ScrollingFrame"' in line_str or 'createScreenGui' in line_str or 'ScreenGui' in line_str:
            panel_creations.append((i+1, line_str))
            
    visible_assignments = []
    for i, line in enumerate(lines):
        line_str = line.strip()
        if '.Visible =' in line_str or '.Visible=' in line_str or '.Enabled =' in line_str or '.Enabled=' in line_str:
            visible_assignments.append((i+1, line_str))
            
    # Check if this script defines modal panels and how their initial visibility is configured
    if any(k in rel.lower() for k in ['vncontroller', 'shop', 'compendium', 'crafting', 'checklist', 'serving', 'inventory', 'keybinds', 'materials', 'wardrobe', 'pouch', 'promocode', 'quest', 'settings', 'teleport', 'tutorial', 'starterpack', 'zundaroom', 'adminconsole', 'devconsole']):
        print(f"\n--- Script: {rel} ---")
        print("  Startup Visibility assignments:")
        for line_num, text in visible_assignments[:8]:
            print(f"    Line {line_num}: {text}")
