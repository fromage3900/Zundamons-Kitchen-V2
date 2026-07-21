--!strict
-- [[ModuleScript] HarvestConfig (ref: NEW)]]
-- Central tuning configuration for all harvesting interactions.
-- All distances, timings, cooldowns, and visual settings live here.

local HarvestConfig = {
	-- Interaction distance (studs)
	MAX_INTERACTION_DISTANCE = 16,
	MIN_INTERACTION_DISTANCE = 2,

	-- Harvest timing (seconds)
	HARVEST_DURATION = 2.5,          -- Base time to hold interaction
	HARVEST_COOLDOWN = 1.0,          -- Per-node cooldown after harvest

	-- Progress bar
	PROGRESS_BAR_WIDTH = 200,
	PROGRESS_BAR_HEIGHT = 24,
	PROGRESS_BAR_BG_COLOR = Color3.fromRGB(40, 30, 20),
	PROGRESS_BAR_FILL_COLOR = Color3.fromRGB(100, 200, 80),
	PROGRESS_BAR_BORDER_COLOR = Color3.fromRGB(200, 180, 150),

	-- Cancel-on-move threshold (studs)
	MOVE_CANCEL_THRESHOLD = 1.5,

	-- Animation
	HARVEST_ANIMATION_ID = "rbxassetid://2510798496",
	HARVEST_ANIMATION_PRIORITY = Enum.AnimationPriority.Action,

	-- Sound
	HARVEST_SOUND_ID = "rbxassetid://9114369623",
	HARVEST_SOUND_VOLUME = 0.6,
	HARVEST_SOUND_PITCH_MIN = 0.9,
	HARVEST_SOUND_PITCH_MAX = 1.1,

	-- Particles
	HARVEST_PARTICLE_COLOR = Color3.fromRGB(180, 230, 120),
	HARVEST_PARTICLE_COUNT = 8,
	HARVEST_PARTICLE_SPEED = 8,
	HARVEST_PARTICLE_LIFETIME = 1.2,

	-- Server validation
	SERVER_VALIDATION_ENABLED = true,
	MAX_HARVEST_RATE = 5,            -- Max harvests per second per player
	RATE_LIMIT_WINDOW = 1.0,         -- Rate limit window in seconds

	-- Exploit prevention
	ENABLE_DISTANCE_CHECK = true,
	ENABLE_OWNERSHIP_CHECK = true,
	ENABLE_RATE_LIMIT = true,

	-- Item reward spawning
	LOOT_SPAWN_HEIGHT_OFFSET = 2.5,
	LOOT_SPAWN_RADIUS = 1.5,
	LOOT_FADE_IN_DURATION = 0.3,
}

return HarvestConfig