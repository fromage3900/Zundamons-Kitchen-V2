-- [[ModuleScript] ZundapalContextBuilder]]
-- Builds live player context for LLM prompts and rule-based proactive hints.
-- Side-effect free: pass in PlayerDataService snapshot tables only.

local CraftConfig = require(script.Parent:WaitForChild("CraftConfig"))
local QuestConfig = require(script.Parent:WaitForChild("QuestConfig"))
local QuestProgress = require(script.Parent:WaitForChild("QuestProgress"))
local ProgressionConfig = require(script.Parent:WaitForChild("ProgressionConfig"))
local ZoneVisitConfig = require(script.Parent:WaitForChild("ZoneVisitConfig"))
local CompanionConfig = require(script.Parent:WaitForChild("CompanionConfig"))

local ZundapalContextBuilder = {}

local SKIP_INVENTORY_KEYS = {
	Gold = true,
	current_gold = true,
	guests_served = true,
	zones_visited = true,
	active_companion = true,
	total_gold_earned = true,
	tier = true,
	completed_quests = true,
	stats = true,
	recipes_unlocked = true,
	cosmetics_unlocked = true,
	furniture_unlocked = true,
	locations_unlocked = true,
	owned_clothing = true,
	owned_decorations = true,
	decoration_placements = true,
	owned_plot = true,
	recipes_unlocked_count = true,
	recipes_served_count = true,
	daily = true,
	achievements = true,
	compendium = true,
	tier_points = true,
}

local ZONE_LABELS = {
	village = "Village / Market Promenade",
	kitchen = "Kitchen Court",
	eastpeaks = "East Peaks / Hilltop Shrine",
	mystic = "Ancient Ruins (Mystic)",
}

local COMPANION_LABELS = {
	zundamon = "Zundamon",
	zundacat = "Zundacat",
	zundabunny = "Zundabunny",
	tantanmon = "Tantanmon",
	ankomon = "Ankomon",
	cardamon = "Cardamon",
	antimon = "Antimon",
	sakuradamon = "Sakuradamon",
}

local function tierName(tier: number): string
	local milestone = ProgressionConfig.milestones[tier]
	if milestone then
		return milestone.name
	end
	return "Chef"
end

local function listVisitedZones(zones: { [string]: any }?): { string }
	local visited = {}
	if type(zones) ~= "table" then
		return visited
	end
	for key, value in pairs(zones) do
		if value then
			table.insert(visited, ZONE_LABELS[key] or key)
		end
	end
	table.sort(visited)
	return visited
end

local function listUnvisitedZones(zones: { [string]: any }?): { string }
	local visited = zones or {}
	local missing = {}
	for _, key in ipairs(ZoneVisitConfig.canonical_zones) do
		if not visited[key] then
			table.insert(missing, ZONE_LABELS[key] or key)
		end
	end
	return missing
end

local function inventorySummary(data: { [string]: any }): { string }
	local lines = {}
	for key, value in pairs(data) do
		if not SKIP_INVENTORY_KEYS[key] and type(value) == "number" and value > 0 then
			table.insert(lines, key .. " x" .. tostring(value))
		end
	end
	table.sort(lines)
	local maxLines = 12
	if #lines > maxLines then
		local trimmed = {}
		for i = 1, maxLines do
			trimmed[i] = lines[i]
		end
		table.insert(trimmed, "(+" .. (#lines - maxLines) .. " more)")
		return trimmed
	end
	return lines
end

local function craftableNow(data: { [string]: any }): { string }
	local craftable = {}
	for recipeName, ingredients in pairs(CraftConfig.recipes) do
		local canCraft = true
		for ingredient, amount in pairs(ingredients) do
			local owned = data[ingredient]
			if ingredient == "Gold" then
				owned = data.Gold or data.current_gold or 0
			end
			if type(owned) ~= "number" or owned < amount then
				canCraft = false
				break
			end
		end
		if canCraft then
			table.insert(craftable, recipeName)
		end
	end
	table.sort(craftable)
	return craftable
end

local function activeQuestLines(data: { [string]: any }): { string }
	local completed = data.completed_quests or {}
	local rows = {}

	for _, quest in ipairs(QuestConfig.default_quests) do
		if not completed[quest.id] then
			local current, goal = QuestProgress.evaluate(quest, data)
			if goal > 0 and current < goal then
				local pct = math.floor((current / goal) * 100)
				table.insert(rows, {
					sort = pct,
					line = string.format(
						"%s (%s): %d/%d — %s",
						quest.name,
						quest.id,
						current,
						goal,
						quest.description or ""
					),
				})
			end
		end
	end

	table.sort(rows, function(a, b)
		return a.sort > b.sort
	end)

	local lines = {}
	for i = 1, math.min(5, #rows) do
		lines[i] = rows[i].line
	end
	return lines
end

function ZundapalContextBuilder.buildSnapshot(data: { [string]: any }, env: { [string]: any }?): { [string]: any }
	env = env or {}
	local stats = data.stats or {}
	local zones = data.zones_visited or {}
	local activeKey = data.active_companion or "zundamon"
	local companionDef = CompanionConfig.getCompanion(activeKey)

	return {
		gold = data.Gold or data.current_gold or 0,
		totalGoldEarned = data.total_gold_earned or 0,
		guestsServed = data.guests_served or 0,
		tier = data.tier or 1,
		tierName = tierName(data.tier or 1),
		activeCompanion = COMPANION_LABELS[activeKey] or companionDef.displayName,
		activeCompanionKey = activeKey,
		activeCompanionBuff = companionDef.buff and companionDef.buff.description or "none",
		activeCompanionPersona = companionDef.llmPersona,
		plotOwned = data.owned_plot,
		decorationsOwned = type(data.owned_decorations) == "table" and #data.owned_decorations or 0,
		zonesVisited = listVisitedZones(zones),
		zonesRemaining = listUnvisitedZones(zones),
		inventory = inventorySummary(data),
		craftableNow = craftableNow(data),
		activeQuests = activeQuestLines(data),
		completedQuestCount = (function()
			local n = 0
			for _, done in pairs(data.completed_quests or {}) do
				if done then
					n += 1
				end
			end
			return n
		end)(),
		perfectCooks = stats.perfectCooks or 0,
		companionChats = stats.companion_chats or 0,
		npcChats = stats.npc_chats or 0,
		dailyQuestTitle = data.daily and data.daily.todayQuestId,
		dailyQuestProgress = data.daily and data.daily.todayProgress,
		hour = env.hour,
		weather = env.weather,
		lastAction = env.lastAction,
		lastPayload = env.lastPayload,
	}
end

function ZundapalContextBuilder.formatForPrompt(snapshot: { [string]: any }, playerName: string): string
	local lines = {
		"=== LIVE PLAYER CONTEXT (use for personalized advice; do not invent stats) ===",
		"Player name: " .. playerName,
		"Gold: " .. tostring(snapshot.gold) .. " | Guests served: " .. tostring(snapshot.guestsServed),
		"Chef tier: " .. tostring(snapshot.tier) .. " (" .. tostring(snapshot.tierName) .. ")",
		"Active companion form: " .. tostring(snapshot.activeCompanion),
		"Perfect cooks: " .. tostring(snapshot.perfectCooks) .. " | Chats with you: " .. tostring(
			snapshot.companionChats
		) .. " | NPC chats: " .. tostring(snapshot.npcChats),
	}

	if snapshot.activeCompanionBuff and snapshot.activeCompanionBuff ~= "none" then
		table.insert(lines, "Active companion buff: " .. tostring(snapshot.activeCompanionBuff))
	end
	if snapshot.activeCompanionPersona then
		table.insert(lines, "Companion persona: " .. tostring(snapshot.activeCompanionPersona))
	end

	if snapshot.plotOwned then
		table.insert(lines, "Owned plot: #" .. tostring(snapshot.plotOwned))
	end
	if snapshot.decorationsOwned > 0 then
		table.insert(lines, "Decorations owned: " .. tostring(snapshot.decorationsOwned))
	end
	if snapshot.hour then
		table.insert(lines, "In-game hour: " .. tostring(snapshot.hour))
	end
	if snapshot.weather then
		table.insert(lines, "Weather: " .. tostring(snapshot.weather))
	end

	if #snapshot.zonesVisited > 0 then
		table.insert(lines, "Zones visited: " .. table.concat(snapshot.zonesVisited, "; "))
	end
	if #snapshot.zonesRemaining > 0 then
		table.insert(lines, "Zones not yet visited: " .. table.concat(snapshot.zonesRemaining, "; "))
	end
	if #snapshot.inventory > 0 then
		table.insert(lines, "Inventory highlights: " .. table.concat(snapshot.inventory, ", "))
	end
	if #snapshot.craftableNow > 0 then
		table.insert(lines, "Can craft right now: " .. table.concat(snapshot.craftableNow, ", "))
	end
	if #snapshot.activeQuests > 0 then
		table.insert(lines, "Active quests (QuestConfig/QuestManager):")
		for _, questLine in ipairs(snapshot.activeQuests) do
			table.insert(lines, "  - " .. questLine)
		end
	end
	if snapshot.dailyQuestTitle then
		table.insert(
			lines,
			"Daily quest: "
				.. tostring(snapshot.dailyQuestTitle)
				.. " progress "
				.. tostring(snapshot.dailyQuestProgress or 0)
		)
	end
	if snapshot.lastAction then
		table.insert(lines, "Most recent gameplay event: " .. tostring(snapshot.lastAction))
		if snapshot.lastPayload then
			local parts = {}
			for key, value in pairs(snapshot.lastPayload) do
				table.insert(parts, tostring(key) .. "=" .. tostring(value))
			end
			if #parts > 0 then
				table.insert(lines, "Event details: " .. table.concat(parts, ", "))
			end
		end
	end

	table.insert(lines, "=== END CONTEXT ===")
	return table.concat(lines, "\n")
end

function ZundapalContextBuilder.suggestProactiveHint(
	action: string,
	payload: { [string]: any }?,
	snapshot: { [string]: any }
): string?
	payload = payload or {}

	if action == "craft" then
		local recipe = payload.recipe
		local quality = payload.quality
		if quality == "perfect" then
			return "Perfect " .. tostring(recipe or "dish") .. "! ✨ That timing was chef's kiss~"
		end
		if recipe and table.find(snapshot.craftableNow, recipe) then
			return "Nice " .. recipe .. "! You still have ingredients to craft more~"
		end
		if #snapshot.craftableNow > 0 then
			return "You could craft " .. snapshot.craftableNow[1] .. " next with what you're carrying~ 🍳"
		end
	elseif action == "serve" then
		if snapshot.guestsServed == 1 then
			return "First guest served~ You're officially a village chef now! 🧑‍🍳"
		end
		if snapshot.activeCompanionKey == "ankomon" then
			return "Ankomon's buff is boosting your gold from guests~ Keep serving! 💰"
		end
		if #snapshot.craftableNow > 0 then
			return "Guests love your cooking! Maybe cook " .. snapshot.craftableNow[1] .. " for the next one~"
		end
	elseif action == "gather" then
		local item = payload.item
		if snapshot.activeCompanionKey == "antimon" then
			return "Your Antimon buff might snag an extra gather drop~ Keep collecting! 🌿"
		end
		if item == "Zunda Pea" then
			return "Zunda Peas! 🫛 Those are perfect for Zunda Mochi~"
		elseif item == "Edamame Pod" then
			return "Edamame~ Roast them with a pinch of salt for a snack! 🌿"
		elseif item == "Sweet Pea" then
			return "Sweet Peas are so cute~ Save some for Sweet Pea Cake! ✨"
		end
	elseif action == "login" then
		if #snapshot.activeQuests > 0 then
			return "Welcome back~ Your quest board has fresh goals waiting! 📋"
		end
	end

	if #snapshot.zonesRemaining > 0 and snapshot.guestsServed >= 3 then
		return "Have you visited " .. snapshot.zonesRemaining[1] .. " yet? There might be secrets~ 🗺"
	end

	return nil
end

return ZundapalContextBuilder
