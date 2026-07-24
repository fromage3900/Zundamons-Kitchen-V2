--!strict
-- ProceduralGeometry: Builds decoration blueprints into Roblox parts
-- Infinity Nikki aesthetic: pastel colors, sparkles, and style-matched placement
local ProceduralGeometry = {}

local function createPart(partDef, position, normal, styleVariant)
	local part = Instance.new(partDef.type)
	part.Size = partDef.size
	part.CFrame = CFrame.lookAt(position + partDef.position, position + partDef.position + normal)
	part.Color = partDef.color
	part.Transparency = partDef.transparency
	part.Anchored = partDef.anchored
	part.CanCollide = partDef.canCollide
	part.Material = partDef.material
	return part
end

local function createLight(lightDef, parent)
	local light
	if lightDef.type == "PointLight" then
		light = Instance.new("PointLight")
	elseif lightDef.type == "SpotLight" then
		light = Instance.new("SpotLight")
	elseif lightDef.type == "SurfaceLight" then
		light = Instance.new("SurfaceLight")
	end
	if light then
		light.Color = lightDef.color
		light.Range = lightDef.range
		light.Brightness = lightDef.brightness
		light.Parent = parent
	end
	return light
end

function ProceduralGeometry.build(decoType, position, normal, styleVariant)
	local DecorationCatalog = require(script:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("DecorationCatalog"))
	local blueprint = DecorationCatalog.getBlueprint(decoType)
	if not blueprint then
		warn("[ProceduralGeometry] Unknown decoration type: " .. tostring(decoType))
		return nil
	end

	local scale = 1
	if blueprint.scaleRange then
		scale = math.random() * (blueprint.scaleRange.max - blueprint.scaleRange.min) + blueprint.scaleRange.min
	end

	local model = Instance.new("Model")
	model.Name = decoType .. "_" .. math.random(1000, 9999)
	model:SetAttribute("DecorationType", decoType)
	model:SetAttribute("StyleVariant", styleVariant or "default")

	local baseCFrame = CFrame.lookAt(position, position + normal)
	local upVector = normal

	for _, partDef in ipairs(blueprint.parts or {}) do
		local part = createPart(partDef, position, normal, styleVariant)
		part.Size = partDef.size * scale
		part.CFrame = baseCFrame * CFrame.new(partDef.position * scale)
		if blueprint.rotationJitter then
			local jitter = Vector3.new(
				(math.random() - 0.5) * 20,
				(math.random() - 0.5) * 360,
				(math.random() - 0.5) * 20
			)
			part.CFrame = part.CFrame * CFrame.Angles(math.rad(jitter.X), math.rad(jitter.Y), math.rad(jitter.Z))
		end
		part.Parent = model
	end

	for _, lightDef in ipairs(blueprint.lights or {}) do
		createLight(lightDef, model)
	end

	if blueprint.customBuild then
		local customFn = ProceduralGeometry.customBuilds[blueprint.customBuild]
		if customFn then
			customFn(model, position, normal, scale)
		end
	end

	return {model}
end

ProceduralGeometry.customBuilds = {
	meditation_circle = function(model, position, normal, scale)
		local numStones = 8
		for i = 1, numStones do
			local angle = (i / numStones) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 1.5 * scale, 0, math.sin(angle) * 1.5 * scale)
			local stone = Instance.new("Part")
			stone.Size = Vector3.new(0.5 * scale, 0.3 * scale, 2 * scale)
			stone.CFrame = CFrame.lookAt(position + offset, position + offset + normal) * CFrame.Angles(0, angle, 0)
			stone.Color = Color3.fromRGB(145, 215, 195)
			stone.Anchored = true
			stone.CanCollide = false
			stone.Material = Enum.Material.SmoothPlastic
			stone.Parent = model
		end
	end,
}

return ProceduralGeometry
