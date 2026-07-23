# Handoff Report: Companion System & Marketplace Synchronization

## 1. Observation
- `src/shared/ConfigurationFiles/MarketplaceConfig.lua`:
  - `products`: Maps ID `1111111101` -> `zundacat`, `1111111102` -> `zundabunny`, `1111111103` -> `tantanmon`, `1111111104` -> `Premium Ramen` (recipe).
  - `companionDevProductIds`: Maps `cardamon = 0`, `antimon = 0`, `sakuradamon = 0`, `zundacat = 1111111101`, `zundabunny = 1111111102`, `tantanmon = 1111111103`.
  - `storeDisplay.companions`: Maps ID `1111111101` -> `Cardamon`, `1111111102` -> `Antimon`, `1111111103` -> `Sakuradamon`, `1111111104` -> `Tantanmon`.
- `src/shared/ConfigurationFiles/CompanionConfig.lua`:
  - `cardamon`, `antimon`, `sakuradamon`, `tantanmon` have `free = false`, `price = 1000`, `robux = 1000`.
- `src/server/CompanionShopServer.server.lua`:
  - Line 68: `local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }` (hardcodes `tantanmon` as owned by default).
- `src/server/Services/MarketplaceService.lua`:
  - Handles `ProcessReceipt` by checking `MarketplaceConfig.products[productId]`.

## 2. Logic Chain
1. In `MarketplaceConfig.lua`, ID `1111111101` is assigned to `zundacat` in `products`, but to `Cardamon` in `storeDisplay`.
2. Purchasing ID `1111111104` via `storeDisplay` triggers `MarketplaceService.processReceipt`, which looks up `products[1111111104]` (`Premium Ramen Recipe`). It executes the recipe granting branch (`data.recipes_unlocked`) instead of unlocking companion `tantanmon`.
3. `cardamon`, `antimon`, and `sakuradamon` do not exist in `MarketplaceConfig.products` at all and have `0` as product IDs in `companionDevProductIds`.
4. `tantanmon` is hardcoded as default owned in `CompanionShopServer.server.lua`, bypassing Robux store purchasing entirely.

## 3. Caveats
- Actual Roblox Developer Product IDs in Roblox Studio dashboard are placeholder integers (`11111111xx`). Real DevProduct IDs generated in Roblox Creator Dashboard must replace these placeholders before public deployment.
- `MarketplaceConfig.enabled` is currently `false` by default to prevent accidental transactions before live release.

## 4. Conclusion
- `MarketplaceConfig.lua` must be updated to assign distinct IDs (`1111111110` - `1111111113`) to the four premium companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`), synchronizing `products`, `companionDevProductIds`, and `storeDisplay.companions`.
- `CompanionShopServer.server.lua` must be updated to remove `tantanmon` from default owned list.
- `CompanionConfig.lua` is properly configured with 1,000 Robux pricing and active buff stats for all 4 premium companions.

## 5. Verification Method
- Code inspection of `MarketplaceConfig.lua` to ensure every companion key matches across `products`, `companionDevProductIds`, and `storeDisplay.companions`.
- Verification that `MarketplaceService.processReceipt` correctly handles `type == "companion"` with `prod.key` for all 4 premium companions.
