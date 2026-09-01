--!strict
-- [[ModuleScript] RhythmScoreEvaluator]]
-- Letter grading (S/A/B/C/F), dish quality tier mapping, and reward scaling
-- (Gold bonuses, Style Points, and Chef Stat XP) for the rhythm cooking engine.

local RhythmEngine = require(script.Parent.RhythmEngine)

export type Grade = "S" | "A" | "B" | "C" | "F"
export type Quality = "perfect" | "great" | "ok"

export type StatXP = {
	precision: number,
	speed: number,
}

export type ScoreCounts = {
	perfect: number,
	great: number,
	good: number,
	miss: number,
	total: number,
}

export type EvaluationInput = {
	accuracy: number?,
	totalScore: number?,
	maxCombo: number?,
	totalNotes: number?,
	perfectHits: number?,
	greatHits: number?,
	goodHits: number?,
	okHits: number?,
	misses: number?,
	hits: { any }?,
	hitRecords: { any }?,
	baseGold: number?,
}

export type EvaluationResult = {
	grade: Grade,
	quality: Quality,
	accuracy: number,
	totalScore: number,
	maxCombo: number,
	goldBonusMultiplier: number,
	goldBonusPercent: number,
	bonusGold: number,
	stylePoints: number,
	statXP: StatXP,
	counts: ScoreCounts,
}

local RhythmScoreEvaluator = {}

-- ── Constants & Configuration Tables ─────────────────────────────────────────

RhythmScoreEvaluator.GRADES = {
	S = "S" :: Grade,
	A = "A" :: Grade,
	B = "B" :: Grade,
	C = "C" :: Grade,
	F = "F" :: Grade,
}

-- Accuracy thresholds: S (>=95%), A (>=85%), B (>=70%), C (>=50%), F (<50%)
RhythmScoreEvaluator.GRADE_THRESHOLDS = {
	S = 95.0,
	A = 85.0,
	B = 70.0,
	C = 50.0,
	F = 0.0,
}

-- Quality tier mapping: S -> "perfect", A/B -> "great", C/F -> "ok"
RhythmScoreEvaluator.GRADE_TO_QUALITY = {
	S = "perfect" :: Quality,
	A = "great" :: Quality,
	B = "great" :: Quality,
	C = "ok" :: Quality,
	F = "ok" :: Quality,
}

-- Gold bonus multipliers: S (+50%), A (+25%), B (+10%), C (+0%), F (+0%)
RhythmScoreEvaluator.GOLD_BONUS_MULTIPLIER = {
	S = 1.50,
	A = 1.25,
	B = 1.10,
	C = 1.00,
	F = 1.00,
}

RhythmScoreEvaluator.GOLD_BONUS_PERCENT = {
	S = 50,
	A = 25,
	B = 10,
	C = 0,
	F = 0,
}

-- Style Points: S (+250), A (+150), B (+75), C (+25), F (+0)
RhythmScoreEvaluator.STYLE_POINTS = {
	S = 250,
	A = 150,
	B = 75,
	C = 25,
	F = 0,
}

-- Base Chef Stat XP rewards per grade
local BASE_PRECISION_XP: { [Grade]: number } = {
	S = 12,
	A = 8,
	B = 5,
	C = 2,
	F = 1,
}

local BASE_SPEED_XP: { [Grade]: number } = {
	S = 8,
	A = 5,
	B = 3,
	C = 1,
	F = 0,
}

-- ── Pure Evaluator Functions ─────────────────────────────────────────────────

-- Resolves letter grade from accuracy percentage [0 .. 100].
function RhythmScoreEvaluator.getGrade(accuracy: number): Grade
	if type(accuracy) ~= "number" or accuracy < 0 then
		return RhythmScoreEvaluator.GRADES.F
	end

	if accuracy >= RhythmScoreEvaluator.GRADE_THRESHOLDS.S then
		return RhythmScoreEvaluator.GRADES.S
	elseif accuracy >= RhythmScoreEvaluator.GRADE_THRESHOLDS.A then
		return RhythmScoreEvaluator.GRADES.A
	elseif accuracy >= RhythmScoreEvaluator.GRADE_THRESHOLDS.B then
		return RhythmScoreEvaluator.GRADES.B
	elseif accuracy >= RhythmScoreEvaluator.GRADE_THRESHOLDS.C then
		return RhythmScoreEvaluator.GRADES.C
	else
		return RhythmScoreEvaluator.GRADES.F
	end
end

-- Maps a grade (or raw accuracy) to dish quality tier: "perfect" | "great" | "ok".
function RhythmScoreEvaluator.getQuality(gradeOrAccuracy: any): Quality
	if type(gradeOrAccuracy) == "number" then
		local grade = RhythmScoreEvaluator.getGrade(gradeOrAccuracy)
		return RhythmScoreEvaluator.GRADE_TO_QUALITY[grade] or "ok"
	elseif type(gradeOrAccuracy) == "string" then
		local upper = string.upper(gradeOrAccuracy) :: Grade
		if RhythmScoreEvaluator.GRADE_TO_QUALITY[upper] then
			return RhythmScoreEvaluator.GRADE_TO_QUALITY[upper]
		end
		-- Check direct quality string
		local lower = string.lower(gradeOrAccuracy)
		if lower == "perfect" or lower == "great" or lower == "ok" then
			return lower :: Quality
		end
	end
	return "ok"
end

-- Returns the gold multiplier for a given grade (e.g. 1.50 for S).
function RhythmScoreEvaluator.getGoldMultiplier(grade: string): number
	local upper = string.upper(grade) :: Grade
	return RhythmScoreEvaluator.GOLD_BONUS_MULTIPLIER[upper] or 1.00
end

-- Returns the gold bonus percentage for a given grade (e.g. 50 for S).
function RhythmScoreEvaluator.getGoldBonusPercent(grade: string): number
	local upper = string.upper(grade) :: Grade
	return RhythmScoreEvaluator.GOLD_BONUS_PERCENT[upper] or 0
end

-- Returns Style Points awarded for a given grade (S: 250, A: 150, B: 75, C: 25, F: 0).
function RhythmScoreEvaluator.getStylePoints(grade: string): number
	local upper = string.upper(grade) :: Grade
	return RhythmScoreEvaluator.STYLE_POINTS[upper] or 0
end

-- Calculates Chef Stat XP (Precision & Speed) scaling with note accuracy and combo ratio.
function RhythmScoreEvaluator.calculateStatXP(
	accuracy: number,
	maxCombo: number,
	totalNotes: number?,
	gradeHint: string?
): StatXP
	local safeAcc = math.clamp(accuracy or 0, 0, 100)
	local grade = if type(gradeHint) == "string" and RhythmScoreEvaluator.GRADES[string.upper(gradeHint)]
		then string.upper(gradeHint) :: Grade
		else RhythmScoreEvaluator.getGrade(safeAcc)

	local safeCombo = math.max(0, maxCombo or 0)
	local safeTotal = math.max(1, totalNotes or 10)
	local comboRatio = math.clamp(safeCombo / safeTotal, 0, 1)

	-- Precision XP scales with accuracy percentage
	local basePrec = BASE_PRECISION_XP[grade] or 1
	local accBonus = math.floor((safeAcc / 100) * 6)
	local finalPrecisionXP = basePrec + accBonus

	-- Speed XP scales with max combo performance and combo ratio
	local baseSpeed = BASE_SPEED_XP[grade] or 0
	local comboBonus = math.floor(comboRatio * 8)
	local finalSpeedXP = math.max(1, baseSpeed + comboBonus)

	return {
		precision = finalPrecisionXP,
		speed = finalSpeedXP,
	}
end

-- Full comprehensive evaluation given session metrics or raw hit records.
function RhythmScoreEvaluator.evaluate(input: EvaluationInput): EvaluationResult
	local perfectCount = input.perfectHits or 0
	local greatCount = input.greatHits or 0
	local goodCount = input.goodHits or input.okHits or 0
	local missCount = input.misses or 0

	local hitList = input.hitRecords or input.hits

	local computedAccuracy: number
	local computedScore: number = input.totalScore or 0
	local computedMaxCombo: number = input.maxCombo or 0

	-- If raw hit records provided, evaluate using RhythmEngine
	if hitList and #hitList > 0 then
		local engineResult = RhythmEngine.calculateScore(hitList)
		perfectCount = engineResult.counts.perfect
		greatCount = engineResult.counts.great
		goodCount = engineResult.counts.good
		missCount = engineResult.counts.miss
		computedAccuracy = engineResult.accuracy
		computedScore = math.max(computedScore, engineResult.totalScore)
		computedMaxCombo = math.max(computedMaxCombo, engineResult.maxCombo)
	elseif type(input.accuracy) == "number" then
		computedAccuracy = math.clamp(input.accuracy, 0, 100)
	else
		-- Calculate accuracy from note counts: Perfect (1.0), Great (0.6), Good (0.3), Miss (0.0)
		local totalNotes = input.totalNotes or (perfectCount + greatCount + goodCount + missCount)
		if totalNotes > 0 then
			local weighted = (perfectCount * 1.0) + (greatCount * 0.6) + (goodCount * 0.3)
			computedAccuracy = math.round((weighted / totalNotes) * 10000) / 100
		else
			computedAccuracy = 0
		end
	end

	local totalNotes = input.totalNotes or (perfectCount + greatCount + goodCount + missCount)
	local grade = RhythmScoreEvaluator.getGrade(computedAccuracy)
	local quality = RhythmScoreEvaluator.getQuality(grade)
	local goldBonusMultiplier = RhythmScoreEvaluator.getGoldMultiplier(grade)
	local goldBonusPercent = RhythmScoreEvaluator.getGoldBonusPercent(grade)

	local baseGold = input.baseGold or 0
	local bonusGold = math.floor(baseGold * (goldBonusMultiplier - 1.0))
	local stylePoints = RhythmScoreEvaluator.getStylePoints(grade)
	local statXP = RhythmScoreEvaluator.calculateStatXP(computedAccuracy, computedMaxCombo, totalNotes, grade)

	local counts: ScoreCounts = {
		perfect = perfectCount,
		great = greatCount,
		good = goodCount,
		miss = missCount,
		total = totalNotes,
	}

	return {
		grade = grade,
		quality = quality,
		accuracy = computedAccuracy,
		totalScore = computedScore,
		maxCombo = computedMaxCombo,
		goldBonusMultiplier = goldBonusMultiplier,
		goldBonusPercent = goldBonusPercent,
		bonusGold = bonusGold,
		stylePoints = stylePoints,
		statXP = statXP,
		counts = counts,
	}
end

return RhythmScoreEvaluator
