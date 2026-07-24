# Phase 4 — Cosmetic, Avatar & Monetization Plan

Author: Opus research + planning pass, 2026-07-24. Grounded in a full read of the
existing shop/cosmetic/currency code. Every "already exists" claim is cited to
`file:line`. This is the monetization companion to `docs/PHASE4_PLAN.md` (which
covers juice/feel, not economy). **Nothing here proposes a system the code can't
reach today without naming the exact glue that's missing.**

---

## 0. Executive summary — the honest state of the economy

The game has **three shops in three different states of completeness** and **one
currency that actually works**:

| System | State | Evidence |
| --- | --- | --- |
| **Furniture/Decor shop** (gold) | ✅ **Fully functional** | `FurniturePlacementServer.server.lua:43-48` deducts gold, grants item + buff |
| **Companion Boutique** (Robux) | ✅ **UI + wiring complete, hard-disabled** | `CompanionShopScript.client.lua` full boutique; gated by `MarketplaceConfig.enabled=false` (`MarketplaceConfig.lua:9`) |
| **Robux Store** (recipes/accessories) | 🟡 **UI real, purchase path is a debug toast** | `StoreScript.client.lua:144-168` fires a placeholder toast, not a purchase, and product IDs are placeholders |
| **Wardrobe / Chef Style** | 🟡 **Read-only display; no equip, no buy** | `OutfitWardrobeGui.client.lua:212-265` outfit cards are a hardcoded sample list; equip buttons wire to nothing |
| **Clothing shop** (gold, `ShopConfig.clothing`) | 🔴 **Config only, no UI, no purchase handler** | `ShopConfig.lua:13-74` has 6 real asset IDs; nothing consumes it |
| **Gacha (Whim)** | 🔴 **Stub** | `GachaService.lua` in-memory pity only; no currency, no remote, no grant, not wired |
| **Hard currency (Gems/Tickets)** | 🔴 **Defined, never minted or stored** | `GachaConfig.lua:9-12` defines them; absent from `PlayerDataService` default data (`:245-288`) |

**The single biggest truth:** the ProcessReceipt backbone is *correct and unified*
(`MarketplaceService.lua` is the sole `ProcessReceipt` owner, delegated to by both
`RobuxStoreServer` and `CompanionShopServer`). Turning real monetization on is
mostly **content entry + flipping `enabled` + wiring 2 client purchase paths**, not
architecture. Do not rebuild the receipt layer — it's the strongest asset here.

### Placeholder verification (confirmed)
All 10 product IDs in `MarketplaceConfig.products` (`MarketplaceConfig.lua:12-23`)
are sequential placeholders `1111111101`–`1111111110`. `StoreScript.client.lua:157`
literally prints *"Replace product ID … in RobuxStoreServer"* to the player. These
**must** be replaced with real Developer Product / Game Pass IDs created in the
published experience before any Robux flow is enabled. `MarketplaceConfig.enabled`
is `false` and everything fails closed against it — this is correct and should stay
false until IDs are real and receipts verified in a private published build.

---

## 1. Cosmetic system

### 1.1 What categories make sense (and their current substrate)

| Category | Substrate today | Verdict |
| --- | --- | --- |
| **Kitchen / garden decor** | `DecorationConfig.lua` (garden + cottage items, mesh IDs, buffs) + working buy/place server | ✅ **Ship-ready.** The one cosmetic loop that fully works end to end. |
| **Player chef outfits** (shirts/aprons/robes) | `ShopConfig.lua:13-74` — 6 real Roblox asset IDs, gold prices, tier gates | 🟡 **Half-built.** Config is real; no store UI, no purchase handler, no equip. |
| **Player accessories** (hats/crowns/bows) | Two homes: `ShopConfig` accessories (asset IDs, gold) **and** `StoreScript` accessories (Robux, placeholder IDs `1111111108-10`) | 🔴 **Conflicting/duplicated.** Pick one currency per item; see §4. |
| **Style-tier fashion unlocks** | `ChefStatsConfig.stylePoints.outfitUnlocks` (`ChefStatsConfig.lua:88-95`) — 8 named outfits gated behind style tiers | 🟡 **Progression ladder defined; outfits are bare string IDs with no asset mapping or equip path.** |
| **Companion skins/glows** | `CompanionVisualConfig.lua` + `CompanionConfig` per-companion `glow`/`sparkleColors` | 🟡 **Visual attributes exist; no "skin variant" concept or ownership.** Net-new to monetize. |
| **FX auras** (e.g. `AllCompanions_CosmicAura`) | Referenced in `GachaConfig` pool + `ChefStatsConfig` unlocks | 🔴 **Names only, no FX asset wiring.** |

### 1.2 Half-built vs net-new

- **Half-built (finish, don't invent):**
  - Player chef-outfit store: `ShopConfig.clothing` is ready; needs a store UI + a
    gold-spend purchase handler + a HumanoidDescription apply-on-equip path.
  - Wardrobe equip: `OutfitWardrobeGui` renders a gallery but the equip buttons
    (`OutfitWardrobeGui.client.lua:251-265`) fire no remote. The unlock *read* path
    works (`OutfitUnlock`/`StylePointsUpdate` remotes fired from
    `EndlessLoopWiring.server.lua:42-44`), but there is **no write path** (equip,
    persist equipped, apply to avatar). Sample list at `:212-219` is hardcoded and
    must be replaced with server-driven catalog data.
- **Net-new:** companion skins as a distinct ownable, FX auras as real particles,
  and any hard-currency cosmetic gacha.

### 1.3 Recommended cosmetic ownership model
Persist all cosmetic ownership in the existing profile schema — the keys already
exist: `owned_clothing`, `owned_decorations`, `cosmetics_unlocked`,
`unlocked_outfits`, `furniture_unlocked` (`PlayerDataService.lua:258-263`, and
`unlocked_outfits` written at `EndlessLoopWiring.server.lua:92`). Add one more:
`equipped_cosmetics = { outfit=…, hat=…, aura=… }`. No schema redesign needed.

---

## 2. Avatar system

### 2.1 Maturity assessment — lower than the file names suggest
The "outfit remotes per ChefStats" are **telemetry, not wardrobe control**:
`ChefStatsUpdate`, `StylePointsUpdate`, `OutfitUnlock` are all **server→client
push** (`EndlessLoopWiring.server.lua:74-108`). They tell the client *"you now have
X style points / tier / unlocked outfit"*. There is **no client→server "equip this
outfit" remote anywhere**, and nothing applies a cosmetic to the player's Roblox
avatar. The `ChefStats` system is a genuine, working *stat/style-points* engine; it
is **not** an avatar customization system yet.

### 2.2 Is player-avatar cosmetics a real vector? — Yes, and it's the cheapest one
The player character is a stock Roblox avatar, and `ShopConfig.clothing` already
holds **6 verified shirt/pants/accessory asset IDs** (`ShopConfig.lua:22,31,42,50,60,71`).
Applying these is a solved Roblox pattern (`HumanoidDescription` for shirts/pants;
`AddAccessory` / `Humanoid:ApplyDescription` for hats). This is the highest-ROI
cosmetic vector because the assets exist and the apply API is trivial.

### 2.3 Storage/equip design (concrete)
1. **Catalog source of truth:** `ShopConfig.clothing` (gold) + a new
   `CosmeticConfig` for premium/gacha-only items (Robux/gems). Keep asset IDs here.
2. **Ownership:** `owned_clothing` (already in schema + whitelisted in
   `RequestDataHandler.server.lua:17`).
3. **Equipped state:** new `equipped_cosmetics` profile key.
4. **New remotes (net-new, ~1 file):** `EquipCosmetic` (RemoteEvent, client→server:
   validate ownership → set `equipped_cosmetics` → apply HumanoidDescription →
   re-apply on `CharacterAdded`). `PurchaseCosmetic` (gold path) mirroring the
   proven furniture handler (`FurniturePlacementServer.server.lua:40-48`).
5. **Wardrobe becomes the equip surface:** replace the hardcoded gallery in
   `OutfitWardrobeGui` with a `GetCosmeticCatalog` RemoteFunction feed and make the
   equip buttons fire `EquipCosmetic`.

**Effort:** ~1 server script + ~1 remote pair + rewiring one existing client. The
avatar system is the *smallest* net-new lift with a real, ownable-asset payoff.

---

## 3. Monetization vectors

Ranked by (existing support ÷ effort). "Effort" is relative dev-days, not calendar.

### (a) Direct Robux purchases — **90% there, effort: S**
- **Support:** Unified `ProcessReceipt` (`MarketplaceService.lua:23-62`) grants
  companion/recipe/accessory correctly and idempotently via `PlayerDataService.mutate`.
  Prompt path exists (`RobuxStoreServer.server.lua:33-43`).
- **Gaps:** (1) real product IDs; (2) `MarketplaceConfig.enabled=true` after
  verification; (3) `StoreScript.client.lua:144-168` currently fires a *debug toast*
  instead of calling `promptRF:InvokeServer(prod.id)` for real — it does call it at
  `:166` but wrapped in the fake-purchase toast UX; clean this to a real prompt +
  success/fail handling via the existing `PurchaseResult` event (`:248-261`).
- **Ship:** create DevProducts → paste IDs → flip enabled → private-build receipt test.

### (b) Premium/hard currency (Gems) + gold — **config only, effort: M**
- **Support:** `GachaConfig.currencies` (`:9-12`) names `gems` (Robux-bought) and
  `tokens`/Whim Tickets (earned). That's the entire extent — **neither is persisted,
  minted, or spent anywhere.** Gold is the only real currency (`PlayerDataService`
  default `gold=50` `:247`; `RewardCore.addGold` `:80`).
- **Gaps:** add `gems` + `whim_tickets` to default data; a `RewardCore.spendCurrency`
  helper (today even gold has no shared spend helper — furniture deducts inline at
  `FurniturePlacementServer.server.lua:45`, which is a smell worth fixing); Gem
  DevProducts (buy-gems bundles) routed through the existing ProcessReceipt (add
  `type="currency"` handling — one `elseif` branch in `MarketplaceService.lua:37-51`).
- **Recommendation:** **Do not add a second soft currency (tickets) yet.** A cozy
  game with one soft (gold) + one hard (gems) currency is cleaner and less
  predatory. Fold "Whim Tickets" into gems or earn-only gem drips.

### (c) Gacha / loot — **stub + defined banners, effort: M-L, caution HIGH**
- **Support:** `GachaConfig` has a real banner, rarity pools, and pity rules
  (`:14-47`). `GachaService.performPull` (`:22-67`) implements pity + weighted roll.
- **Gaps (this is a stub, not a feature):** pity is **in-memory, wiped on leave**
  (`GachaService.lua:13,70-72`) — not persisted; **no currency is spent**; **no
  remote** exposes it to a client; **no inventory grant** on pull; **no banner UI**.
- **Viability of a *fair* gacha:** Yes, but scope it as **cosmetic-only** and honor
  Roblox's paid-random-item policy: **publish odds**, guarantee via the existing
  pity, and **never gate gameplay power** behind it. Companions already carry
  gameplay buffs (`CompanionConfig.lua:88-162`), so **keep companions on direct
  purchase, put only outfits/auras/skins in gacha.** Persist pity in the profile.
- **Honest call:** this is the highest-effort, highest-risk vector and the least
  finished. **Defer to a later phase.**

### (d) Battle pass / season track — **infra exists, effort: M**
- **Support to hang it on:** `DailyChallengeService`, `ChallengeModeService`,
  `DailyStreakService`, `AdvancedRewards.server.lua` (login streak, achievements,
  daily quests all call `RewardCore.addGold/addXP`). Style points
  (`ChefStatsConfig.stylePoints`) already accrue per cook/serve
  (`EndlessLoopWiring.server.lua:127-148`) — a natural "pass XP" signal.
- **Gaps:** a `SeasonPassConfig` (tiers × free/premium reward tracks), a persisted
  `season_pass = { xp, claimed_tiers, premium_owned }`, a claim remote, and one
  Game Pass (or DevProduct) for the premium track. Reward payloads reuse
  `RewardCore` + cosmetic grants.
- **Fit:** strong. This is the best *recurring-revenue* vector for a cozy game and
  reuses more existing systems than gacha does.

### (e) Game passes — **zero support today, effort: S each, best ROI**
- **Support:** none — no Game Pass IDs anywhere; `MarketplaceConfig` only has
  DevProducts. But Game Passes reuse `MarketplaceService` philosophy (add a
  `UserOwnsGamePassAsync` check on join + a `PromptGamePassPurchase`).
- **High-fit passes for this game:**
  - **2× Gold** — wrap `RewardCore.addGold` (`:80`) in a per-player multiplier. One
    of the cleanest possible integrations.
  - **Auto-harvest / auto-serve helper** — hangs on the harvest + guest systems.
  - **+Companion slots / extra outfit loadouts.**
  - **VIP cozy perks** (exclusive glow, name tag, chair).
- **Recommendation:** **2× Gold and a VIP pass are the single best first
  monetization to ship** — trivial integration, universally accepted in cozy games,
  no fairness concerns.

---

## 4. Shop UI integration

### 4.1 The problem
Three disjoint surfaces today:
- **Robux Store** (`StoreScript.client.lua`) — `ZundaShopGui`, opens via HUD
  `HudBtn_shop`/`HudBtn_settings` and key **B** (`:275-289`). Tabs: Recipes,
  Accessories. Has a dead `companions` branch (`:237-238`) never given a tab button.
- **Companion Boutique** (`CompanionShopScript.client.lua`) — `CompanionShopGui`,
  the **most mature** shop; registered with `UIRouter` + `ActionRegistry` under
  action `companions` (`:368-371`).
- **Furniture Shop** (`FurniturePlacement.client.lua`) — gold decor + placement.

They use **different modal conventions**: the Boutique uses `CozyModalShell` +
`UIRouter` (modal exclusivity, Escape handling); StoreScript is a bespoke
hand-rolled panel with its own toggle and no router registration.

### 4.2 Recommendation — unify into one "Zunda Shop" with tabs, reached from the Pea Wheel
1. **Add a `shop` action to `UIActionRegistry`** (`UIActionRegistry.lua` DEFAULTS,
   `:40-160`) with an icon (🛍️) and include it in `getOrderedSliceList()`
   (`:258-269`) so it's a real Pea Wheel slice. Today there is no shop slice — the
   Robux store is only reachable by key **B** and legacy HUD buttons, and the
   Boutique only via its own `companions` slice. This is the missing front door.
2. **One shell, five tabs**, all built on `CozyModalShell` + `UIRouter` (adopt the
   Boutique's proven pattern; retire StoreScript's bespoke toggle):
   - **Style** (player outfits/accessories — gold via `ShopConfig`, premium via new `CosmeticConfig`)
   - **Companions** (the existing Boutique detail view, embedded)
   - **Home** (furniture/decor — the working gold shop)
   - **Recipes** (Robux unlocks — existing)
   - **Premium** (Gem bundles, Game Passes, Season Pass — new)
3. **Currency clarity:** each tab shows the price in its native currency with a
   consistent badge (gold 🪙 / Robux 🌀 / gems 💎). Resolve the accessory
   duplication (§1.1): make **hats/aprons gold via `ShopConfig`**, reserve Robux/gems
   for premium-exclusive cosmetics only.
4. **Keep the Boutique code** — don't rewrite it; refactor it to render into a tab
   frame instead of its own full-screen panel. It already exposes
   `_G.ZundaCompanionShop = { open, close, toggle }` (`:364`) so a container can drive it.
5. **Route everything through `UIRouter`** so opening the shop closes other modals
   (the Boutique already does this at `:342-350`; StoreScript does not, which is a
   latent double-modal bug).

### 4.3 Migration note
`StoreScript.client.lua` and `OutfitWardrobeGui.client.lua` both predate the
`UIActionRegistry`/`UIRouter` conventions (Store uses raw HUD-button hooks; Wardrobe
was recently de-rogue'd but is still a standalone toggle). Unifying them under the
router is as much a **consistency/bugfix** win as a monetization one.

---

## 5. Prioritized roadmap (best effort:reward first)

### Phase 4A — "Make the money door real and honest" (S, ship first)
1. **Finish direct Robux (§3a):** create real DevProduct IDs, replace placeholders,
   clean `StoreScript` purchase path to a real prompt + `PurchaseResult` UX, flip
   `MarketplaceConfig.enabled` after a private receipt test. *Unblocks the Boutique
   too — it's already built and only waiting on this flag.*
2. **Ship 2× Gold + VIP Game Passes (§3e):** wrap `RewardCore.addGold`; add join-time
   `UserOwnsGamePassAsync`. Highest ROI, lowest risk.
3. **Add the unified `shop` Pea Wheel slice + tab shell (§4):** even before all tabs
   are rich, this gives one coherent front door and routes through `UIRouter`.

### Phase 4B — "Cosmetics people actually equip" (M)
4. **Gold chef-outfit store + equip (§2):** consume `ShopConfig.clothing`, add
   `PurchaseCosmetic` (mirror furniture handler) + `EquipCosmetic` +
   HumanoidDescription apply + `CharacterAdded` re-apply. Rewire `OutfitWardrobeGui`
   to a server catalog and live equip buttons.
5. **Map `ChefStatsConfig.outfitUnlocks` string IDs → real asset IDs** so the
   style-tier ladder grants equippable outfits (turns existing progression into a
   retention cosmetic reward, no new currency).

### Phase 4C — "Recurring revenue" (M)
6. **Season Pass (§3d):** `SeasonPassConfig`, persisted track, claim remote, premium
   Game Pass, reward payloads via `RewardCore` + cosmetic grants. Feed pass XP from
   the style-points signal that already fires per cook/serve.

### Phase 4D — "Hard currency + gacha" (L, most caution, defer)
7. **Gems as hard currency (§3b):** persist + mint via Gem-bundle DevProducts through
   the existing ProcessReceipt (`type="currency"` branch).
8. **Cosmetic-only Whim gacha (§3c):** persist pity, spend gems, add remote + grant +
   banner UI, publish odds, cosmetics only — never gameplay buffs. Only after the
   simpler vectors are earning and the cosmetic catalog is deep enough to be worth
   rolling for.

### Explicitly deferred / cut
- Second soft currency (Whim Tickets) — fold into gems.
- FX auras as a product — need real particle assets first; today they're names only.
- Companion gacha — companions carry buffs; keep them on direct purchase for fairness.

---

## Appendix — key file map

| Concern | File | Notes |
| --- | --- | --- |
| Receipt owner (unified) | `src/server/Services/MarketplaceService.lua` | ✅ solid; extend for `currency`/gamepass |
| Product catalog + `enabled` flag | `src/shared/ConfigurationFiles/MarketplaceConfig.lua` | placeholder IDs `:12-23`, `enabled=false :9` |
| Robux store UI | `src/client/StoreScript.client.lua` | debug-toast purchase `:144-168`; unify into shell |
| Companion boutique (mature) | `src/client/CompanionShopScript.client.lua` + `CompanionShopServer.server.lua` | pattern to copy |
| Companion catalog + buffs | `src/shared/ConfigurationFiles/CompanionConfig.lua` | 4 premium @1000 Robux |
| Chef stats + style tiers | `src/shared/ConfigurationFiles/ChefStatsConfig.lua` | unlock ladder `:88-95` |
| Stats/style server push | `src/server/systems/EndlessLoopWiring.server.lua` | telemetry remotes `:42-44`, `:74-108` |
| Wardrobe UI (read-only) | `src/client/OutfitWardrobeGui.client.lua` | hardcoded gallery `:212-219`, no equip |
| Clothing catalog (gold) | `src/shared/ConfigurationFiles/ShopConfig.lua` | 6 real asset IDs, no consumer |
| Furniture shop (works) | `src/server/FurniturePlacementServer.server.lua` + `DecorationConfig.lua` | purchase template `:40-48` |
| Gacha (stub) | `src/server/Services/GachaService.lua` + `GachaConfig.lua` | in-memory pity, unwired |
| Currency + schema | `src/server/Services/PlayerDataService.lua` | gold only; default `:245-288` |
| Reward helpers | `src/server/Services/RewardCore.lua` | `addGold :80`; no spend helper |
| Pea Wheel / action registry | `src/client/ConfigurationFiles/UIActionRegistry.lua` | add `shop` slice `:40-160,258-269` |
