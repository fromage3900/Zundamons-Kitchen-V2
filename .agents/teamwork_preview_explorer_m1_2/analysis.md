# Comprehensive Analysis: Companion Purchasing & Marketplace Synchronization

## Executive Summary
This report presents an in-depth investigation of `MarketplaceConfig.lua`, `CompanionConfig.lua`, and the server/client companion purchasing infrastructure (`CompanionShopServer.server.lua`, `MarketplaceService.lua`, `CompanionShopScript.client.lua`).

We identified critical ID collisions and cross-table inconsistencies between `MarketplaceConfig.products`, `MarketplaceConfig.companionDevProductIds`, and `MarketplaceConfig.storeDisplay.companions`. Furthermore, `tantanmon` is currently hardcoded as owned by default in `CompanionShopServer.server.lua`, which bypasses premium Robux purchase checks.

Precise code modification recommendations are provided to align product IDs, structure 1,000 Robux pricing for all 4 premium companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`), and fix server-side ownership defaults.

---

## 1. Direct Observations & Evidence Chain

### Observation 1.1: Product ID Collision in `MarketplaceConfig.lua`
In `src/shared/ConfigurationFiles/MarketplaceConfig.lua`:
- **Receipt Catalog (`products`)**:
  - `[1111111101]` = `{ type = "companion", key = "zundacat", name = "ZundaCat Companion" }`
  - `[1111111102]` = `{ type = "companion", key = "zundabunny", name = "ZundaBunny Companion" }`
  - `[1111111103]` = `{ type = "companion", key = "tantanmon", name = "TantanMon Companion" }`
  - `[1111111104]` = `{ type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" }`
- **Product ID Mapping (`companionDevProductIds`)**:
  - `cardamon = 0`, `antimon = 0`, `sakuradamon = 0` (unassigned)
  - `zundacat = 1111111101`, `zundabunny = 1111111102`, `tantanmon = 1111111103`
- **Store Display (`storeDisplay.companions`)**:
  - `{ id = 1111111101, name = "Cardamon", key = "cardamon", robux = 1000 }`
  - `{ id = 1111111102, name = "Antimon", key = "antimon", robux = 1000 }`
  - `{ id = 1111111103, name = "Sakuradamon", key = "sakuradamon", robux = 1000 }`
  - `{ id = 1111111104, name = "Tantanmon", key = "tantanmon", robux = 1000 }`

**Logic Chain**:
- Product ID `1111111101` represents `zundacat` in `products`, but `cardamon` in `storeDisplay`.
- Product ID `1111111104` represents `Premium Ramen Recipe` in `products`, but `Tantanmon` in `storeDisplay`.
- If a client purchases ID `1111111104` via `storeDisplay`, `MarketplaceService.processReceipt` checks `products[1111111104]`, which executes `prod.type == "recipe"` and unlocks `Premium Ramen` instead of `tantanmon`.
- `cardamon`, `antimon`, and `sakuradamon` do not exist in `MarketplaceConfig.products`.

### Observation 1.2: Premium Companion Configuration in `CompanionConfig.lua`
In `src/shared/ConfigurationFiles/CompanionConfig.lua`:
- Premium companions:
  - `cardamon`: `free = false`, `price = 1000`, `robux = 1000`, buff: `perfect_window` (0.30)
  - `antimon`: `free = false`, `price = 1000`, `robux = 1000`, buff: `extra_drop` (0.20)
  - `sakuradamon`: `free = false`, `price = 1000`, `robux = 1000`, buff: `xp` (0.25)
  - `tantanmon`: `free = false`, `price = 1000`, `robux = 1000`, buff: `speed` (0.20)
- Free companions: `zundapal`, `dog`, `parrot`, `cat`, `ankomon` (all `free = true`, `price = 0`).

### Observation 1.3: Server Ownership Hardcoding in `CompanionShopServer.server.lua`
In `src/server/CompanionShopServer.server.lua` line 68:
```lua
local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }
```
**Logic Chain**:
- `tantanmon` is explicitly marked as owned by default in `GetOwnedCompanions`.
- Because `GetOwnedCompanions` returns `tantanmon = true`, players are treated as owning `tantanmon` automatically, disabling the purchase prompt and enabling equipment without payment.

---

## 2. Recommended Structure for `MarketplaceConfig.lua`

To eliminate ID collisions and properly configure 1,000 Robux pricing for all premium companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`), assign unique product IDs in `MarketplaceConfig.lua`:

### 2.1 Dedicated ID Scheme
- Companion Product IDs: `1111111110` – `1111111113`
  - `1111111110`: Cardamon Companion (1,000 Robux)
  - `1111111111`: Antimon Companion (1,000 Robux)
  - `1111111112`: Sakuradamon Companion (1,000 Robux)
  - `1111111113`: Tantanmon Companion (1,000 Robux)
- Recipe Product IDs: `1111111104` – `1111111106`
- Accessory Product IDs: `1111111107` – `1111111109`

### 2.2 Precise Modification Proposal for `MarketplaceConfig.lua`

```lua
-- MarketplaceConfig.lua

MarketplaceConfig.products = {
	-- Premium Companions (1,000 Robux)
	[1111111110] = { type = "companion", key = "cardamon", name = "Cardamon Companion" },
	[1111111111] = { type = "companion", key = "antimon", name = "Antimon Companion" },
	[1111111112] = { type = "companion", key = "sakuradamon", name = "Sakuradamon Companion" },
	[1111111113] = { type = "companion", key = "tantanmon", name = "TantanMon Companion" },

	-- Recipes
	[1111111104] = { type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" },
	[1111111105] = { type = "recipe", key = "Party Cake", name = "Party Cake Recipe" },
	[1111111106] = { type = "recipe", key = "Truffle Soup", name = "Truffle Soup Recipe" },

	-- Accessories
	[1111111107] = { type = "accessory", key = "crown", name = "Gold Crown" },
	[1111111108] = { type = "accessory", key = "bow", name = "Pink Bow" },
	[1111111109] = { type = "accessory", key = "chefhat", name = "Chef Hat" },
}

MarketplaceConfig.companionDevProductIds = {
	cardamon = 1111111110,
	antimon = 1111111111,
	sakuradamon = 1111111112,
	tantanmon = 1111111113,
	ankomon = 0,
	zundacat = 0,
	zundabunny = 0,
}

MarketplaceConfig.storeDisplay = {
	companions = {
		{ id = 1111111110, name = "Cardamon", emoji = "🍋", desc = "+30% wider perfect cooking window", robux = 1000, key = "cardamon" },
		{ id = 1111111111, name = "Antimon", emoji = "🌿", desc = "+20% extra gather drop chance", robux = 1000, key = "antimon" },
		{ id = 1111111112, name = "Sakuradamon", emoji = "🌸", desc = "+25% XP bonus from cooking & serving", robux = 1000, key = "sakuradamon" },
		{ id = 1111111113, name = "Tantanmon", emoji = "🌶️", desc = "+20% speed & spicy burst", robux = 1000, key = "tantanmon" },
	},
	recipes = {
		{ id = 1111111104, name = "Premium Ramen", emoji = "🍜", desc = "Exclusive ramen recipe", robux = 60 },
		{ id = 1111111105, name = "Party Cake", emoji = "🎂", desc = "Fancy celebration cake", robux = 60 },
		{ id = 1111111106, name = "Truffle Soup", emoji = "🍲", desc = "Ultra-rare truffle recipe", robux = 80 },
	},
	accessories = {
		{ id = 1111111107, name = "Gold Crown", emoji = "👑", desc = "Wear royalty on your head", robux = 40 },
		{ id = 1111111108, name = "Pink Bow", emoji = "🎀", desc = "Cute bow accessory", robux = 40 },
		{ id = 1111111109, name = "Chef Hat", emoji = "🍽️", desc = "Professional chef headwear", robux = 50 },
	},
}
```

---

## 3. Recommended Modifications for Server & Companion Config Files

### 3.1 Fix Server Default Ownership in `CompanionShopServer.server.lua`
In `src/server/CompanionShopServer.server.lua`:
Change line 68 from:
```lua
local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }
```
To:
```lua
local owned = { zundapal = true, zundamon = true, dog = true, parrot = true, cat = true, ankomon = true }
```
*(Removes `tantanmon` from default owned so that it requires purchase or unlocking, consistent with `CompanionConfig.lua`)*

### 3.2 Ensure Price and Robux Fields in `CompanionConfig.lua`
`CompanionConfig.lua` already defines:
- `cardamon`: `free = false, price = 1000, robux = 1000`
- `antimon`: `free = false, price = 1000, robux = 1000`
- `sakuradamon`: `free = false, price = 1000, robux = 1000`
- `tantanmon`: `free = false, price = 1000, robux = 1000`
No structural change is needed in `CompanionConfig.lua`, as prices are already set to 1000.

---

## 4. Verification Method

To verify these fixes:
1. Validate syntax of modified Lua modules (`MarketplaceConfig.lua`, `CompanionShopServer.server.lua`).
2. Verify reverse lookup mapping in `CompanionShopServer.server.lua`:
   `productToComp[pid]` correctly resolves `1111111110` -> `cardamon`, `1111111111` -> `antimon`, `1111111112` -> `sakuradamon`, `1111111113` -> `tantanmon`.
3. Verify receipt processing in `MarketplaceService.lua`:
   Calling `MarketplaceService.processReceipt({ PlayerId = userId, ProductId = 1111111110 })` sets `companion_owned_cardamon = true` in player data and fires `CompanionOwnedSync`.
