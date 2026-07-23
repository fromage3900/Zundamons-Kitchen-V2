# Companion System & Shop Synchronization Audit Report (Milestone 1)

## Executive Summary
This report audits the companion catalog, initial player data state, server-side ownership query handlers, and shop client scripts for Zundamon's Kitchen V2. While `CompanionConfig.lua` correctly marks free (`zundapal`, `dog`, `parrot`, `cat`, `ankomon`) and premium (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`) companions, critical synchronization bugs exist in `CompanionShopServer.server.lua`, `StoreScript.client.lua`, and `MarketplaceConfig.lua` where `tantanmon` (1,000 Robux premium) is mistakenly granted free, `ankomon` (free) is omitted from server ownership queries, and legacy companions are hardcoded.

---

## 1. Companion Catalog Audit (`CompanionConfig.lua`)
**File Path**: `src/shared/ConfigurationFiles/CompanionConfig.lua`

`CompanionConfig.lua` defines the canonical list of companions in `CompanionConfig.companions`:

| Companion Key | Display Name | Category | `free` | `price` | `robux` | Buff Description |
|---|---|---|---|---|---|---|
| `zundapal` | Zundapal | Starter | `true` | `0` | - | None (Starter) |
| `dog` | Dog | Free Pet | `true` | `0` | - | None |
| `parrot` | Parrot | Free Pet | `true` | `0` | - | None |
| `cat` | Cat | Free Pet | `true` | `0` | - | None |
| `ankomon` | Ankomon | Free Bean | `true` | `0` | - | +15% gold from serving guests |
| `cardamon` | Cardamon | Premium | `false` | `1000` | `1000` | +30% wider perfect cooking window |
| `antimon` | Antimon | Premium | `false` | `1000` | `1000` | +20% chance of extra drop on gather |
| `sakuradamon` | Sakuradamon | Premium | `false` | `1000` | `1000` | +25% XP from crafting & serving |
| `tantanmon` | Tantanmon | Premium | `false` | `1000` | `1000` | +20% move speed & cook speed |

### Evaluation:
- **Free Companions (5)**: `zundapal`, `dog`, `parrot`, `cat`, `ankomon`. (All 4 requested free companions `parrot`, `dog`, `cat`, `ankomon` plus `zundapal` are defined as `free = true`).
- **Premium Companions (4)**: `cardamon`, `antimon`, `sakuradamon`, `tantanmon`. (All 4 are configured with `free = false`, `price = 1000`, `robux = 1000`).

---

## 2. Server Player Data Initialization Audit

### A. DataSchema & `PlayerDataService.lua`
**File Path**: `src/server/Services/PlayerDataService.lua` (lines 245-304)

`PlayerDataService.createDefaultData()` initializes profile data for new players:
```lua
createDefaultData = function(): { [string]: any }
    local data = {
        ...
        companions_set = {},
        ...
    }
    return data
end
```
- Persistent companion ownership is tracked dynamically via keys formatted as `companion_owned_<compType> = true` (e.g., `companion_owned_cardamon = true`).
- Free companions do NOT require a persistent data key because server checks (`CompanionManager.server.lua` line 369) inspect `def.free == true` directly.

### B. `GetOwnedCompanions` RemoteFunction Handler
**File Path**: `src/server/CompanionShopServer.server.lua` (lines 67-82)

```lua
GetOwnedCompanions.OnServerInvoke = function(player)
	local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }
	local data = PlayerDataService.get(player)
	if data then
		for k, v in pairs(data) do
			if v == true then
				local pre, name = string.match(k, "(companion_owned_)(.+)")
				if pre then
					owned[name] = true
				end
			end
		end
		owned.__active = data.active_companion or "zundapal"
	end
	return owned
end
```

### Critical Flaws Discovered in `CompanionShopServer.server.lua`:
1. **`tantanmon` is falsely hardcoded as owned (`tantanmon = true`)**: `tantanmon` is a 1,000 Robux premium companion in `CompanionConfig.lua`, but `GetOwnedCompanions` forces `owned["tantanmon"] = true`. This grants `tantanmon` to every player for free upon joining!
2. **`ankomon` is missing from default owned list**: `ankomon` is a free companion in `CompanionConfig.lua`, but is missing from line 68 in `GetOwnedCompanions`.
3. **Legacy/non-existent keys included**: `zundamon`, `zundacat`, and `zundabunny` are hardcoded in line 68, despite not being in `CompanionConfig.lua`.

---

## 3. Client Shop & Marketplace Audit

### A. `CompanionShopScript.client.lua`
**File Path**: `src/client/CompanionShopScript.client.lua` (lines 196)
```lua
local TAB_ORDER = { "zundapal", "zundamon", "zundacat", "zundabunny", "tantanmon", "dog", "parrot", "cat", "ankomon", "cardamon", "antimon", "sakuradamon" }
```
- `TAB_ORDER` includes legacy keys (`zundamon`, `zundacat`, `zundabunny`) and places `tantanmon` early in the tab list instead of grouping all 4 premium companions at the end.
- Recommended `TAB_ORDER`: `{ "zundapal", "dog", "parrot", "cat", "ankomon", "cardamon", "antimon", "sakuradamon", "tantanmon" }`.

### B. `StoreScript.client.lua`
**File Path**: `src/client/StoreScript.client.lua` (lines 178-187)
```lua
local FREE_COMPANIONS = {
    { key="zundapal",   emoji="🫛", name="Zundapal",   flavor="Your Zundamon companion from the Downloads." },
    { key="zundamon",   emoji="🍡", name="Zundamon",   flavor="The original. A loyal pea spirit." },
    { key="zundacat",   emoji="🐱", name="ZundaCat",   flavor="A curious cat-shaped friend." },
    { key="zundabunny", emoji="🐰", name="ZundaBunny", flavor="Hops alongside with twinkling ears." },
    { key="tantanmon",  emoji="🌶️", name="TantanMon",  flavor="Spicy little firework." },
    { key="dog",        emoji="🐕", name="Dog",        flavor="A faithful furry friend." },
    { key="parrot",     emoji="🦜", name="Parrot",     flavor="A colourful chatterbox." },
    { key="cat",        emoji="🐱", name="Cat",        flavor="A purring little menace." },
}
```
- **Bug**: `StoreScript.client.lua` lists `tantanmon` under `FREE_COMPANIONS` and omits `ankomon`.

### C. `MarketplaceConfig.lua`
**File Path**: `src/shared/ConfigurationFiles/MarketplaceConfig.lua` (lines 12-33, 36-42)
- `MarketplaceConfig.products` maps IDs `1111111101` and `1111111102` to `zundacat` and `zundabunny` (legacy).
- `MarketplaceConfig.companionDevProductIds` maps `ankomon = 0`, `cardamon = 0`, `antimon = 0`, `sakuradamon = 0`, `zundacat = 1111111101`, `zundabunny = 1111111102`, `tantanmon = 1111111103`.
- `MarketplaceConfig.storeDisplay.companions` displays:
  - `Cardamon` (1000 Robux, id 1111111101)
  - `Antimon` (1000 Robux, id 1111111102)
  - `Sakuradamon` (1000 Robux, id 1111111103)
  - `Tantanmon` (1000 Robux, id 1111111104)
- **Mismatch**: `products` and `companionDevProductIds` conflict with `storeDisplay.companions`! Purchasing Cardamon (1111111101) would grant `zundacat` instead of `cardamon`.

---

## 4. Remediation Plan & Proposed Code Changes

### Proposed Modification 1: `src/server/CompanionShopServer.server.lua`
Dynamically build `owned` from `CompanionConfig.companions` where `free == true`:

```lua
GetOwnedCompanions.OnServerInvoke = function(player)
	local owned = {}
	for k, def in pairs(CompanionConfig.companions) do
		if def.free then
			owned[k] = true
		end
	end
	local data = PlayerDataService.get(player)
	if data then
		for k, v in pairs(data) do
			if v == true then
				local pre, name = string.match(k, "(companion_owned_)(.+)")
				if pre then
					owned[name] = true
				end
			end
		end
		owned.__active = data.active_companion or "zundapal"
	end
	return owned
end
```

### Proposed Modification 2: `src/shared/ConfigurationFiles/MarketplaceConfig.lua`
Align `products`, `companionDevProductIds`, and `storeDisplay`:

```lua
MarketplaceConfig.products = {
	[1111111101] = { type = "companion", key = "cardamon", name = "Cardamon Companion" },
	[1111111102] = { type = "companion", key = "antimon", name = "Antimon Companion" },
	[1111111103] = { type = "companion", key = "sakuradamon", name = "Sakuradamon Companion" },
	[1111111104] = { type = "companion", key = "tantanmon", name = "Tantanmon Companion" },
	...
}

MarketplaceConfig.companionDevProductIds = {
	cardamon = 1111111101,
	antimon = 1111111102,
	sakuradamon = 1111111103,
	tantanmon = 1111111104,
}
```

### Proposed Modification 3: `src/client/CompanionShopScript.client.lua`
Update `TAB_ORDER`:
```lua
local TAB_ORDER = { "zundapal", "dog", "parrot", "cat", "ankomon", "cardamon", "antimon", "sakuradamon", "tantanmon" }
```

### Proposed Modification 4: `src/client/StoreScript.client.lua`
Update `FREE_COMPANIONS`:
```lua
local FREE_COMPANIONS = {
    { key="zundapal", emoji="🫛", name="Zundapal", flavor="Your Zundamon spirit companion." },
    { key="dog",      emoji="🐕", name="Dog",      flavor="A faithful furry friend." },
    { key="parrot",   emoji="🦜", name="Parrot",   flavor="A colourful chatterbox." },
    { key="cat",      emoji="🐱", name="Cat",      flavor="A purring little menace." },
    { key="ankomon",  emoji="🫘", name="Ankomon",  flavor="A red bean spirit. Sweetens every payday." },
}
```
