# Handoff Report — Milestone 1 Companion System Investigation

## 1. Observation

### CompanionConfig.lua (`src/shared/ConfigurationFiles/CompanionConfig.lua`)
- `CompanionConfig.companions` defines 9 companions:
  - Free (`free = true`, `price = 0`): `zundapal`, `dog`, `parrot`, `cat`, `ankomon`.
  - Premium (`free = false`, `price = 1000`, `robux = 1000`): `cardamon`, `antimon`, `sakuradamon`, `tantanmon`.
- Buffs defined:
  - `ankomon`: `{ stat = "gold", magnitude = 0.15, description = "+15% gold from serving guests" }`
  - `cardamon`: `{ stat = "perfect_window", magnitude = 0.30, description = "+30% wider perfect cooking window" }`
  - `antimon`: `{ stat = "extra_drop", magnitude = 0.20, description = "+20% chance of extra drop on gather" }`
  - `sakuradamon`: `{ stat = "xp", magnitude = 0.25, description = "+25% XP from crafting & serving" }`
  - `tantanmon`: `{ stat = "speed", magnitude = 0.20, description = "+20% move speed & cook speed" }`

### MarketplaceConfig.lua (`src/shared/ConfigurationFiles/MarketplaceConfig.lua`)
- `MarketplaceConfig.products` lines 13-16:
  - `[1111111101] = { type = "companion", key = "zundacat", name = "ZundaCat Companion" }`
  - `[1111111102] = { type = "companion", key = "zundabunny", name = "ZundaBunny Companion" }`
  - `[1111111103] = { type = "companion", key = "tantanmon", name = "TantanMon Companion" }`
  - `[1111111104] = { type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" }`
- `MarketplaceConfig.companionDevProductIds` lines 26-32:
  - `cardamon = 0`, `antimon = 0`, `sakuradamon = 0` (unconfigured!).
  - `zundacat = 1111111101`, `zundabunny = 1111111102` (obsolete keys).
- `MarketplaceConfig.storeDisplay.companions` lines 38-41:
  - ID `1111111101` mapped to `cardamon`, ID `1111111102` mapped to `antimon`, ID `1111111103` mapped to `sakuradamon`, ID `1111111104` mapped to `tantanmon`.

### Server & Client Companion Scripts
- `src/server/CompanionShopServer.server.lua` line 68: `GetOwnedCompanions.OnServerInvoke` hardcodes:
  `local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }`
  `ankomon` is missing; `tantanmon` is hardcoded as free (`true`).
- `src/client/CompanionShopScript.client.lua` line 196: `TAB_ORDER` includes `zundamon`, `zundacat`, `zundabunny`.

## 2. Logic Chain
1. `CompanionConfig.lua` is the canonical catalog. All 4 free (`parrot`, `dog`, `cat`, `ankomon`) and 4 premium (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`) companions are correctly configured there with exact price tags (0 vs 1,000 Robux) and unique buffs.
2. In `MarketplaceConfig.lua`, `products` maps `1111111101`..`1111111103` to obsolete companion keys (`zundacat`, `zundabunny`) and `1111111104` to a recipe. However, `storeDisplay.companions` maps `1111111101`..`1111111104` to `cardamon`, `antimon`, `sakuradamon`, `tantanmon`. Therefore, a purchase requested from `storeDisplay` or `CompanionShopServer` resolves to the wrong product or fails because `companionDevProductIds` has 0 for `cardamon`, `antimon`, `sakuradamon`.
3. Re-aligning `MarketplaceConfig.products`, `companionDevProductIds`, and `storeDisplay.companions` to use clean IDs `1111111101`..`1111111104` for the 4 premium companions resolves all DevProduct purchase mismatches.
4. Correcting `GetOwnedCompanions` in `CompanionShopServer.server.lua` ensures `ankomon` is owned by default (free) and `tantanmon` requires purchase (premium).
5. Updating `TAB_ORDER` in `CompanionShopScript.client.lua` removes obsolete tabs (`zundacat`, `zundabunny`, `zundamon`) and orders the active 9 companions cleanly.

## 3. Caveats
- Real Roblox DevProduct IDs are currently placeholder integers (`1111111101` etc.) since `MarketplaceConfig.enabled` is currently `false` (fail-closed for testing). Real IDs can be substituted when publishing to Roblox.
- Model prefabs for 3D companions rely on `ServerStorage.CompanionVisualCatalog` or `src/shared/Models/Companions` or fallback `zundapalupdate4` MeshParts as defined in `CompanionVisualConfig.lua`.

## 4. Conclusion
The companion catalog in `CompanionConfig.lua` is properly configured. Applying the proposed diffs to `MarketplaceConfig.lua`, `CompanionShopServer.server.lua`, and `CompanionShopScript.client.lua` will complete full end-to-end synchronization for all 8 companions.

## 5. Verification Method
1. Inspect `MarketplaceConfig.lua` to confirm `products[1111111101]` to `[1111111104]` match `companionDevProductIds` and `storeDisplay.companions` for `cardamon`, `antimon`, `sakuradamon`, `tantanmon`.
2. Invoke `GetOwnedCompanions` RF in Studio playtest to verify `ankomon` returns `true` and `cardamon`/`antimon`/`sakuradamon`/`tantanmon` return `nil`/`false` prior to purchase.
3. Verify `CompanionShopGui` tabs render all 9 valid companions without missing icons or obsolete entries.
