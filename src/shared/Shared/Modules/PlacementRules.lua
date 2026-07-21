--!strict
-- Shared placement helpers for procedural landscape generation.

local PlacementRules = {}

local function round(value)
	return math.floor(value + 0.5)
end

local function clamp(value, min, max)
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

function PlacementRules.generateCandidates(zone, seed)
	local count = math.max(1, math.floor((zone.size or 12) / 4))
	local candidates = {}

	for index = 1, count do
		local t = (index / math.max(1, count)) * math.pi * 2
		local radius = math.max(2, (zone.size or 12) * 0.16 + ((seed % 5) * 0.5))
		local x = math.cos(t) * radius
		local z = math.sin(t) * radius

		table.insert(candidates, {
			id = string.format("%s_%d", zone.name or "Zone", index),
			x = round(x * 10) / 10,
			z = round(z * 10) / 10,
			score = clamp(1 - ((index - 1) / math.max(1, count)), 0.2, 1.0),
		})
	end

	return candidates
end

function PlacementRules.filterBySpacing(candidates, existing, spacing)
	local filtered = {}

	for _, candidate in ipairs(candidates) do
		local isValid = true
		for _, placement in ipairs(existing or {}) do
			local dx = (candidate.x or 0) - (placement.x or 0)
			local dz = (candidate.z or 0) - (placement.z or 0)
			local distance = math.sqrt(dx * dx + dz * dz)
			if distance < spacing then
				isValid = false
				break
			end
		end

		if isValid then
			table.insert(filtered, candidate)
		end
	end

	return filtered
end

function PlacementRules.selectAssets(profile)
	local selected = {}

	for _, entry in ipairs(profile or {}) do
		if entry.required or math.random() <= (entry.weight or 0.5) then
			table.insert(selected, entry)
		end
	end

	if #selected == 0 then
		table.insert(selected, profile[1] or { asset = "Scatter", category = "decor" })
	end

	return selected
end

return PlacementRules
