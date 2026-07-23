# Review Report — Milestone 1 Gate Verification

**Verdict**: APPROVE

## Executive Summary
All code changes in Milestone 1 (Companion System & Companion Shop Synchronization) have been reviewed, verified, and stress-tested. The changes meet all verification criteria, adhere to Roblox Studio & Rojo 7.7.0 workspace rules, maintain client UI decoupling, enforce `ResetOnSpawn = false` on `ScreenGui` instances, and handle edge cases gracefully without integrity violations.

---

## Verified Criteria & Evidence

### 1. `CompanionConfig.lua` Catalog Configuration
- **Status**: PASSED
- **Evidence**:
  - Starter (`zundapal`) and 4 free companions (`parrot`, `dog`, `cat`, `ankomon`) explicitly configured with `free = true` and `price = 0`.
  - 4 premium companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`) explicitly configured with `free = false`, `price = 1000`, and `robux = 1000`.
  - Buff attributes (gold multiplier, perfect window expansion, extra drop chance, XP bonus, speed burst) correctly mapped to premium and special free (`ankomon`) companions.

### 2. `MarketplaceConfig.lua` DevProduct Catalog & Mappings
- **Status**: PASSED
- **Evidence**:
  - `MarketplaceConfig.products` maps Developer Product IDs `1111111101` through `1111111104` to `cardamon`, `antimon`, `sakuradamon`, and `tantanmon`.
  - `MarketplaceConfig.companionDevProductIds` maps companion keys to the exact corresponding product IDs without collisions or orphaned references.
  - `MarketplaceConfig.storeDisplay.companions` accurately mirrors product metadata and descriptions.

### 3. `CompanionShopServer.server.lua` Data & Server Handler Logic
- **Status**: PASSED
- **Evidence**:
  - `GetOwnedCompanions.OnServerInvoke` dynamically iterates `CompanionConfig.companions` and populates defaults where `def.free == true`.
  - Merges player data flags matching pattern `companion_owned_<name>`.
  - Premium companion `tantanmon` is NOT marked owned by default; only unlocked when `companion_owned_tantanmon == true` in player profile data.
  - Handles `nil` player data gracefully during initial login state.
  - Server validation on `PurchaseCompanion` rejects requests for non-existent, free, or already-owned companions.

### 4. Client UI Decoupling, Tab Order, and ScreenGui Persistence
- **Status**: PASSED
- **Evidence**:
  - Both `StoreScript.client.lua` and `CompanionShopScript.client.lua` instantiate ScreenGuis via `ClientGuiBootstrap.createScreenGui`, which explicitly enforces `ResetOnSpawn = false`.
  - Transient toast ScreenGuis (`PurchaseToast`, `SuccessToast`) explicitly enforce `ResetOnSpawn = false`.
  - `CompanionShopScript.client.lua` defines `TAB_ORDER` with free companions listed first (`zundapal`, `parrot`, `dog`, `cat`, `ankomon`), followed by premium companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`).
  - Panel initial state is set to `Visible = false` to prevent modal overlaps on spawn.

---

## Adversarial Challenge & Stress-Test Results

| Attack Scenario / Assumption | Expected Behavior | Actual Behavior | Result |
| --- | --- | --- | --- |
| Player profile data not yet loaded when `GetOwnedCompanions` invoked | Return free companions table without throwing Lua error | Dynamically populates free companions and defaults `__active` safely | PASS |
| Client attempts `PurchaseCompanion` for a free companion | Server rejects purchase attempt | `def.free` check early returns from handler | PASS |
| Client attempts `PurchaseCompanion` for already-owned premium companion | Server rejects duplicate purchase prompt | `companion_owned_<compType>` check early returns | PASS |
| Character respawns while shop GUI active | GUI persists without reset or UI state corruption | `ResetOnSpawn = false` preserves state | PASS |

---

## Integrity Violation Check
- **Hardcoded test outputs / facades**: None detected. Real catalog data structures, dynamic table lookups, and functional remote invocations are present.
- **Bypassed logic / shortcuts**: None detected.
- **Verdict**: CLEAN. APPROVE.
