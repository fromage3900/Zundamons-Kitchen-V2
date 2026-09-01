--!strict
-- [[ModuleScript] RhythmBeatmapConfig]]
-- Multi-lane rhythm chart configuration & deterministic beatmap generator.
-- Culinary action lanes: CHOP (D), STIR (F), SIMMER (J), SEASON (K) with Infinity Nikki pastel aesthetics.

export type LaneDef = {
	id: number,
	name: string,
	action: string,
	icon: string,
	key: string,
	keyCode: Enum.KeyCode,
	color: Color3,
	description: string,
}

export type Note = {
	index: number,
	targetTime: number,
	laneId: number,
	action: string,
	icon: string,
	key: string,
	duration: number?,
}

export type Chart = {
	recipe: string,
	bpm: number,
	difficulty: string,
	duration: number,
	totalNotes: number,
	startDelay: number,
	notes: { Note },
}

local RhythmBeatmapConfig = {}

-- ── 4 Culinary Action Lanes ──────────────────────────────────────────────────
-- Pastel color palette: Zunda green (#A0D296), gold (#FFC850), pink (#FF96C8), mint (#91D7C3)
RhythmBeatmapConfig.Lanes = {
	CHOP = {
		id = 1,
		name = "Chop",
		action = "Chop",
		icon = "🔪",
		key = "D",
		keyCode = Enum.KeyCode.D,
		color = Color3.fromRGB(160, 210, 150),
		description = "Chop fresh ingredients with precision",
	},
	STIR = {
		id = 2,
		name = "Stir",
		action = "Stir",
		icon = "🥣",
		key = "F",
		keyCode = Enum.KeyCode.F,
		color = Color3.fromRGB(255, 200, 80),
		description = "Stir the pot to blend rich flavors",
	},
	SIMMER = {
		id = 3,
		name = "Simmer",
		action = "Simmer",
		icon = "🔥",
		key = "J",
		keyCode = Enum.KeyCode.J,
		color = Color3.fromRGB(255, 150, 200),
		description = "Control the flame to simmer to perfection",
	},
	SEASON = {
		id = 4,
		name = "Season",
		action = "Season",
		icon = "🧂",
		key = "K",
		keyCode = Enum.KeyCode.K,
		color = Color3.fromRGB(145, 215, 195),
		description = "Add a pinch of seasoning for the finishing touch",
	},
}

RhythmBeatmapConfig.LaneById = {
	[1] = RhythmBeatmapConfig.Lanes.CHOP,
	[2] = RhythmBeatmapConfig.Lanes.STIR,
	[3] = RhythmBeatmapConfig.Lanes.SIMMER,
	[4] = RhythmBeatmapConfig.Lanes.SEASON,
}

RhythmBeatmapConfig.LaneList = {
	RhythmBeatmapConfig.Lanes.CHOP,
	RhythmBeatmapConfig.Lanes.STIR,
	RhythmBeatmapConfig.Lanes.SIMMER,
	RhythmBeatmapConfig.Lanes.SEASON,
}

function RhythmBeatmapConfig.getLane(identifier: any): LaneDef?
	if type(identifier) == "number" then
		return RhythmBeatmapConfig.LaneById[identifier]
	elseif type(identifier) == "string" then
		local upper = string.upper(identifier)
		if RhythmBeatmapConfig.Lanes[upper] then
			return RhythmBeatmapConfig.Lanes[upper]
		end
		for _, lane in ipairs(RhythmBeatmapConfig.LaneList) do
			if string.upper(lane.name) == upper or string.upper(lane.key) == upper then
				return lane
			end
		end
	end
	return nil
end

-- ── Difficulty Presets ───────────────────────────────────────────────────────
RhythmBeatmapConfig.Difficulties = {
	easy = {
		name = "Easy",
		bpmMultiplier = 0.85,
		noteDensityMultiplier = 0.75,
		minIntervalBeats = 1.0,
		syncopationChance = 0.0,
	},
	normal = {
		name = "Normal",
		bpmMultiplier = 1.0,
		noteDensityMultiplier = 1.0,
		minIntervalBeats = 0.5,
		syncopationChance = 0.15,
	},
	hard = {
		name = "Hard",
		bpmMultiplier = 1.15,
		noteDensityMultiplier = 1.4,
		minIntervalBeats = 0.5,
		syncopationChance = 0.35,
	},
	expert = {
		name = "Expert",
		bpmMultiplier = 1.3,
		noteDensityMultiplier = 1.8,
		minIntervalBeats = 0.25,
		syncopationChance = 0.5,
	},
}

-- ── Deterministic PRNG ───────────────────────────────────────────────────────
local function stringHash(str: string): number
	local hash = 5381
	for i = 1, #str do
		hash = ((hash * 33) + string.byte(str, i)) % 2147483647
	end
	return hash
end

local function makeRng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
end

-- ── Curated Signature Recipe Patterns ────────────────────────────────────────
-- Structured step motifs that evoke real cooking rituals (e.g. Chop -> Stir -> Simmer -> Season)
local RECIPE_MOTIFS: { [string]: { bpm: number, lanePattern: { number } } } = {
	["Bread"] = {
		bpm = 100,
		lanePattern = { 1, 2, 1, 2, 3, 2, 4 }, -- Chop/knead -> Stir -> Chop/knead -> Stir -> Simmer/bake -> Stir -> Season
	},
	["Apple Pie"] = {
		bpm = 110,
		lanePattern = { 1, 1, 2, 1, 2, 3, 4, 3 },
	},
	["Zunda Bread"] = {
		bpm = 115,
		lanePattern = { 1, 2, 1, 2, 4, 3, 2, 4 },
	},
	["Royal Stew"] = {
		bpm = 118,
		lanePattern = { 1, 1, 2, 3, 2, 3, 4, 4 },
	},
	["Zunda Mochi"] = {
		bpm = 128,
		lanePattern = { 1, 2, 1, 2, 1, 2, 4, 4 }, -- Fast pounding rhythm
	},
	["Edamame Snack"] = {
		bpm = 132,
		lanePattern = { 1, 3, 4, 1, 3, 4 },
	},
	["Fancy Pie"] = {
		bpm = 122,
		lanePattern = { 1, 1, 2, 3, 1, 2, 3, 4, 4 },
	},
	["Zundamon's Banquet"] = {
		bpm = 138,
		lanePattern = { 1, 2, 3, 4, 1, 2, 3, 4, 1, 4 },
	},
	["Sweet Pea Cake"] = {
		bpm = 116,
		lanePattern = { 1, 2, 2, 3, 1, 2, 4, 4 },
	},
	["Pea Flower Tea"] = {
		bpm = 105,
		lanePattern = { 1, 3, 2, 4, 3, 4 },
	},
	["Ultimate Feast"] = {
		bpm = 144,
		lanePattern = { 1, 1, 2, 2, 3, 3, 4, 4, 1, 2, 3, 4 },
	},
	["Zunda Paradise"] = {
		bpm = 150,
		lanePattern = { 1, 2, 1, 3, 2, 4, 1, 3, 2, 4, 4, 4 },
	},
	["Sumimon's Ink-Wash Soba"] = {
		bpm = 125,
		lanePattern = { 1, 1, 2, 1, 3, 4, 2, 4 },
	},
	["Kagamon's Glazed Mirror Mochi"] = {
		bpm = 120,
		lanePattern = { 1, 2, 1, 2, 3, 4, 4, 3 },
	},
	["Suzurimon's Bell Chime Dango"] = {
		bpm = 112,
		lanePattern = { 1, 2, 4, 1, 2, 4, 3, 4 },
	},
	["Wasabimon's Pungent Zunda Soba"] = {
		bpm = 135,
		lanePattern = { 1, 1, 1, 2, 3, 4, 1, 4 },
	},
	["Matchamon's Ceremonial Froth Bowl"] = {
		bpm = 108,
		lanePattern = { 2, 2, 2, 3, 2, 2, 4, 4 },
	},
	["Shisomon's Pickled Perilla Wrap"] = {
		bpm = 115,
		lanePattern = { 1, 4, 1, 4, 2, 3, 4 },
	},
}

-- ── Chart Generator ─────────────────────────────────────────────────────────
function RhythmBeatmapConfig.getChart(recipeName: string, durationSeconds: number?, difficulty: string?): Chart
	local cleanName = if type(recipeName) == "string" and recipeName ~= "" then recipeName else "Zunda Mochi"
	local diffKey = if type(difficulty) == "string" and RhythmBeatmapConfig.Difficulties[string.lower(difficulty)]
		then string.lower(difficulty)
		else "normal"
	local diffConfig = RhythmBeatmapConfig.Difficulties[diffKey]

	local nameHash = stringHash(cleanName .. ":" .. diffKey)
	local rng = makeRng(nameHash)

	-- Base BPM resolution
	local motif = RECIPE_MOTIFS[cleanName]
	local baseBpm = if motif then motif.bpm else (110 + (nameHash % 31))
	local finalBpm = math.round(baseBpm * diffConfig.bpmMultiplier)
	local beatDuration = 60 / finalBpm

	-- Lead-in countdown window before first note hits
	local startDelay = 2.0

	-- Total duration
	local totalDuration = if type(durationSeconds) == "number" and durationSeconds > 0
		then math.max(durationSeconds, 3.0)
		else 8.0

	local usableDuration = math.max(totalDuration - 0.5, 2.0)
	local totalBeats = math.floor(usableDuration / beatDuration)

	local notes: { Note } = {}
	local noteIndex = 0
	local currentBeat = 0
	local lastLaneId = 0

	local motifPattern = if motif then motif.lanePattern else nil
	local patternLen = if motifPattern then #motifPattern else 0

	while currentBeat < totalBeats do
		noteIndex += 1
		local targetTime = startDelay + (currentBeat * beatDuration)

		-- Select lane
		local laneId: number
		if motifPattern and patternLen > 0 then
			local patIdx = ((noteIndex - 1) % patternLen) + 1
			laneId = motifPattern[patIdx]
		else
			-- Procedural lane selection with natural culinary transitions
			local r = rng()
			if lastLaneId == 0 then
				laneId = math.floor(r * 4) + 1
			else
				-- Favor progressive flow (Chop -> Stir -> Simmer -> Season) with slight variations
				local step = if r < 0.5 then 1 elseif r < 0.75 then 2 elseif r < 0.9 then -1 else 0
				laneId = ((lastLaneId - 1 + step) % 4) + 1
			end
		end
		lastLaneId = laneId

		local laneDef = RhythmBeatmapConfig.LaneById[laneId] or RhythmBeatmapConfig.Lanes.CHOP

		table.insert(notes, {
			index = noteIndex,
			targetTime = math.round(targetTime * 1000) / 1000,
			laneId = laneId,
			action = laneDef.action,
			icon = laneDef.icon,
			key = laneDef.key,
			duration = 0,
		})

		-- Advance beat step
		local stepBeats = 1.0
		local rSub = rng()
		if diffConfig.syncopationChance > 0 and rSub < diffConfig.syncopationChance then
			-- 8th note or triplet subdivision
			stepBeats = if rSub < (diffConfig.syncopationChance * 0.4) then 0.5 else 1.0
		end

		stepBeats = math.max(stepBeats, diffConfig.minIntervalBeats)
		currentBeat += stepBeats
	end

	-- Safety fallback if no notes generated
	if #notes == 0 then
		for i = 1, 4 do
			local laneDef = RhythmBeatmapConfig.LaneById[i]
			table.insert(notes, {
				index = i,
				targetTime = startDelay + ((i - 1) * beatDuration),
				laneId = i,
				action = laneDef.action,
				icon = laneDef.icon,
				key = laneDef.key,
				duration = 0,
			})
		end
	end

	return {
		recipe = cleanName,
		bpm = finalBpm,
		difficulty = diffKey,
		duration = totalDuration + startDelay,
		totalNotes = #notes,
		startDelay = startDelay,
		notes = notes,
	}
end

return RhythmBeatmapConfig
