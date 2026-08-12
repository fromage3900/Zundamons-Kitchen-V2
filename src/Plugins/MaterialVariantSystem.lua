--!strict
-- MaterialVariantSystem: Paints terrain with MaterialVariants per zone
-- Infinity Nikki aesthetic: pastel terrain that matches the zone's style identity
local MaterialVariantSystem = {}

local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

function MaterialVariantSystem.paintZone(zoneName, materialVariant, bounds)
	if not Terrain then
		warn("[MaterialVariantSystem] No Terrain found in Workspace")
		return false
	end

	local MaterialPalette = require(script:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("MaterialPalette"))
	local palette = MaterialPalette.getPalette(materialVariant)
	if not palette then
		warn("[MaterialVariantSystem] Unknown material variant: " .. tostring(materialVariant))
		return false
	end

	local region = Region3.new(bounds.min, bounds.max)
	local material = palette.baseMaterial

	Terrain:ReplaceMaterial(region, Enum.Material.SmoothPlastic, material, palette.color, 0.5)

	print("[MaterialVariantSystem] Painted zone " .. zoneName .. " with " .. materialVariant)
	return true
end

function MaterialVariantSystem.createVariant(palette)
	local MaterialService = game:GetService("MaterialService")
	local variant = Instance.new("MaterialVariant")
	variant.Name = palette.name
	variant.BaseMaterial = palette.baseMaterial
	variant.Parent = MaterialService
	return variant
end

function MaterialVariantSystem.getTerrainBounds()
	if not Terrain then
		return nil
	end
	local region = Terrain:ReadVoxels(4, Vector3.new(0, 0, 0))
	if not region then
		return nil
	end
	local min = Vector3.new(-500, -100, -500)
	local max = Vector3.new(500, 200, 500)
	return { min = min, max = max }
end

return MaterialVariantSystem
