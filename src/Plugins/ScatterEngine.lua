--!strict
-- ScatterEngine: Surface sampling and decoration placement
-- Infinity Nikki aesthetic: style-matched placement with sparkle density
local ScatterEngine = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

function ScatterEngine.scanZone(zoneName)
	local ZoneProfiles = require(script:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("ZoneProfiles"))
	local zone = ZoneProfiles.getZone(zoneName)
	if not zone or not zone.bounds then
		return nil
	end

	local bounds = zone.bounds
	local region = Region3.new(bounds.min, bounds.max)
	local parts = Workspace:FindPartsInRegion3(region, nil, 1000)

	local surfaceSamples = {}
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") and not part.Anchored == false then
			local surfaceCFrame = part.CFrame + Vector3.new(0, part.Size.Y / 2, 0)
			table.insert(surfaceSamples, {
				position = surfaceCFrame.Position,
				normal = Vector3.new(0, 1, 0),
				part = part,
			})
		end
	end

	return {
		bounds = bounds,
		samples = surfaceSamples,
		partCount = #parts,
	}
end

function ScatterEngine.sampleSurface(zoneBounds, density, exclusionTags)
	local samples = {}
	local bounds = zoneBounds.bounds or zoneBounds
	local min, max = bounds.min, bounds.max

	local spanX = max.X - min.X
	local spanZ = max.Z - min.Z
	local area = spanX * spanZ
	local targetCount = math.max(1, math.floor(area * density / 100))

	local rng = Random.new()
	local attempts = 0
	local maxAttempts = targetCount * 10

	while #samples < targetCount and attempts < maxAttempts do
		attempts += 1
		local x = rng:NextNumber(min.X, max.X)
		local z = rng:NextNumber(min.Z, max.Z)
		local y = min.Y

		local ray = Ray.new(Vector3.new(x, max.Y + 50, z), Vector3.new(0, -(max.Y - min.Y + 100), 0))
		local hit, position, normal = Workspace:FindPartOnRayWithIgnoreList(ray, {}, false, true)

		if hit and position and normal then
			if normal.Y > 0.5 then
				local skip = false
				for _, tag in ipairs(exclusionTags) do
					if hit:FindFirstChild(tag) or (hit:GetAttribute("Tag") == tag) then
						skip = true
						break
					end
				end
				if not skip then
					table.insert(samples, {
						position = position,
						normal = normal,
						part = hit,
					})
				end
			end
		end
	end

	return samples
end

function ScatterEngine.pickDecoration(decorationList, weights)
	if #decorationList == 0 then
		return nil
	end

	local totalWeight = 0
	local weighted = {}
	for _, deco in ipairs(decorationList) do
		local weight = (weights and weights[deco]) or 1
		totalWeight += weight
		table.insert(weighted, { deco = deco, weight = weight })
	end

	if totalWeight == 0 then
		return decorationList[math.random(1, #decorationList)]
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(weighted) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.deco
		end
	end

	return decorationList[#decorationList]
end

function ScatterEngine.calculateStyleScore(zoneName, decorationName)
	local ZoneProfiles = require(script:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("ZoneProfiles"))
	local zone = ZoneProfiles.getZone(zoneName)
	if not zone then
		return 0
	end

	local DecorationCatalog =
		require(script:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("DecorationCatalog"))
	local blueprint = DecorationCatalog.getBlueprint(decorationName)
	if not blueprint or not blueprint.tags then
		return 0
	end

	local matchCount = 0
	for _, tag in ipairs(blueprint.tags) do
		if table.find(zone.styleAffinity or {}, tag) then
			matchCount += 1
		end
	end
	return matchCount / #blueprint.tags
end

return ScatterEngine
