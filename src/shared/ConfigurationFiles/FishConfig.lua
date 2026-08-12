-- [[ModuleScript] FishConfig (ref: RBX5E6D4447D3244E2182C35809E5179440)]]
local M = {}

-- Each fish has: name, rarity (1-5), value (gold), xp, tag pattern, color
M.fish = {
	{ name = "Bluegill", rarity = 1, value = 8, xp = 5, color = Color3.fromRGB(140, 180, 220), weight = 30 },
	{ name = "Carp", rarity = 1, value = 12, xp = 6, color = Color3.fromRGB(200, 170, 120), weight = 25 },
	{ name = "Trout", rarity = 2, value = 20, xp = 10, color = Color3.fromRGB(220, 180, 150), weight = 18 },
	{ name = "Pike", rarity = 2, value = 25, xp = 12, color = Color3.fromRGB(120, 150, 130), weight = 12 },
	{ name = "Salmon", rarity = 3, value = 50, xp = 25, color = Color3.fromRGB(240, 140, 130), weight = 7 },
	{ name = "Koi", rarity = 3, value = 60, xp = 28, color = Color3.fromRGB(240, 100, 100), weight = 5 },
	{ name = "Catfish", rarity = 4, value = 100, xp = 50, color = Color3.fromRGB(80, 70, 60), weight = 2 },
	{ name = "Golden Koi", rarity = 5, value = 300, xp = 120, color = Color3.fromRGB(255, 220, 80), weight = 1 },
}

-- Difficulty per rarity: tug intensity, dodge rate
M.difficulty = {
	[1] = { tugMag = 0.15, dodgeChance = 0.10, duration = 6, hookWindow = 0.55 },
	[2] = { tugMag = 0.22, dodgeChance = 0.18, duration = 8, hookWindow = 0.50 },
	[3] = { tugMag = 0.32, dodgeChance = 0.28, duration = 10, hookWindow = 0.42 },
	[4] = { tugMag = 0.42, dodgeChance = 0.40, duration = 13, hookWindow = 0.35 },
	[5] = { tugMag = 0.55, dodgeChance = 0.55, duration = 18, hookWindow = 0.30 },
}

function M.rollFish()
	local total = 0
	for _, f in ipairs(M.fish) do
		total = total + f.weight
	end
	local pick = math.random() * total
	local acc = 0
	for _, f in ipairs(M.fish) do
		acc = acc + f.weight
		if pick <= acc then
			return f
		end
	end
	return M.fish[1]
end

return M
