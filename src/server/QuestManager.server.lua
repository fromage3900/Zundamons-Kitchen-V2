local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RE      = RS:WaitForChild("RemoteEvents")
local ev = RE:FindFirstChild("UpdateQuests")
if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "UpdateQuests"; ev.Parent = RE end
local qcEv = RE:FindFirstChild("QuestCompleted")
if not qcEv then qcEv = Instance.new("RemoteEvent"); qcEv.Name = "QuestCompleted"; qcEv.Parent = RE end
local qcBatch = RE:FindFirstChild("QuestCompletedBatch")
if not qcBatch then qcBatch = Instance.new("RemoteEvent"); qcBatch.Name = "QuestCompletedBatch"; qcBatch.Parent = RE end
-- Side dialogue trigger (client listens for this)
local sideDlgRE = RE:FindFirstChild("TriggerSideDialogue")
if not sideDlgRE then sideDlgRE = Instance.new("RemoteEvent"); sideDlgRE.Name = "TriggerSideDialogue"; sideDlgRE.Parent = RE end

-- Helper: fire side dialogue to a player
local function triggerSideDialogue(player, key)
	if not player or not key then return end
	pcall(function() sideDlgRE:FireClient(player, key) end)
end

local QuestConfig = require(RS.ConfigurationFiles.QuestConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local QUESTS = QuestConfig.quests
for _, q in ipairs(QuestConfig.default_quests) do
	table.insert(QUESTS, q)
end

local function questCheck(d, q, player)
	local t = q.target
	local cur = 0
	if q.type == "serve" then
		cur = d.guests_served or 0
	elseif q.type == "cook" then
		if q.target_item then
			cur = d[q.target_item] or 0
		else
			local count = 0
			for k, v in pairs(d) do
				if type(v) == "number" and k ~= "gold" and k ~= "total_gold_earned" and k ~= "guests_served"
					and k ~= "perfect_cooks" and k ~= "great_cooks" and k ~= "companion_affection"
					and k ~= "companion_chats" and k ~= "cooking_streak" and k ~= "max_cooking_streak"
					and k ~= "tier" and k ~= "recipes_unlocked_count" then
					count = count + v
				end
			end
			-- crude: count items/recipes total
			for _, r in pairs(QuestConfig.quests) do if r.type == "cook" and r.target_item and d[r.target_item] then
				count = count - (d[r.target_item] or 0) end end
			cur = 0
		end
	elseif q.type == "cook_perfect" then
		cur = d.perfect_cooks or 0
	elseif q.type == "cook_great" then
		cur = d.great_cooks or 0
	elseif q.type == "gather" then
		if q.target_item then
			cur = d[q.target_item] or 0
		else
			local t2 = 0
			if d.Apple then t2 = t2 + d.Apple end
			if d.Wheat then t2 = t2 + d.Wheat end
			cur = t2
		end
	elseif q.type == "earn_gold" then
		cur = d.total_gold_earned or 0
	elseif q.type == "companion_chat" then
		cur = d.companion_chats or 0
	elseif q.type == "companion_affection" then
		cur = d.companion_affection or 0
	elseif q.type == "visit_zone" then
		local zones = d.zones_visited or {}
		cur = 0
		if q.target_zone then
			cur = zones[q.target_zone] and 1 or 0
		end
	elseif q.type == "visit_zones_unique" then
		local zones = d.zones_visited or {}
		cur = 0
		for _, _ in pairs(zones) do cur = cur + 1 end
	elseif q.type == "npc_chat" then
		cur = d.npc_chats and d.npc_chats[q.target_npc] or 0
	elseif q.type == "cook_unique" then
		local seen = {}
		for _, r in pairs(QuestConfig.quests) do
			if r.type == "cook" and r.target_item and d[r.target_item] and d[r.target_item] > 0 then
				seen[r.target_item] = true end end
		for k, v in pairs(d) do
			if type(v) == "number" and v > 0 and not k:match("_") then
				-- heuristically, any numeric key >0 that matches a recipe
			end
		end
		-- count recipes tracked in recipes_served_count
		local rsc = d.recipes_served_count or {}
		for _, _ in pairs(rsc) do cur = cur + 1 end
	elseif q.type == "cook_unique_zunda" then
		local rsc = d.recipes_served_count or {}
		local zunda_recipes = { ["Zunda Bread"] = true, ["Zunda Mochi"] = true, ["Zunda Paradise"] = true,
			["Sweet Pea Cake"] = true, ["Pea Flower Tea"] = true, ["Edamame Snack"] = true }
		for name in pairs(rsc) do if zunda_recipes[name] then cur = cur + 1 end end
	elseif q.type == "cook_quality" then
		local qualField = q.quality == "perfect" and "perfect_cooks" or "great_cooks"
		cur = d[qualField] or 0
	elseif q.type == "cook_speed" then
		cur = d.speed_cooks or 0
	elseif q.type == "cook_unique_seasonal" then
		local rsc = d.recipes_served_count or {}
		local seasonal = { ["Seasonal Salad"] = true, ["Warm Winter Stew"] = true }
		for name in pairs(rsc) do if seasonal[name] then cur = cur + 1 end end
	elseif q.type == "gather_unique" then
		local gathered = d.gathered_items or {}
		cur = 0
		for _ in pairs(gathered) do cur = cur + 1 end
	elseif q.type == "set_companion" then
		local comps = d.companions_set or {}
		cur = comps[q.target_companion] and 1 or 0
	elseif q.type == "npc_chat_all" then
		local npcs = d.npc_chats or {}
		cur = 0
		for _ in pairs(npcs) do cur = cur + 1 end
	end
	return cur, t
end

-- Daily login streak rewards
local function checkDailyLogin(player)
	local d = PlayerDataService.get(player)
	if not d then return end

	local today = os.date("%Y-%m-%d")
	local lastLogin = d.last_login_date or ""

	-- Calculate streak
	if lastLogin ~= today then
		if d.login_streak then
			-- Check if yesterday's login to continue streak
			local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
			if lastLogin == yesterday then
				d.login_streak = d.login_streak + 1
			else
				d.login_streak = 1
			end
		else
			d.login_streak = 1
		end
		d.last_login_date = today

		-- Award streak rewards
		local streak = d.login_streak
		local goldReward = 50
		local xpReward = 50
		local buffDuration = 0

		if streak >= 7 then
			goldReward = 250
			xpReward = 200
			buffDuration = 3600 -- 1 hour companion buff
		elseif streak >= 3 then
			goldReward = 100
			xpReward = 100
		end

		d.gold = (d.gold or 0) + goldReward
		d.chef = d.chef or { level = 1, xp = 0 }
		d.chef.xp = (d.chef.xp or 0) + xpReward

		-- Apply companion buff duration
		if buffDuration > 0 then
			d.active_buff = os.time() + buffDuration
		end

		print("[QuestManager] Daily login streak " .. streak .. " for " .. player.Name .. " (+" .. goldReward .. "g)")
	end
end

local function eval(player)
	local d = PlayerDataService.get(player)
	if not d then return end
	local prog = {}
	local batch = {}
	for _, q in ipairs(QUESTS) do
		local cur, goal = questCheck(d, q, player)
		prog[q.id] = { current = cur, goal = goal, done = cur >= goal }
		if cur >= goal then
			if not d.quests_completed then d.quests_completed = {} end
			if not d.quests_completed[q.id] then
				d.quests_completed[q.id] = true
				d.gold = (d.gold or 0) + (q.rewards.gold or 0)
				print("[QuestManager] Quest complete: " .. q.id .. " for " .. player.Name .. " +" .. (q.rewards.gold or 0) .. "g")
				table.insert(batch, {
					id = q.id,
					title = q.icon .. " " .. q.name,
					reward = q.rewards.gold or 0,
					desc = q.description,
					unlock_hint = q.unlock_hint or "",
				})
				-- Chain completion celebration
				if q.chain_id then
					if not d.chains_progress then d.chains_progress = {} end
					if not d.chains_progress[q.chain_id] then d.chains_progress[q.chain_id] = {} end
					d.chains_progress[q.chain_id][q.chain_step] = true
					local allDone = true
					local chainBonus = 0
					for _, cq in ipairs(QUESTS) do
						if cq.chain_id == q.chain_id then
							if not d.chains_progress[q.chain_id][cq.chain_step] then
								allDone = false
							end
							chainBonus = chainBonus + (cq.rewards.gold or 0)
						end
					end
					if allDone then
						if not d.chains_completed then d.chains_completed = {} end
						if not d.chains_completed[q.chain_id] then
							d.chains_completed[q.chain_id] = true
							local celebrationBonus = math.floor(chainBonus * 0.3)
							d.gold = (d.gold or 0) + celebrationBonus
							print("[QuestManager] Chain complete: " .. q.chain_id .. " for " .. player.Name .. " +" .. celebrationBonus .. "g (bonus)")
							triggerSideDialogue(player, "quest_chain_complete")
						end
					end
				end
			end
		end
	end
	if #batch > 0 then
		qcBatch:FireClient(player, batch)
	end
	ev:FireClient(player, QUESTS, prog)
end

local rewarded = {}
local function initPlayer(p)
	rewarded[p.Name] = {}
	PlayerDataService.getOrCreate(p)
	task.wait(7)
	while p and p.Parent do
		task.wait(4)
		eval(p)
	end
end

Players.PlayerAdded:Connect(initPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() initPlayer(p) end)
end

-- Companion chat tracking
local chatEv = RE:FindFirstChild("CompanionChat")
if not chatEv then
	chatEv = Instance.new("RemoteEvent"); chatEv.Name = "CompanionChat"; chatEv.Parent = RE
end
local chatTimestamps = {}
chatEv.OnServerEvent:Connect(function(player)
	local now = os.clock()
	local last = chatTimestamps[player]
	if last and now - last < 2 then return end
	chatTimestamps[player] = now
	local d = PlayerDataService.getOrCreate(player)
	d.companion_chats = (d.companion_chats or 0) + 1
	d.companion_affection = math.min((d.companion_affection or 0) + 1, 100)
end)

-- NPC chat tracking
local npcChatTimestamps = {}
local npcChat = RE:FindFirstChild("NPCChat")
if not npcChat then
	npcChat = Instance.new("RemoteEvent"); npcChat.Name = "NPCChat"; npcChat.Parent = RE
end
npcChat.OnServerEvent:Connect(function(player, npcName)
	if typeof(npcName) ~= "string" then return end
	local now = os.clock()
	local last = npcChatTimestamps[player]
	if last and now - last < 2 then return end
	npcChatTimestamps[player] = now
	local d = PlayerDataService.getOrCreate(player)
	if not d.npc_chats then d.npc_chats = {} end
	d.npc_chats[npcName] = (d.npc_chats[npcName] or 0) + 1
end)

print("[QuestManager v2] Dynamic quest engine — uses QuestConfig, tracks companion/cooking quality")
