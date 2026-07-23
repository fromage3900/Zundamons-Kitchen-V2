# Handoff Report — Explorer 3 (Milestone 1)

## 1. Observation

Direct observations from source inspection:

1. **`src/shared/ConfigurationFiles/CompanionConfig.lua`** (lines 14-163):
   - `zundapal`: `free = true`, `price = 0`
   - `dog`: `free = true`, `price = 0`
   - `parrot`: `free = true`, `price = 0`
   - `cat`: `free = true`, `price = 0`
   - `ankomon`: `free = true`, `price = 0`, `buff = { stat = "gold", magnitude = 0.15 }`
   - `cardamon`: `free = false`, `price = 1000`, `robux = 1000`, `buff = { stat = "perfect_window", magnitude = 0.30 }`
   - `antimon`: `free = false`, `price = 1000`, `robux = 1000`, `buff = { stat = "extra_drop", magnitude = 0.20 }`
   - `sakuradamon`: `free = false`, `price = 1000`, `robux = 1000`, `buff = { stat = "xp", magnitude = 0.25 }`
   - `tantanmon`: `free = false`, `price = 1000`, `robux = 1000`, `buff = { stat = "speed", magnitude = 0.20 }`

2. **`src/server/CompanionShopServer.server.lua`** (lines 67-82):
   - `GetOwnedCompanions.OnServerInvoke` hardcodes:
     `local owned = { zundapal = true, zundamon = true, zundacat = true, zundabunny = true, tantanmon = true, dog = true, parrot = true, cat = true }`
   - `ankomon` is missing from this default table.
   - `tantanmon` is included as `true` in this default table despite being configured as `free = false` in `CompanionConfig.lua`.

3. **`src/server/Services/PlayerDataService.lua`** (lines 245-304):
   - `createDefaultData()` initializes `companions_set = {}` and does not pre-populate `companion_owned_<comp>` keys. Free companion access relies on catalog `free = true` or `GetOwnedCompanions` returns.

4. **`src/server/CompanionManager.server.lua`** (lines 363-377):
   - `SetCompanion.OnServerEvent` checks `def.free == true` or `data["companion_owned_" .. compType]`. Allows `ankomon` to be equipped server-side because `ankomon.free == true`. Rejects `tantanmon` unless purchased.

5. **`src/client/CompanionShopScript.client.lua`** (line 196):
   - `TAB_ORDER` includes legacy keys (`zundamon`, `zundacat`, `zundabunny`) and places `tantanmon` in the free tab sequence.

6. **`src/client/StoreScript.client.lua`** (lines 178-187):
   - Hardcodes `FREE_COMPANIONS` including `tantanmon`, `zundamon`, `zundacat`, `zundabunny`, and omitting `ankomon`.

7. **`src/shared/ConfigurationFiles/MarketplaceConfig.lua`** (lines 12-33):
   - `products` maps `[1111111101]` to `zundacat` and `[1111111102]` to `zundabunny`.
   - `companionDevProductIds` maps `cardamon`, `antimon`, `sakuradamon` to `0`.
   - Conflicts with `storeDisplay.companions` which maps `cardamon` (1111111101), `antimon` (1111111102), `sakuradamon` (1111111103), `tantanmon` (1111111104).

---

## 2. Logic Chain

1. **Free Companion Requirement Verification**:
   - The project specification mandates that 4 free companions (`parrot`, `dog`, `cat`, `ankomon`) alongside starter `zundapal` are automatically owned/unlocked by all players on join.
   - `CompanionConfig.lua` correctly sets `free = true` for `zundapal`, `dog`, `parrot`, `cat`, and `ankomon`.
   - However, server handler `GetOwnedCompanions` in `CompanionShopServer.server.lua` fails to include `ankomon` in its default owned dictionary, causing client UI queries to report `ankomon` as unowned by default. `StoreScript.client.lua` also omits `ankomon` from `FREE_COMPANIONS`.

2. **Premium Companion Lock Verification**:
   - The specification mandates that premium companions (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`) require purchase (1,000 Robux each) and are NOT unlocked by default.
   - `CompanionConfig.lua` correctly configures all 4 as `free = false`, `price = 1000`, `robux = 1000`.
   - However, `CompanionShopServer.server.lua` hardcodes `tantanmon = true` in `GetOwnedCompanions.OnServerInvoke`, unlocking `tantanmon` for all players by default without purchase.
   - Furthermore, `MarketplaceConfig.lua` product mapping contains legacy keys (`zundacat`, `zundabunny`) instead of mapping the 4 canonical premium companions to their respective product IDs.

3. **Synthesis & Root Cause**:
   - The discrepancy stems from hardcoded static tables in `CompanionShopServer.server.lua`, `StoreScript.client.lua`, and `MarketplaceConfig.lua` that fell out of sync with `CompanionConfig.lua`.
   - Replacing hardcoded static dictionaries in `GetOwnedCompanions` with dynamic queries against `CompanionConfig.companions` where `def.free == true` permanently guarantees that all free companions (including `ankomon`) are owned on join and all premium companions (including `tantanmon`) are locked until purchase.

---

## 3. Caveats

- **Legacy Player Data**: Players who had previously saved data with legacy keys (`companion_owned_zundacat`) will retain those keys, but active catalogs should ignore legacy keys not in `CompanionConfig.companions`.
- **Marketplace DevProduct Integration**: In Studio mock mode (`RunService:IsStudio()`), DevProduct purchases rely on `MarketplaceConfig.enabled = false` / test stubs until real DevProduct IDs are provisioned on Roblox Dashboard for production.

---

## 4. Conclusion

1. `CompanionConfig.lua` is canonical and accurate:
   - Free companions: `zundapal`, `dog`, `parrot`, `cat`, `ankomon`.
   - Premium companions (1,000 Robux): `cardamon`, `antimon`, `sakuradamon`, `tantanmon`.
2. Three critical code fixes are required for the Implementer agent:
   - Fix `CompanionShopServer.server.lua` (`GetOwnedCompanions`) to dynamically return all `def.free == true` companions (granting `ankomon` and locking `tantanmon`).
   - Fix `StoreScript.client.lua` (`FREE_COMPANIONS`) to include `ankomon` and remove `tantanmon`.
   - Fix `MarketplaceConfig.lua` to map `cardamon`, `antimon`, `sakuradamon`, `tantanmon` to product IDs `1111111101` - `1111111104`.

---

## 5. Verification Method

To verify these findings independently or after implementer fixes:

1. **Check `GetOwnedCompanions` invoke result**:
   - In Roblox Studio command bar or server test script:
     ```lua
     local SSS = game:GetService("ServerScriptService")
     local RF = game:GetService("ReplicatedStorage").RemoteFunctions.GetOwnedCompanions
     local player = game.Players:GetPlayers()[1]
     local owned = RF:Invoke(player)
     print("Owned companions:", owned)
     ```
   - Expectation: `owned.parrot == true`, `owned.dog == true`, `owned.cat == true`, `owned.ankomon == true`, `owned.zundapal == true`.
   - Expectation for premium: `owned.cardamon == nil`, `owned.antimon == nil`, `owned.sakuradamon == nil`, `owned.tantanmon == nil`.

2. **Check Shop UI behavior**:
   - Open Companion Boutique in-game (press 'O').
   - Confirm tabs and details for `parrot`, `dog`, `cat`, `ankomon`, `zundapal` show "Equip" / "✓ Equipped".
   - Confirm tabs and details for `cardamon`, `antimon`, `sakuradamon`, `tantanmon` show "1000 Robux" purchase prompt and NOT "Equip".
