--!strict
-- [[ModuleScript] TournamentConfig]]
-- Weekly PvP cooking tournament system for Zundamon's Kitchen V2.
--
-- Tournaments run on a weekly cycle. Players submit their best dish + party
-- composition; the server calculates a composite score and ranks all participants.
-- Top 10 earners receive exclusive cosmetics. All participants earn tournament
-- currency redeemable in the tournament shop.
--
-- Score Formula:
--   base_score     = dish_quality_score * recipe_difficulty_multiplier
--   synergy_bonus  = base_score * type_synergy_magnitude
--   chef_bonus     = base_score * (chef_stat_average / 500) * 0.20
--   final_score    = floor(base_score + synergy_bonus + chef_bonus)
--
-- dish_quality_score:
--   "poor"    = 100
--   "normal"  = 200
--   "good"    = 350
--   "great"   = 500
--   "perfect" = 750 (+ perfect_bonus below)
--
-- recipe_difficulty_multiplier (from CraftConfig.difficulty):
--   "easy"   = 1.0
--   "medium" = 1.3
--   "hard"   = 1.6
--   "expert" = 2.0

local TournamentConfig = {}

-- ── Score Constants ───────────────────────────────────────────────────────────

TournamentConfig.scoring = {
	-- Base points per quality tier
	quality_scores = {
		poor = 100,
		normal = 200,
		good = 350,
		great = 500,
		perfect = 750,
	},

	-- Extra flat bonus for a "perfect" cook (stacks with quality_score)
	perfect_bonus = 150,

	-- Multiplier applied after quality score, based on recipe difficulty
	difficulty_multipliers = {
		easy = 1.0,
		medium = 1.3,
		hard = 1.6,
		expert = 2.0,
	},

	-- Chef stat contribution: each avg chef stat point above 0 adds 0.04%
	-- Formula: (chef_stat_average / 500) * 0.20  →  max +20% at stat cap
	chef_stat_coefficient = 0.20,
	chef_stat_cap = 500,

	-- Party synergy magnitude is taken directly from DamonTypeConfig.getPartySynergies()
	-- and summed; each active synergy adds its magnitude as a fraction of base_score.
}

-- ── Weekly Cycle ──────────────────────────────────────────────────────────────

-- Tournaments reset every Monday at 00:00 UTC.
-- Submission window: Monday 00:00 → Saturday 23:59 UTC.
-- Results finalized: Sunday 00:00 UTC, distributed before next Monday.
TournamentConfig.cycle = {
	reset_day_utc = 2, -- 2 = Monday (os.date %w: 0=Sun, 1=Mon, ...)
	submission_close_day = 7, -- 7 = Sunday
	results_day_utc = 1, -- 1 = Sunday (distribute before reset)
	submission_max_per_player = 3, -- players may re-submit up to 3 times; best score counts
}

-- ── Ranking Tiers & Rewards ───────────────────────────────────────────────────

TournamentConfig.tiers = {
	{
		name = "Zunda Grand Master",
		rank_range = { 1, 1 },
		emoji = "🥇",
		gold_reward = 2000,
		trophy_token = 50,
		cosmetic = "tournament_crown_gold",
		title_badge = "Grand Master Chef",
	},
	{
		name = "Platinum Plate",
		rank_range = { 2, 3 },
		emoji = "🥈",
		gold_reward = 1200,
		trophy_token = 35,
		cosmetic = "tournament_crown_platinum",
		title_badge = "Platinum Chef",
	},
	{
		name = "Gold Ladle",
		rank_range = { 4, 10 },
		emoji = "🥉",
		gold_reward = 800,
		trophy_token = 20,
		cosmetic = "tournament_ladle_gold",
		title_badge = "Gold Ladle Chef",
	},
	{
		name = "Silver Fork",
		rank_range = { 11, 50 },
		emoji = "🍴",
		gold_reward = 400,
		trophy_token = 10,
		cosmetic = nil, -- no cosmetic at this tier
		title_badge = nil,
	},
	{
		name = "Participant",
		rank_range = { 51, math.huge },
		emoji = "🌱",
		gold_reward = 100,
		trophy_token = 2,
		cosmetic = nil,
		title_badge = nil,
	},
}

-- ── Tournament Shop ───────────────────────────────────────────────────────────
-- "trophy_token" is the tournament currency earned from participation + ranking.

TournamentConfig.shop = {
	{ id = "tournament_apron", cost = 100, type = "cosmetic", name = "Championship Apron", icon = "👔" },
	{
		id = "tournament_hat",
		cost = 80,
		type = "cosmetic",
		name = "Grand Chef Toque",
		icon = "👨‍🍳",
	},
	{ id = "tournament_trail", cost = 150, type = "effect", name = "Gold Sparkle Trail", icon = "✨" },
	{ id = "tournament_evo_pea", cost = 60, type = "evo_item", name = "Tournament Pea Shard", icon = "🫛" },
	{
		id = "tournament_whim_x5",
		cost = 40,
		type = "currency",
		name = "Whim Ticket ×5",
		icon = "🎟️",
	},
	{ id = "tournament_gems_500", cost = 120, type = "currency", name = "Zunda Gems ×500", icon = "💎" },
}

-- ── Score Calculation (server-only, reference implementation) ─────────────────
-- This function is defined here for documentation and testing; the live
-- implementation lives in src/server/Services/TournamentService.lua.
-- Types are annotated for reference — Luau strict mode applies there.

--[[
function TournamentConfig.calculateScore(
    qualityTier: string,   -- "poor" | "normal" | "good" | "great" | "perfect"
    recipeDifficulty: string, -- "easy" | "medium" | "hard" | "expert"
    chefStatAverage: number,  -- average of speed, precision, charisma, stamina (0–500)
    activeSynergies: { { magnitude: number } }  -- from DamonTypeConfig.getPartySynergies()
): number

    local s = TournamentConfig.scoring
    local base = (s.quality_scores[qualityTier] or 200)
        + (qualityTier == "perfect" and s.perfect_bonus or 0)

    local diffMult = s.difficulty_multipliers[recipeDifficulty] or 1.0
    base = base * diffMult

    local chefBonus = base * (math.min(chefStatAverage, s.chef_stat_cap) / s.chef_stat_cap) * s.chef_stat_coefficient

    local synergyBonus = 0
    for _, syn in ipairs(activeSynergies) do
        synergyBonus += base * syn.magnitude
    end

    return math.floor(base + chefBonus + synergyBonus)
end
]]

-- ── Helper Functions ──────────────────────────────────────────────────────────

-- Returns the reward tier table for a given rank (1-indexed).
function TournamentConfig.getTierForRank(rank: number): { [string]: any }?
	for _, tier in ipairs(TournamentConfig.tiers) do
		if rank >= tier.rank_range[1] and rank <= tier.rank_range[2] then
			return tier
		end
	end
	return nil
end

return TournamentConfig
