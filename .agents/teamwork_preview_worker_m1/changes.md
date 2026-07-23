# Milestone 1: Companion Catalog & Pricing Configuration Changes

## Summary of Changes

### 1. `src/shared/ConfigurationFiles/CompanionConfig.lua`
- Verified catalog structure:
  - Free companions (`free = true`, `price = 0`): `zundapal`, `dog`, `parrot`, `cat`, `ankomon`.
  - Premium companions (`free = false`, `price = 1000`, `robux = 1000`): `cardamon`, `antimon`, `sakuradamon`, `tantanmon`.

### 2. `src/shared/ConfigurationFiles/MarketplaceConfig.lua`
- Updated `MarketplaceConfig.products` table:
  - `[1111111101]` -> `{ type = "companion", key = "cardamon", name = "Cardamon Companion" }`
  - `[1111111102]` -> `{ type = "companion", key = "antimon", name = "Antimon Companion" }`
  - `[1111111103]` -> `{ type = "companion", key = "sakuradamon", name = "Sakuradamon Companion" }`
  - `[1111111104]` -> `{ type = "companion", key = "tantanmon", name = "Tantanmon Companion" }`
  - Reindexed recipe and accessory product IDs to `1111111105`..`1111111110` to avoid ID collisions.
- Updated `MarketplaceConfig.companionDevProductIds`:
  - Mapped canonical premium companion IDs (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`). Removed legacy keys (`zundacat`, `zundabunny`).
- Updated `MarketplaceConfig.storeDisplay`:
  - Updated recipe and accessory display IDs to align with `MarketplaceConfig.products`.

### 3. `src/server/CompanionShopServer.server.lua`
- Refactored `GetOwnedCompanions.OnServerInvoke`:
  - Dynamically populates owned defaults by iterating over `CompanionConfig.companions` where `def.free == true`. This automatically unlocks `zundapal`, `dog`, `parrot`, `cat`, and `ankomon`.
  - Premium companion `tantanmon` is no longer defaulted to owned (locked until purchased).
  - Merges player data `companion_owned_<compType>` flags correctly.

### 4. `src/client/StoreScript.client.lua`
- Updated `PRODUCTS` table recipe and accessory product IDs to match `MarketplaceConfig`.
- Updated `FREE_COMPANIONS` list to include `zundapal`, `dog`, `parrot`, `cat`, and `ankomon`. Removed `tantanmon` and legacy keys (`zundacat`, `zundabunny`).
- Verified `toast.ResetOnSpawn = false` on temporary ScreenGuis created for purchase and success toasts.

### 5. `src/client/CompanionShopScript.client.lua`
- Updated `TAB_ORDER` to canonical companion IDs:
  - Free: `zundapal`, `parrot`, `dog`, `cat`, `ankomon`
  - Premium: `cardamon`, `antimon`, `sakuradamon`, `tantanmon`

---

## Verification Results

1. **Preflight Audit (`python scripts/preflight_audit.py`)**:
   - Rojo Level Preservation Check: PASSED (`$ignoreUnknownInstances = true`)
   - Client UI Decoupling Audit: PASSED (62 scripts checked cleanly)
   - MarketplaceConfig audit: PASSED
   - Overall result: ALL PREFLIGHT AUDITS PASSED cleanly with 0 errors.

2. **Remotes Stress Verification (`python scripts/verify_m1_remotes.py`)**:
   - Verification ran successfully and confirmed remote declarations and wiring.
