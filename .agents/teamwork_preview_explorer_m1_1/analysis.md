# Companion System & Companion Shop Synchronization Analysis — Milestone 1

## Executive Summary
This investigation analyzed `src/shared/ConfigurationFiles/CompanionConfig.lua`, `src/shared/ConfigurationFiles/MarketplaceConfig.lua`, and all related client/server codebase references for the companion ecosystem in Zundamon's Kitchen V2.

The analysis confirms:
1. All **4 free companions** (`parrot`, `dog`, `cat`, `ankomon`) plus default `zundapal` are correctly defined with `free = true` and `price = 0`.
2. All **4 premium companions** (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`) are correctly configured in `CompanionConfig.lua` with `free = false`, `price = 1000`, and `robux = 1000`.
3. A **critical misalignment** exists in `src/shared/ConfigurationFiles/MarketplaceConfig.lua`, where product IDs, companion keys, and recipe IDs conflict with `storeDisplay.companions` and missing product mappings.
4. Ancillary scripts (`CompanionShopServer.server.lua`, `CompanionShopScript.client.lua`) contain legacy keys (`zundamon`, `zundacat`, `zundabunny`) and incorrect ownership defaults (`ankomon` missing from free defaults, `tantanmon` incorrectly marked free by default).

---

## 1. Companion Catalog Analysis (`CompanionConfig.lua`)

`CompanionConfig.lua` serves as the single source of truth for companion metadata and gameplay buffs. The current catalog contains 9 companions:

| Companion ID | Display Name | Type | Price (Robux) | Buff Stat | Buff Magnitude | Buff Description |
|---|---|---|---|---|---|---|
| `zundapal` | Zundapal | Free | 0 | None | N/A | Default starter companion |
| `dog` | Dog | Free | 0 | None | N/A | Faithful furry friend |
| `parrot` | Parrot | Free | 0 | None | N/A | Colourful chatterbox |
| `cat` | Cat | Free | 0 | None | N/A | Purring little menace |
| `ankomon` | Ankomon | Free | 0 | `gold` | +15% (0.15) | +15% gold from serving guests |
| `cardamon` | Cardamon | Premium | 1,000 | `perfect_window` | +30% (0.30) | +30% wider perfect cooking window |
| `antimon` | Antimon | Premium | 1,000 | `extra_drop` | +20% (0.20) | +20% chance of extra drop on gather |
| `sakuradamon` | Sakuradamon | Premium | 1,000 | `xp` | +25% (0.25) | +25% XP from crafting & serving |
| `tantanmon` | Tantanmon | Premium | 1,000 | `speed` | +20% (0.20) | +20% move speed & cook speed |

### Verification Findings:
- **Free Companions (`parrot`, `dog`, `cat`, `ankomon`)**: All 4 companions are explicitly set to `free = true` and `price = 0`. `ankomon` carries a valid gameplay buff (+15% gold).
- **Premium Companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`)**: All 4 companions are set to `free = false`, `price = 1000`, and `robux = 1000`. Each companion provides a unique, non-overlapping buff.

---

## 2. Marketplace & DevProduct Cross-Reference (`MarketplaceConfig.lua`)

`MarketplaceConfig.lua` handles DevProduct resolution for Robux purchases in `RobuxStoreServer` and `MarketplaceService`.

### Current Inconsistencies & Issues Found:

1. **`MarketplaceConfig.products` Conflict**:
   - `[1111111101]` maps to `"zundacat"` (Obsolete key not in `CompanionConfig`).
   - `[1111111102]` maps to `"zundabunny"` (Obsolete key not in `CompanionConfig`).
   - `[1111111103]` maps to `"tantanmon"`.
   - `[1111111104]` maps to `"recipe"` / `"Premium Ramen"`.

2. **`MarketplaceConfig.companionDevProductIds` Conflict**:
   - `cardamon = 0`, `antimon = 0`, `sakuradamon = 0` (Unconfigured!). Purchases fail on server when requested.
   - `zundacat = 1111111101`, `zundabunny = 1111111102` (Obsolete keys).

3. **`MarketplaceConfig.storeDisplay.companions` ID Collision**:
   - `cardamon` is assigned ID `1111111101` in `storeDisplay`, but product `1111111101` grants `zundacat`!
   - `antimon` is assigned ID `1111111102` in `storeDisplay`, but product `1111111102` grants `zundabunny`!
   - `sakuradamon` is assigned ID `1111111103` in `storeDisplay`, but product `1111111103` grants `tantanmon`!
   - `tantanmon` is assigned ID `1111111104` in `storeDisplay`, but product `1111111104` grants `Premium Ramen Recipe`!

### Recommended Synchronization Fix for `MarketplaceConfig.lua`:
- Re-index `products` so IDs `1111111101` through `1111111104` match the 4 premium companions:
  - `1111111101` -> `cardamon` ("Cardamon Companion")
  - `1111111102` -> `antimon` ("Antimon Companion")
  - `1111111103` -> `sakuradamon` ("Sakuradamon Companion")
  - `1111111104` -> `tantanmon` ("Tantanmon Companion")
- Re-index recipes to IDs `1111111105`..`1111111107` and accessories to `1111111108`..`1111111110`.
- Update `companionDevProductIds` to map `cardamon`, `antimon`, `sakuradamon`, `tantanmon` to IDs `1111111101`..`1111111104`.
- Synchronize `storeDisplay.companions` with matching DevProduct IDs, keys, descriptions, and 1000 Robux price tags.

---

## 3. Codebase Companion Reference Audit

We searched all references to companion IDs across the client and server codebases:

### Files & Findings:

1. **`src/server/CompanionShopServer.server.lua`**:
   - `GetOwnedCompanions.OnServerInvoke` hardcodes default owned companions:
     `local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }`
   - **Bug**: `ankomon` (which is `free = true`) is missing from the default owned table!
   - **Bug**: `tantanmon` (which is premium, 1,000 Robux) is hardcoded as `true` (owned for free)!
   - **Bug**: Contains obsolete keys `zundamon`, `zundacat`, `zundabunny`.
   - **Fix**: Change default owned table to:
     `local owned = { zundapal = true, dog = true, parrot = true, cat = true, ankomon = true }`

2. **`src/client/CompanionShopScript.client.lua`**:
   - Line 196: `TAB_ORDER` contains obsolete keys:
     `local TAB_ORDER = { "zundapal", "zundamon", "zundacat", "zundabunny", "tantanmon", "dog", "parrot", "cat", "ankomon", "cardamon", "antimon", "sakuradamon" }`
   - **Fix**: Update `TAB_ORDER` to match the canonical 9 companions:
     `local TAB_ORDER = { "zundapal", "parrot", "dog", "cat", "ankomon", "cardamon", "antimon", "sakuradamon", "tantanmon" }`

3. **`src/server/Services/MarketplaceService.lua`**:
   - ProcessReceipt handles companion unlocking via `data["companion_owned_" .. prod.key] = true` and fires `CompanionOwnedSync`.
   - Functionally intact once `MarketplaceConfig.lua` is fixed.

4. **Gameplay Buff Handlers (`CookingService.lua`, `ZundaGatherServer.server.lua`, `RewardCore.lua`, `CompanionBuffServer.server.lua`)**:
   - Lookups access `CompanionConfig.companions[active_companion].buff`.
   - Compatible with all 4 premium buffs (`perfect_window`, `extra_drop`, `xp`, `speed`) and free buff (`gold`).

5. **`src/shared/ConfigurationFiles/CompanionVisualConfig.lua`**:
   - Includes visual mapping (asset IDs and base prefabs) for all 8 companions plus `zundapal`. Intact and ready.

---

## 4. Recommended Configuration Diffs

### Diff 1: `src/shared/ConfigurationFiles/MarketplaceConfig.lua`

```diff
--- a/src/shared/ConfigurationFiles/MarketplaceConfig.lua
+++ b/src/shared/ConfigurationFiles/MarketplaceConfig.lua
@@ -12,25 +12,26 @@ MarketplaceConfig.enabled = false
 
 -- Server receipt catalog: [productId] = { type, key, name }
 MarketplaceConfig.products = {
-	[1111111101] = { type = "companion", key = "zundacat", name = "ZundaCat Companion" },
-	[1111111102] = { type = "companion", key = "zundabunny", name = "ZundaBunny Companion" },
-	[1111111103] = { type = "companion", key = "tantanmon", name = "TantanMon Companion" },
-	[1111111104] = { type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" },
-	[1111111105] = { type = "recipe", key = "Party Cake", name = "Party Cake Recipe" },
-	[1111111106] = { type = "recipe", key = "Truffle Soup", name = "Truffle Soup Recipe" },
-	[1111111107] = { type = "accessory", key = "crown", name = "Gold Crown" },
-	[1111111108] = { type = "accessory", key = "bow", name = "Pink Bow" },
-	[1111111109] = { type = "accessory", key = "chefhat", name = "Chef Hat" },
+	[1111111101] = { type = "companion", key = "cardamon", name = "Cardamon Companion" },
+	[1111111102] = { type = "companion", key = "antimon", name = "Antimon Companion" },
+	[1111111103] = { type = "companion", key = "sakuradamon", name = "Sakuradamon Companion" },
+	[1111111104] = { type = "companion", key = "tantanmon", name = "Tantanmon Companion" },
+	[1111111105] = { type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" },
+	[1111111106] = { type = "recipe", key = "Party Cake", name = "Party Cake Recipe" },
+	[1111111107] = { type = "recipe", key = "Truffle Soup", name = "Truffle Soup Recipe" },
+	[1111111108] = { type = "accessory", key = "crown", name = "Gold Crown" },
+	[1111111109] = { type = "accessory", key = "bow", name = "Pink Bow" },
+	[1111111110] = { type = "accessory", key = "chefhat", name = "Chef Hat" },
 }
 
 -- Premium companions in CompanionShop (0 = not configured yet)
 MarketplaceConfig.companionDevProductIds = {
 	ankomon = 0,
-	cardamon = 0,
-	antimon = 0,
-	sakuradamon = 0,
-	zundacat = 1111111101,
-	zundabunny = 1111111102,
-	tantanmon = 1111111103,
+	cardamon = 1111111101,
+	antimon = 1111111102,
+	sakuradamon = 1111111103,
+	tantanmon = 1111111104,
 }
 
 -- Client StoreScript display (derived from products; edit copy here)
 MarketplaceConfig.storeDisplay = {
 	companions = {
 		{ id = 1111111101, name = "Cardamon", emoji = "🍋", desc = "+30% wider perfect cooking window", robux = 1000, key = "cardamon" },
 		{ id = 1111111102, name = "Antimon", emoji = "🌿", desc = "+20% extra gather drop chance", robux = 1000, key = "antimon" },
 		{ id = 1111111103, name = "Sakuradamon", emoji = "🌸", desc = "+25% XP bonus from cooking & serving", robux = 1000, key = "sakuradamon" },
 		{ id = 1111111104, name = "Tantanmon", emoji = "🌶️", desc = "+20% speed & spicy burst", robux = 1000, key = "tantanmon" },
 	},
 	recipes = {
-		{ id = 1111111104, name = "Premium Ramen", emoji = "🍜", desc = "Exclusive ramen recipe", robux = 60 },
-		{ id = 1111111105, name = "Party Cake", emoji = "🎂", desc = "Fancy celebration cake", robux = 60 },
-		{ id = 1111111106, name = "Truffle Soup", emoji = "🍲", desc = "Ultra-rare truffle recipe", robux = 80 },
+		{ id = 1111111105, name = "Premium Ramen", emoji = "🍜", desc = "Exclusive ramen recipe", robux = 60 },
+		{ id = 1111111106, name = "Party Cake", emoji = "🎂", desc = "Fancy celebration cake", robux = 60 },
+		{ id = 1111111107, name = "Truffle Soup", emoji = "🍲", desc = "Ultra-rare truffle recipe", robux = 80 },
 	},
 	accessories = {
-		{ id = 1111111107, name = "Gold Crown", emoji = "👑", desc = "Wear royalty on your head", robux = 40 },
-		{ id = 1111111108, name = "Pink Bow", emoji = "🎀", desc = "Cute bow accessory", robux = 40 },
-		{ id = 1111111109, name = "Chef Hat", emoji = "🍽️", desc = "Professional chef headwear", robux = 50 },
+		{ id = 1111111108, name = "Gold Crown", emoji = "👑", desc = "Wear royalty on your head", robux = 40 },
+		{ id = 1111111109, name = "Pink Bow", emoji = "🎀", desc = "Cute bow accessory", robux = 40 },
+		{ id = 1111111110, name = "Chef Hat", emoji = "🍽️", desc = "Professional chef headwear", robux = 50 },
 	},
 }
```

### Diff 2: `src/server/CompanionShopServer.server.lua`

```diff
--- a/src/server/CompanionShopServer.server.lua
+++ b/src/server/CompanionShopServer.server.lua
@@ -67,5 +67,5 @@ GetCompanionCatalog.OnServerInvoke = function(player)
 GetOwnedCompanions.OnServerInvoke = function(player)
-	local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }
+	local owned = { zundapal = true, dog = true, parrot = true, cat = true, ankomon = true }
 	local data = PlayerDataService.get(player)
```

### Diff 3: `src/client/CompanionShopScript.client.lua`

```diff
--- a/src/client/CompanionShopScript.client.lua
+++ b/src/client/CompanionShopScript.client.lua
@@ -196,1 +196,1 @@
-local TAB_ORDER = { "zundapal", "zundamon", "zundacat", "zundabunny", "tantanmon", "dog", "parrot", "cat", "ankomon", "cardamon", "antimon", "sakuradamon" }
+local TAB_ORDER = { "zundapal", "parrot", "dog", "cat", "ankomon", "cardamon", "antimon", "sakuradamon", "tantanmon" }
```

---

## 5. Conclusion & Next Steps for Implementation
1. Apply the configuration fixes to `MarketplaceConfig.lua`.
2. Apply the default ownership fix to `CompanionShopServer.server.lua` to ensure free companions (`ankomon`) are owned by default and premium companions (`tantanmon`) are not accidentally granted for free.
3. Update `TAB_ORDER` in `CompanionShopScript.client.lua`.
4. Test companion shop opening, catalog fetching, prompt purchasing, and companion equipping in Roblox Studio playtest.
