--!strict
-- ZundaMaterialUtils: apply Zunda palette materials to parts and generate
-- Rojo/Git-friendly Lua config snippets for the shared hub.

local ZundaPalette = require(script.Parent.ZundaPalette)

local ZundaMaterialUtils = {}

local function setAttributeSafe(part: BasePart, key: string, value: any)
	if part:IsA("BasePart") then
		pcall(function()
			part:SetAttribute(key, value)
		end)
	end
end

-- Apply one palette spec to a part. When createVariant is true, the part gets
-- the MaterialVariant (created in MaterialService if missing); otherwise the
-- part is painted with the base material + color directly.
function ZundaMaterialUtils.applyToPart(part: BasePart, spec: any, createVariant: boolean, applyAttributes: boolean)
	if createVariant then
		local variant = ZundaPalette.findOrCreateVariant(spec.name, spec)
		if variant then
			part.Material = variant.BaseMaterial
			part.MaterialVariant = variant
		end
	else
		part.Material = ZundaPalette.resolveBaseMaterial(spec.baseMaterial)
		part.Color = spec.color
		part.MaterialVariant = nil
	end
	if applyAttributes then
		for key, value in pairs(spec.attributes or {}) do
			setAttributeSafe(part, key, value)
		end
	end
end

function ZundaMaterialUtils.applyToSelection(
	instances: { Instance },
	spec: any,
	createVariant: boolean,
	applyAttributes: boolean
): number
	local applied = 0
	for _, instance in ipairs(instances) do
		if instance:IsA("BasePart") then
			ZundaMaterialUtils.applyToPart(instance, spec, createVariant, applyAttributes)
			applied += 1
		elseif instance:IsA("Model") then
			for _, descendant in ipairs(instance:GetDescendants()) do
				if descendant:IsA("BasePart") then
					ZundaMaterialUtils.applyToPart(descendant, spec, createVariant, applyAttributes)
					applied += 1
				end
			end
		end
	end
	return applied
end

function ZundaMaterialUtils.flattenParts(instances: { Instance }): { BasePart }
	local parts = {}
	local seen = {}
	for _, instance in ipairs(instances) do
		local list = { instance }
		if instance:IsA("Model") then
			list = instance:GetDescendants()
		end
		for _, descendant in ipairs(list) do
			if descendant:IsA("BasePart") and not seen[descendant] then
				seen[descendant] = true
				table.insert(parts, descendant)
			end
		end
	end
	return parts
end

-- Generate a Lua table snippet for the shared palette module so authors can
-- paste new variants straight into src/Plugins/ZundaPalette.lua (Rojo-owned)
-- or src/shared/ConfigurationFiles material configs.
function ZundaMaterialUtils.generateConfigSnippet(spec: any): string
	local lines = {
		string.format("%s = {", spec.name),
		string.format("\tname = %q,", spec.name),
		string.format("\tdisplayName = %q,", spec.displayName or spec.name),
		string.format(
			"\tcolor = Color3.fromRGB(%d, %d, %d),",
			math.floor(spec.color.R * 255 + 0.5),
			math.floor(spec.color.G * 255 + 0.5),
			math.floor(spec.color.B * 255 + 0.5)
		),
		string.format("\tbaseMaterial = %q,", spec.baseMaterial),
		string.format("\troughness = %s,", tostring(spec.roughness)),
		string.format("\tmetallic = %s,", tostring(spec.metallic)),
		string.format("\tnotes = %q,", spec.notes or ""),
		"},",
	}
	return table.concat(lines, "\n")
end

function ZundaMaterialUtils.describeVariant(variant: MaterialVariant?): string?
	if not variant then
		return nil
	end
	return string.format(
		"%s (BaseMaterial=%s, Color=%s, Roughness=%s, Metallic=%s)",
		variant.Name,
		tostring(variant.BaseMaterial),
		tostring(variant.Color),
		tostring(variant.Roughness),
		tostring(variant.Metallic)
	)
end

return ZundaMaterialUtils
