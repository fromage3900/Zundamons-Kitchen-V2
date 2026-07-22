# Backend Game Telemetry Audit & JSON Specification Handoff Report

**Author**: Explorer 4  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_1`  
**Milestone**: Milestone 2  
**Target Service**: `WebInfoSyncService.lua`, `PromoCodeService.lua`, `game_info.json` (docs/api & site/api)  

---

## 1. Observation

Direct observations from filesystem inspection and code auditing:

### 1.1 `src/server/Services/WebInfoSyncService.lua` (Lines 1-52)
```lua
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigurationFiles = Shared:WaitForChild("ConfigurationFiles")
local DailyChallengeConfig = require(ConfigurationFiles:WaitForChild("DailyChallengeConfig"))
local GachaConfig = require(ConfigurationFiles:WaitForChild("GachaConfig"))

local WebInfoSyncService = {}

function WebInfoSyncService.exportGameStateJson(): string
	local payload = {
		last_updated = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		game_version = "v2.4.1-hybrid",
		live_event = {
			name = "🌸 Whims of Gourmet - Spring Festival",
			active = true,
			multiplier = "2.0x Style Points & Gold",
		},
		active_daily_challenges = {
			DailyChallengeConfig.challenges[1].title,
			DailyChallengeConfig.challenges[2].title,
			DailyChallengeConfig.challenges[3].title,
		},
		featured_gacha_banner = {
			name = GachaConfig.banners[1].name,
			cost = GachaConfig.banners[1].costPerPull,
			featured_items = GachaConfig.banners[1].featuredItems,
		},
		active_promo_codes = {
			"ZUNDAMOCHI2026",
			"SOUPSEASON",
			"KAWAIIZUNDA",
			"NIKKIFASHION",
		},
		global_stats = {
			total_dishes_cooked = 142850,
			total_gacha_pulls = 38920,
			active_chefs_online = 125,
		},
	}

	return HttpService:JSONEncode(payload)
end
```
* **Runtime Error**: Line 26-28 attempts to index `DailyChallengeConfig.challenges`. In `src/shared/ConfigurationFiles/DailyChallengeConfig.lua`, the table is exported as `DailyChallengeConfig.dailyPool`, NOT `DailyChallengeConfig.challenges`. Calling `WebInfoSyncService.exportGameStateJson()` results in `attempt to index nil with number`.
* **Missing Schema Elements**:
  * `online_players`: Lacks top-level object `{ "count": ..., "status": "online", "version": "2.4.0 HYBRID ECS" }`.
  * `active_challenges`: Missing structured daily and weekly challenge list (name, target, reward).
  * `gacha_banners`: Uses singular `featured_gacha_banner` and omits companion spirit drop rates.
  * `promo_codes`: Hardcoded list missing `"HYBRIDECS"` and disconnected from `PromoCodeService.activeCodes`.
  * `global_stats`: Missing `edamame_harvested` count.

### 1.2 `src/server/Services/PromoCodeService.lua` (Lines 10-16)
```lua
PromoCodeService.activeCodes = {
	ZUNDAMOCHI2026 = { gold = 500, gems = 50, item = "10x Fresh Zunda Mochi" },
	SOUPSEASON     = { gold = 1000, gems = 100, item = "5x Wild Mushroom Pack" },
	KAWAIIZUNDA    = { gold = 750, gems = 75, item = "Sakura Chef Apron" },
	NIKKIFASHION   = { gold = 1500, gems = 150, item = "3x Whim Gacha Tickets" },
}
```
* Missing the required `HYBRIDECS` code definition.

### 1.3 `docs/api/game_info.json` & `site/api/game_info.json`
* `docs/api/game_info.json` currently exists but uses the outdated payload format.
* `site/api/game_info.json` does NOT exist in `site/` source folder.
* Running `node site/sync_site.js` copies all files from `site/` to `docs/`. Without `site/api/game_info.json`, `docs/api/game_info.json` is preserved but not generated from source control.

---

## 2. Logic Chain

1. **Root Cause Analysis of Bug**:
   `WebInfoSyncService.lua` was written referencing `DailyChallengeConfig.challenges`. However, `DailyChallengeConfig.lua` defines the pool as `DailyChallengeConfig.dailyPool` and exposes `selectDailyChallenges()` and `getWeeklyBoss()`. Therefore, `DailyChallengeConfig.challenges` evaluates to `nil`, causing runtime errors whenever telemetry is serialized.

2. **Telemetry Generator Schema Alignment**:
   To satisfy all 5 requirements in the task specification:
   - **`online_players`**: Needs a structured object containing `count` (number of connected players or fallback active chefs), `status` (`"online"`), and `version` (`"2.4.0 HYBRID ECS"`).
   - **`active_challenges`**: Must contain both `daily` array and `weekly` array, detailing challenge `id`, `name`, `target` (description), `goal`, and `reward` breakdown (gold, xp, style points, items).
   - **`gacha_banners`**: Must be an array of active companion spirit banners containing `id`, `banner_name`, `banner_type`, `cost_per_pull`, `featured_spirits`, and `rates` (`legendary`: 5%, `epic`: 20%, `rare`: 75%).
   - **`promo_codes`**: Must dynamically query `PromoCodeService.activeCodes` or output a structured array including `ZUNDAMOCHI2026`, `SOUPSEASON`, `KAWAIIZUNDA`, `NIKKIFASHION`, and `HYBRIDECS` with reward summaries.
   - **`global_stats`**: Must include `total_dishes_cooked` (142,850), `edamame_harvested` (89,420), `total_gacha_pulls` (38,920), and `active_event` status (`"🌸 Whims of Gourmet - Spring Festival"`, `active`: true, `multiplier`: `"2.0x Style Points & Gold"`).

3. **HTTP & Filesystem Sync Routine**:
   - **In-Game Export**: `WebInfoSyncService.exportGameStateJson()` outputs the JSON string in-engine. An optional timer or event loop in Luau can invoke `HttpService:PostAsync(TELEMETRY_ENDPOINT, payloadJson)` to update live external servers.
   - **Static Hub Sync**: Creating `site/api/game_info.json` with the verified spec allows `node site/sync_site.js` to automatically mirror `site/api/game_info.json` -> `docs/api/game_info.json`, keeping GitHub Pages 100% updated.

---

## 3. Caveats

* **Read-Only Scope**: This report provides proposed code updates and exact JSON specs. Explorer 4 has not modified existing codebase source files directly outside the `.agents` working folder.
* **Online Player Count in Studio**: In Roblox Studio mock environment, `Players:GetPlayers()` may return 0 or 1. `WebInfoSyncService` should fallback to baseline community active chefs count (e.g. `math.max(#Players:GetPlayers(), 125)`) when running in mock telemetry mode.

---

## 4. Conclusion

`WebInfoSyncService.lua`, `PromoCodeService.lua`, and `game_info.json` require updates to fix runtime errors, add missing promo codes, and adhere to the Milestone 2 telemetry spec.

### Proposed Fix 1: `src/server/Services/PromoCodeService.lua`
Add `HYBRIDECS` code:
```lua
PromoCodeService.activeCodes = {
	ZUNDAMOCHI2026 = { gold = 500, gems = 50, item = "10x Fresh Zunda Mochi" },
	SOUPSEASON     = { gold = 1000, gems = 100, item = "5x Wild Mushroom Pack" },
	KAWAIIZUNDA    = { gold = 750, gems = 75, item = "Sakura Chef Apron" },
	NIKKIFASHION   = { gold = 1500, gems = 150, item = "3x Whim Gacha Tickets" },
	HYBRIDECS      = { gold = 2000, gems = 200, item = "5x Whim Gacha Tickets" },
}
```

### Proposed Fix 2: `src/server/Services/WebInfoSyncService.lua`
Updated Luau module script:
```lua
--!strict
-- [[ModuleScript] WebInfoSyncService]]
-- Real-time game state serializer for Zundamon's Kitchen V2.
-- Syncs active daily/weekly challenges, gacha banners, promo codes, and community telemetry.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigurationFiles = Shared:WaitForChild("ConfigurationFiles")
local DailyChallengeConfig = require(ConfigurationFiles:WaitForChild("DailyChallengeConfig"))
local GachaConfig = require(ConfigurationFiles:WaitForChild("GachaConfig"))

local PromoCodeService = nil
pcall(function()
	PromoCodeService = require(ServerScriptService.Services:WaitForChild("PromoCodeService"))
end)

local WebInfoSyncService = {}

function WebInfoSyncService.exportGameStateJson(): string
	local activeCount = #Players:GetPlayers()
	if activeCount == 0 then
		activeCount = 125 -- Baseline telemetry fallback
	end

	-- Daily & Weekly Challenges
	local dailyPool = DailyChallengeConfig.dailyPool or {}
	local dailyChallenges = {}
	for i = 1, math.min(3, #dailyPool) do
		local c = dailyPool[i]
		table.insert(dailyChallenges, {
			id = c.id,
			name = c.title,
			target = c.description,
			goal = c.goal,
			reward = c.reward,
		})
	end

	local weeklyBossList = DailyChallengeConfig.weeklyBoss or {}
	local weeklyChallenges = {}
	for _, w in ipairs(weeklyBossList) do
		table.insert(weeklyChallenges, {
			id = w.id,
			name = w.title,
			target = w.description,
			goal = w.goal,
			reward = w.reward,
		})
	end

	-- Gacha Banners
	local gachaBanners = {}
	for _, b in ipairs(GachaConfig.banners or {}) do
		table.insert(gachaBanners, {
			id = b.id,
			banner_name = b.name,
			banner_type = "companion_spirit",
			cost_per_pull = b.costPerPull,
			featured_spirits = b.featuredItems,
			rates = {
				legendary = "5%",
				epic = "20%",
				rare = "75%",
			},
		})
	end

	-- Promo Codes
	local promoCodesList = {}
	if PromoCodeService and PromoCodeService.activeCodes then
		for code, data in pairs(PromoCodeService.activeCodes) do
			table.insert(promoCodesList, {
				code = code,
				reward_summary = string.format("+%d Gold, +%d Gems, %s", data.gold, data.gems, data.item),
				active = true,
			})
		end
	else
		promoCodesList = {
			{ code = "ZUNDAMOCHI2026", reward_summary = "+500 Gold, +50 Gems, 10x Fresh Zunda Mochi", active = true },
			{ code = "SOUPSEASON", reward_summary = "+1000 Gold, +100 Gems, 5x Wild Mushroom Pack", active = true },
			{ code = "KAWAIIZUNDA", reward_summary = "+750 Gold, +75 Gems, Sakura Chef Apron", active = true },
			{ code = "NIKKIFASHION", reward_summary = "+1500 Gold, +150 Gems, 3x Whim Gacha Tickets", active = true },
			{ code = "HYBRIDECS", reward_summary = "+2000 Gold, +200 Gems, 5x Whim Gacha Tickets", active = true },
		}
	end

	local payload = {
		last_updated = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		online_players = {
			count = activeCount,
			status = "online",
			version = "2.4.0 HYBRID ECS",
		},
		active_challenges = {
			daily = dailyChallenges,
			weekly = weeklyChallenges,
		},
		gacha_banners = gachaBanners,
		promo_codes = promoCodesList,
		global_stats = {
			total_dishes_cooked = 142850,
			edamame_harvested = 89420,
			total_gacha_pulls = 38920,
			active_event = {
				name = "🌸 Whims of Gourmet - Spring Festival",
				active = true,
				multiplier = "2.0x Style Points & Gold",
			},
		},
	}

	return HttpService:JSONEncode(payload)
end

return WebInfoSyncService
```

### Proposed JSON Spec: `site/api/game_info.json` & `docs/api/game_info.json`
```json
{
  "last_updated": "2026-07-22T13:52:33Z",
  "online_players": {
    "count": 125,
    "status": "online",
    "version": "2.4.0 HYBRID ECS"
  },
  "active_challenges": {
    "daily": [
      {
        "id": "dc_perfect_3",
        "name": "Perfect Timing",
        "target": "Cook 3 dishes with PERFECT timing",
        "goal": 3,
        "reward": {
          "gold": 120,
          "xp": 100,
          "style": 15
        }
      },
      {
        "id": "dc_cook_5",
        "name": "Cooking Spree",
        "target": "Cook 5 dishes",
        "goal": 5,
        "reward": {
          "gold": 80,
          "xp": 60,
          "style": 10
        }
      },
      {
        "id": "dc_gather_10",
        "name": "Gatherer",
        "target": "Gather 10 ingredients",
        "goal": 10,
        "reward": {
          "gold": 60,
          "xp": 50,
          "style": 8
        }
      }
    ],
    "weekly": [
      {
        "id": "wc_zunda_rush",
        "name": "Zunda Paradise Rush",
        "target": "Serve 5 Zunda Paradise dishes in Challenge Mode",
        "goal": 5,
        "reward": {
          "gold": 1000,
          "xp": 500,
          "style": 100,
          "items": [
            "Zundamon's Banquet"
          ]
        }
      }
    ]
  },
  "gacha_banners": [
    {
      "id": "gourmet_spring_2026",
      "banner_name": "🌸 Whims of Spring Gourmet",
      "banner_type": "companion_spirit",
      "cost_per_pull": 100,
      "featured_spirits": [
        "Zundamon_MagicalGirlForm",
        "Royal_Gourmet_Crown",
        "Ankomon_GoldTrim"
      ],
      "rates": {
        "legendary": "5%",
        "epic": "20%",
        "rare": "75%"
      }
    }
  ],
  "promo_codes": [
    {
      "code": "ZUNDAMOCHI2026",
      "reward_summary": "+500 Gold, +50 Gems, 10x Fresh Zunda Mochi",
      "active": true
    },
    {
      "code": "SOUPSEASON",
      "reward_summary": "+1000 Gold, +100 Gems, 5x Wild Mushroom Pack",
      "active": true
    },
    {
      "code": "KAWAIIZUNDA",
      "reward_summary": "+750 Gold, +75 Gems, Sakura Chef Apron",
      "active": true
    },
    {
      "code": "NIKKIFASHION",
      "reward_summary": "+1500 Gold, +150 Gems, 3x Whim Gacha Tickets",
      "active": true
    },
    {
      "code": "HYBRIDECS",
      "reward_summary": "+2000 Gold, +200 Gems, 5x Whim Gacha Tickets",
      "active": true
    }
  ],
  "global_stats": {
    "total_dishes_cooked": 142850,
    "edamame_harvested": 89420,
    "total_gacha_pulls": 38920,
    "active_event": {
      "name": "🌸 Whims of Gourmet - Spring Festival",
      "active": true,
      "multiplier": "2.0x Style Points & Gold"
    }
  }
}
```

---

## 5. Verification Method

### 5.1 JSON Schema & Node Sync Verification
1. Run Node sync runner in terminal:
   ```powershell
   node site/sync_site.js --verbose
   ```
2. Verify output confirms copying or syncing of `site/api/game_info.json` -> `docs/api/game_info.json`.
3. Validate JSON formatting:
   ```powershell
   node -e "JSON.parse(fs.readFileSync('docs/api/game_info.json'))"
   ```

### 5.2 Luau Service Verification (in Studio / Luau runner)
1. Execute `WebInfoSyncService.exportGameStateJson()` in Roblox Studio command bar or Luau test runner:
   ```lua
   local WebInfoSyncService = require(game:GetService("ServerScriptService").Services.WebInfoSyncService)
   local json = WebInfoSyncService.exportGameStateJson()
   print(json)
   ```
2. Verify that no `attempt to index nil with number` error occurs.
3. Verify that the output string contains valid JSON with `online_players`, `active_challenges`, `gacha_banners`, `promo_codes`, and `global_stats`.

### 5.3 Invalidation Conditions
* `DailyChallengeConfig` changing table names without updating `WebInfoSyncService`.
* Running `node site/sync_site.js` when `site/api/game_info.json` is missing.
