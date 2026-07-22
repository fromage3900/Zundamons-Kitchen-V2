--!strict
-- [[ModuleScript] ChefLevelConfig]]
-- XP required per level and tier definitions

local ChefLevelConfig = {}

function ChefLevelConfig.xpForLevel(level: number): number
	-- Gentle exponential: easier early levels for cozy feel
	-- Level 1-5: ~100 XP each
	-- Level 5-10: ~150 XP each
	-- Level 10+: steeper curve
	if level <= 5 then
		return 80
	elseif level <= 10 then
		return math.floor(80 + (level - 5) * 20)
	else
		return math.floor(80 + 100 + (level - 10) * 40)
	end
end

function ChefLevelConfig.tierForLevel(level: number)
	if level < 5 then
		return { name = "Sprout", color = Color3.fromRGB(150, 200, 150), badge = "🌱" }
	elseif level < 15 then
		return { name = "Blossom", color = Color3.fromRGB(180, 130, 255), badge = "🌸" }
	elseif level < 30 then
		return { name = "Zunda Chef", color = Color3.fromRGB(255, 200, 80), badge = "🍡" }
	else
		return { name = "Grand Zunda", color = Color3.fromRGB(255, 150, 200), badge = "✨" }
	end
end

ChefLevelConfig.xpRewards = {
	serveGuest = 15,
	craftSuccess = 10,
	craftPerfect = 25,
	dailyLogin = 20,
	gather = 5,
}

return ChefLevelConfig
