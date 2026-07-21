# Original User Request

## 2026-07-21T17:52:18Z

Zundamon's Kitchen V2 is a cooperative Roblox life-sim. The project goal is to methodically audit, refactor, and fully integrate the core gameplay loop (Harvest → Cook → Serve → Reward → Repeat) into a working, bug-free state synced via Rojo 7.7.0.

Working directory: g:\Zundamons-kItchen-V2

Integrity mode: development

## Requirements

### R1. Harvesting & Resource Node System
Players can equip tools (Axe, Pickaxe, Sickle), swing to deal damage to resource nodes, see visual progress bars and particle effects, receive item drops, and have items saved in PlayerDataService.

### R2. Cooking & Rhythm Minigame System
Crafting recipes initiates a server-validated rhythm minigame (CookingValidationSystem). Accuracy grades (perfect, great, ok) determine quality bonuses, gold rewards, chef XP, and inventory dish delivery.

### R3. Guest Serving & Economy Loop
Customer NPCs spawn in workspace.Guests, display requested recipes and gold rewards, accept dishes from player inventory, trigger despawning, and award gold and chef XP via RewardCore.

### R4. Real-time HUD Synchronization
Player stats (Gold, Chef XP, Level, Combo, inventory notifications) update dynamically in the HUD UI (ZundaHUD, ChefPill, XPBar, ComboMeter) in real-time.

## Acceptance Criteria

### Functional Verification
- [ ] Swings with tools hit nodes, play progress UI/particles, drop items, and update inventory.
- [ ] Rhythm cooking minigame accurately tracks note hits, sends server validation, and grants cooked dishes.
- [ ] Guests accept ordered dishes, deduct items from inventory, pay gold, and despawn smoothly.
- [ ] HUD displays live gold, XP progress, and combo updates without requiring manual GUI refreshes.
- [ ] No script.Parent errors or missing package crashes appear in the Studio Output window.
