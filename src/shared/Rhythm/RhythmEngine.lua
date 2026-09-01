--!strict
-- [[ModuleScript] RhythmEngine]]
-- Core deterministic rhythm evaluation, timing windows, combo multipliers, and scoring formulas.
-- Shared across client local prediction and server-authoritative cooking verification.

export type Judgment = "PERFECT" | "GREAT" | "GOOD" | "MISS"

export type TimingWindows = {
	perfect: number,
	great: number,
	good: number,
	multiplier: number,
}

export type HitDetails = {
	judgment: Judgment,
	offset: number,
	baseScore: number,
	multiplier: number,
	score: number,
	isHit: boolean,
}

export type ScoreCounts = {
	PERFECT: number,
	GREAT: number,
	GOOD: number,
	MISS: number,
	total: number,
	perfect: number,
	great: number,
	good: number,
	miss: number,
}

export type ScoreResult = {
	totalScore: number,
	maxPossibleScore: number,
	accuracy: number,
	maxCombo: number,
	finalCombo: number,
	grade: string,
	quality: string,
	counts: ScoreCounts,
}

local RhythmEngine = {}

-- ── Constants ────────────────────────────────────────────────────────────────
RhythmEngine.Judgments = {
	PERFECT = "PERFECT" :: Judgment,
	GREAT = "GREAT" :: Judgment,
	GOOD = "GOOD" :: Judgment,
	MISS = "MISS" :: Judgment,
}

RhythmEngine.BASE_WINDOWS = {
	PERFECT = 0.12, -- Baseline +/- 0.12s
	GREAT = 0.28, -- Baseline +/- 0.28s
	GOOD = 0.45, -- Baseline +/- 0.45s
}

RhythmEngine.BASE_SCORES = {
	PERFECT = 1000,
	GREAT = 600,
	GOOD = 300,
	MISS = 0,
}

RhythmEngine.MAX_PRECISION_BONUS = 0.25 -- Maximum +25% window expansion from ChefStats Precision

-- ── Timing Windows & Stat Scaling ───────────────────────────────────────────
-- statPrecision can be passed as raw ChefStats points (0 to 500) or as a fractional bonus (0.0 to 0.25).
function RhythmEngine.getPrecisionBonus(statPrecision: number?): number
	if not statPrecision or statPrecision <= 0 then
		return 0
	end
	if statPrecision > 1.0 then
		-- Raw stat points (0 to 500 scale)
		local ratio = math.clamp(statPrecision / 500, 0, 1)
		return ratio * RhythmEngine.MAX_PRECISION_BONUS
	else
		-- Direct fractional bonus
		return math.clamp(statPrecision, 0, RhythmEngine.MAX_PRECISION_BONUS)
	end
end

function RhythmEngine.getTimingWindows(statPrecision: number?): TimingWindows
	local bonus = RhythmEngine.getPrecisionBonus(statPrecision)
	local mult = 1.0 + bonus
	return {
		perfect = RhythmEngine.BASE_WINDOWS.PERFECT * mult,
		great = RhythmEngine.BASE_WINDOWS.GREAT * mult,
		good = RhythmEngine.BASE_WINDOWS.GOOD * mult,
		multiplier = mult,
	}
end

-- ── Hit Evaluation ───────────────────────────────────────────────────────────
-- Evaluates a hit attempt against a note's target timestamp.
-- Returns: (judgment, offsetDelta, scorePoints)
function RhythmEngine.evaluateHit(
	targetTime: number,
	hitTime: number,
	statPrecision: number?
): (Judgment, number, number)
	if type(targetTime) ~= "number" or type(hitTime) ~= "number" then
		return RhythmEngine.Judgments.MISS, 0, 0
	end

	local offset = hitTime - targetTime
	local absOffset = math.abs(offset)
	local windows = RhythmEngine.getTimingWindows(statPrecision)

	if absOffset <= windows.perfect then
		return RhythmEngine.Judgments.PERFECT, offset, RhythmEngine.BASE_SCORES.PERFECT
	elseif absOffset <= windows.great then
		return RhythmEngine.Judgments.GREAT, offset, RhythmEngine.BASE_SCORES.GREAT
	elseif absOffset <= windows.good then
		return RhythmEngine.Judgments.GOOD, offset, RhythmEngine.BASE_SCORES.GOOD
	else
		return RhythmEngine.Judgments.MISS, offset, RhythmEngine.BASE_SCORES.MISS
	end
end

-- Evaluates a hit with combo multiplier applied.
function RhythmEngine.evaluateHitWithCombo(
	targetTime: number,
	hitTime: number,
	statPrecision: number?,
	currentCombo: number?
): HitDetails
	local judgment, offset, baseScore = RhythmEngine.evaluateHit(targetTime, hitTime, statPrecision)
	local isHit = judgment ~= RhythmEngine.Judgments.MISS
	local nextCombo = if isHit then ((currentCombo or 0) + 1) else 0
	local mult = if isHit then RhythmEngine.getComboMultiplier(nextCombo) else 1.0
	local score = math.floor(baseScore * mult)

	return {
		judgment = judgment,
		offset = offset,
		baseScore = baseScore,
		multiplier = mult,
		score = score,
		isHit = isHit,
	}
end

-- ── Combo Multiplier ─────────────────────────────────────────────────────────
-- Multiplier tiers: 1.0x (0-4), 1.2x (5-9), 1.5x (10-14), 2.0x (15-19), 3.0x (20+)
function RhythmEngine.getComboMultiplier(combo: number): number
	if type(combo) ~= "number" or combo < 5 then
		return 1.0
	elseif combo < 10 then
		return 1.2
	elseif combo < 15 then
		return 1.5
	elseif combo < 20 then
		return 2.0
	else
		return 3.0
	end
end

-- ── Grade & Quality Calculations ─────────────────────────────────────────────
-- Letter grades: S (>= 95%), A (>= 85%), B (>= 70%), C (>= 50%), F (< 50%)
function RhythmEngine.getGrade(accuracy: number): string
	if accuracy >= 95 then
		return "S"
	elseif accuracy >= 85 then
		return "A"
	elseif accuracy >= 70 then
		return "B"
	elseif accuracy >= 50 then
		return "C"
	else
		return "F"
	end
end

-- Dish quality mapping: perfect, great, ok
function RhythmEngine.getDishQuality(accuracy: number, perfectRatio: number?): string
	if (perfectRatio and perfectRatio >= 0.8) or accuracy >= 95 then
		return "perfect"
	elseif accuracy >= 70 then
		return "great"
	else
		return "ok"
	end
end

-- ── Streak Management & Full Score Calculation ──────────────────────────────
-- Normalizes a hit input item to standard judgment string.
local function normalizeJudgment(item: any): Judgment
	if type(item) == "string" then
		local upper = string.upper(item)
		if upper == "PERFECT" or upper == "GREAT" or upper == "GOOD" or upper == "MISS" then
			return upper :: Judgment
		elseif upper == "OK" then
			return "GOOD" :: Judgment
		end
	elseif type(item) == "table" then
		local tag = item.judgment or item.tag or item.quality
		if type(tag) == "string" then
			return normalizeJudgment(tag)
		end
	end
	return "MISS" :: Judgment
end

-- Calculates cumulative score, accuracy, max combo, grade, and quality from an array of hits.
function RhythmEngine.calculateScore(hits: { any }): ScoreResult
	local totalHits = if type(hits) == "table" then #hits else 0
	local perfectCount = 0
	local greatCount = 0
	local goodCount = 0
	local missCount = 0

	local totalScore = 0
	local maxPossibleScore = 0
	local currentCombo = 0
	local maxCombo = 0

	if totalHits > 0 then
		for _, rawHit in ipairs(hits) do
			local judgment = normalizeJudgment(rawHit)
			local baseScore = RhythmEngine.BASE_SCORES[judgment] or 0

			if judgment == "PERFECT" then
				perfectCount += 1
				currentCombo += 1
			elseif judgment == "GREAT" then
				greatCount += 1
				currentCombo += 1
			elseif judgment == "GOOD" then
				goodCount += 1
				currentCombo += 1
			else
				missCount += 1
				currentCombo = 0
			end

			if currentCombo > maxCombo then
				maxCombo = currentCombo
			end

			local mult = if currentCombo > 0 then RhythmEngine.getComboMultiplier(currentCombo) else 1.0
			totalScore += math.floor(baseScore * mult)
			maxPossibleScore += RhythmEngine.BASE_SCORES.PERFECT
		end
	end

	-- Accuracy is based on standard weighted note accuracy: Perfect 100%, Great 60%, Good 30%, Miss 0%
	local accuracy = 0
	if totalHits > 0 then
		local weightedPoints = (perfectCount * 1.0) + (greatCount * 0.6) + (goodCount * 0.3)
		accuracy = math.round((weightedPoints / totalHits) * 10000) / 100
	end

	local grade = RhythmEngine.getGrade(accuracy)
	local perfectRatio = if totalHits > 0 then (perfectCount / totalHits) else 0
	local quality = RhythmEngine.getDishQuality(accuracy, perfectRatio)

	local counts: ScoreCounts = {
		PERFECT = perfectCount,
		GREAT = greatCount,
		GOOD = goodCount,
		MISS = missCount,
		total = totalHits,
		perfect = perfectCount,
		great = greatCount,
		good = goodCount,
		miss = missCount,
	}

	return {
		totalScore = totalScore,
		maxPossibleScore = maxPossibleScore,
		accuracy = accuracy,
		maxCombo = maxCombo,
		finalCombo = currentCombo,
		grade = grade,
		quality = quality,
		counts = counts,
	}
end

return RhythmEngine
