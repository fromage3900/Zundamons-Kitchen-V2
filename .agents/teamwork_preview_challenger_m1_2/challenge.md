# Milestone 1 Gate Verification Report — Challenger 2

## Challenge Summary

**Overall risk assessment**: LOW

Empirical testing confirms that Milestone 1 companion shop catalog synchronization, DevProduct mapping, client tab sorting, and server ownership sync logic meet all requirements. Legacy key contamination (`zundacat`, `zundabunny`) has been completely eliminated from runtime shop and companion scripts, and `MarketplaceConfig.lua`, `CompanionShopScript.client.lua`, and `StoreScript.client.lua` are fully consistent with `CompanionConfig.lua`.

**Gate Decision**: **VERIFIED**

---

## Challenges

### [Low] Challenge 1: Backward Compatibility for Legacy Player Save Data

- **Assumption challenged**: Players who previously played older builds may have `companion_owned_zundacat = true` or `companion_owned_zundabunny = true` stored in `PlayerDataService`.
- **Attack scenario**: When `GetOwnedCompanions.OnServerInvoke` executes, it parses all keys matching `companion_owned_(.+)` from player data and adds `owned["zundacat"] = true` to the returned dictionary. If the client code iterated blindly over `owned` to create shop tabs, obsolete tabs would be rendered.
- **Blast radius**: UI rendering of empty/glitched tabs for obsolete companions if client UI doesn't filter against active catalog.
- **Mitigation & Verification**: In `CompanionShopScript.client.lua`, `buildTabs()` iterates exclusively over `TAB_ORDER` and checks `catalog[key]`. Obsolete keys in `owned` data are safely ignored during tab rendering.
- **Status**: PASSED / MITIGATED.

### [Low] Challenge 2: Disabling MarketplaceConfig in Unverified Environments

- **Assumption challenged**: DevProduct purchases could fail or error if MarketplaceConfig is disabled or product IDs are placeholders.
- **Attack scenario**: A player clicks a premium companion purchase button while `MarketplaceConfig.enabled == false`.
- **Blast radius**: Potential UI freeze or unhandled error if client/server do not handle `enabled == false`.
- **Mitigation & Verification**: `MarketplaceConfig.enabled` defaults to `false` (fail-closed). Client displays `"Coming Soon • Preview Companion"` on action buttons when disabled, preventing invalid Robux purchase prompts. `CompanionShopServer.server.lua` line 47 checks `MarketplaceConfig.enabled` and warns gracefully if purchase is invoked while disabled.
- **Status**: PASSED.

---

## Stress Test Results

1. **MarketplaceConfig Product ID Uniqueness & Mapping**
   - *Scenario*: Scan `MarketplaceConfig.products` for duplicate product IDs and verify mapping against `companionDevProductIds`.
   - *Expected Behavior*: All product IDs (1111111101..1111111110) are unique; `cardamon`=1111111101, `antimon`=1111111102, `sakuradamon`=1111111103, `tantanmon`=1111111104.
   - *Actual Behavior*: 10 unique product IDs found, 0 duplicates, 100% alignment between `products`, `companionDevProductIds`, and `storeDisplay`.
   - *Result*: **PASS**

2. **Client Tab Order & Active Companion Inclusion**
   - *Scenario*: Extract `TAB_ORDER` from `CompanionShopScript.client.lua` and compare against `CompanionConfig.companions` keys.
   - *Expected Behavior*: `TAB_ORDER` contains 9 active companions (`zundapal`, `parrot`, `dog`, `cat`, `ankomon`, `cardamon`, `antimon`, `sakuradamon`, `tantanmon`), 0 duplicates, 0 legacy keys.
   - *Actual Behavior*: Exact match (9 active companions), clean sorting (free first, premium second), 0 duplicates, 0 legacy keys.
   - *Result*: **PASS**

3. **StoreScript Free Companion Consistency**
   - *Scenario*: Compare `FREE_COMPANIONS` in `StoreScript.client.lua` against `def.free == true` in `CompanionConfig.lua`.
   - *Expected Behavior*: `FREE_COMPANIONS` contains exactly `zundapal`, `dog`, `parrot`, `cat`, `ankomon`.
   - *Actual Behavior*: Exact 1-to-1 match (5 free companions), 0 missing, 0 extra.
   - *Result*: **PASS**

4. **Runtime Legacy Keys Audit (`zundacat`, `zundabunny`)**
   - *Scenario*: Grep scan all runtime shop/companion scripts (`CompanionShopScript.client.lua`, `StoreScript.client.lua`, `CompanionShopServer.server.lua`, `CompanionConfig.lua`, `MarketplaceConfig.lua`) for legacy keys (`zundacat`, `zundabunny`).
   - *Expected Behavior*: 0 occurrences of `zundacat` or `zundabunny` in shop/companion runtime files.
   - *Actual Behavior*: 0 occurrences found across all 5 runtime files.
   - *Result*: **PASS**

---

## Unchallenged Areas

- **Roblox Studio In-Game Prompt Purchase Execution**: Cannot execute actual Roblox Marketplace DevProduct purchases without active Studio playtest session connected via Roblox Studio MCP or live Roblox client. Verified via offline static analysis and Python empirical harness.
