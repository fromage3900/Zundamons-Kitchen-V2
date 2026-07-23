# Challenge Report — Milestone 1 Gate Verification

**Overall Assessment**: **REJECTED** (Critical Edge Case Bug Found)

---

## Challenge Summary

| Task | Description | Status | Findings |
|---|---|---|---|
| 1 | Programmatic `CompanionConfig.lua` Verification | **PASS** | All 8 target companions + `zundapal` verified with complete data schemas. |
| 2 | Preflight Audit Execution (`scripts/preflight_audit.py`) | **PASS** | Exit code 0, 0 audit errors. |
| 3 | Edge Case Stress Testing | **FAIL** | Critical mismatch: Fallback key in `CompanionManager.server.lua` and `CompanionHUD.client.lua` is `COMPANIONS.zundamon` instead of `COMPANIONS.zundapal`. Querying an invalid key results in `def = nil` and crashes `buildCompanion` / HUD update. |
| 4 | Marketplace ID Alignment Verification | **PASS** | Exact 1-to-1 alignment across `products`, `companionDevProductIds`, and `storeDisplay.companions`. |

---

## Detailed Findings

### Task 1: `CompanionConfig.lua` Catalog Verification (PASS)
Programmatic inspection of `src/shared/ConfigurationFiles/CompanionConfig.lua` verified that:
- Top-level companion keys present in `CompanionConfig.companions`:
  1. `zundapal` (Free default, emoji: 🫛, displayName: "Zundapal")
  2. `dog` (Free, emoji: 🐕, displayName: "Dog")
  3. `parrot` (Free, emoji: 🦜, displayName: "Parrot")
  4. `cat` (Free, emoji: 🐱, displayName: "Cat")
  5. `ankomon` (Free, emoji: 🫘, displayName: "Ankomon", buff: +15% gold)
  6. `cardamon` (Paid 1000 Robux, emoji: 🍋, displayName: "Cardamon", buff: +30% perfect window)
  7. `antimon` (Paid 1000 Robux, emoji: 🌿, displayName: "Antimon", buff: +20% extra drop)
  8. `sakuradamon` (Paid 1000 Robux, emoji: 🌸, displayName: "Sakuradamon", buff: +25% XP)
  9. `tantanmon` (Paid 1000 Robux, emoji: 🌶️, displayName: "Tantanmon", buff: +20% move/cook speed)
- `CompanionConfig.getCompanion("invalid_key")` safely returns `CompanionConfig.companions.zundapal`.

### Task 2: Preflight Audit Execution (PASS)
Ran `python scripts/preflight_audit.py`. Output confirmed:
- Rojo Level Preservation ($ignoreUnknownInstances = true) passed.
- 62 client scripts audited with 0 decoupling errors.
- `MarketplaceConfig` present and verified.
- Return code: 0.

### Task 3: Edge Case Testing (FAIL - CRITICAL BUGS FOUND)

#### Critical Bug 3A-1: Server-Side Fallback Crash on Invalid Key
- **Location**: `src/server/CompanionManager.server.lua:173`
- **Code**:
  ```lua
  local def = COMPANIONS[compType] or COMPANIONS.zundamon
  ```
- **Issue**: In `CompanionConfig.lua`, the free default companion key is `"zundapal"`. `COMPANIONS.zundamon` does NOT exist and evaluates to `nil`.
- **Attack Scenario**: If `compType` passed to `buildCompanion` is invalid, nil, or corrupted (e.g. from data migration or player state), `def` becomes `nil`. Submitting `nil` to subsequent lines (`def.glow`, `def.sparkleColors`, `def.glowRange`, `def.emoji`, `def.displayName`) causes a server-side Lua runtime crash: `attempt to index nil with 'glow'`.
- **Mitigation Required**: Change fallback in `src/server/CompanionManager.server.lua:173` to `COMPANIONS.zundapal`.

#### Critical Bug 3A-2: Client-Side Fallback Crash on Invalid Key
- **Location**: `src/client/CompanionHUD.client.lua:63`
- **Code**:
  ```lua
  local def = COMPANIONS[compType] or COMPANIONS.zundamon
  ```
- **Issue**: Same key mismatch as above. Client HUD updates for unknown/invalid companion types will evaluate `def` to `nil` and crash the client HUD script.
- **Mitigation Required**: Change fallback in `src/client/CompanionHUD.client.lua:63` to `COMPANIONS.zundapal`.

#### Minor Issue 3B: Missing Fallback for `owned.__active` When Player Data is Nil
- **Location**: `src/server/CompanionShopServer.server.lua:84`
- **Code**:
  ```lua
  GetOwnedCompanions.OnServerInvoke = function(player)
      local owned = {}
      for compType, def in pairs(CompanionConfig.companions) do
          if def.free then owned[compType] = true end
      end
      local data = PlayerDataService.get(player)
      if data then
          -- ...
          owned.__active = data.active_companion or "zundapal"
      end
      return owned
  end
  ```
- **Issue**: If `PlayerDataService.get(player)` returns `nil` (e.g. initial connection or uninitialized data), `owned.__active` is not populated and returns `nil` to the client.
- **Mitigation**: Move default assignment outside `if data then`: `owned.__active = (data and data.active_companion) or "zundapal"`.

### Task 4: Marketplace ID Alignment (PASS)
Empirically verified ID alignment across `MarketplaceConfig.lua`:
- `cardamon` -> Product ID `1111111101`, `type = "companion"`, `robux = 1000`
- `antimon` -> Product ID `1111111102`, `type = "companion"`, `robux = 1000`
- `sakuradamon` -> Product ID `1111111103`, `type = "companion"`, `robux = 1000`
- `tantanmon` -> Product ID `1111111104`, `type = "companion"`, `robux = 1000`
- Perfect 1-to-1-to-1 alignment confirmed across `products`, `companionDevProductIds`, and `storeDisplay.companions`.

---

## Final Recommendation
**REJECTED**. Gate verification CANNOT pass until the fallback references in `CompanionManager.server.lua` (line 173) and `CompanionHUD.client.lua` (line 63) are corrected from `COMPANIONS.zundamon` to `COMPANIONS.zundapal`.
