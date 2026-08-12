--!strict
-- MaterialPalette: Registers MaterialVariants for terrain painting
-- Infinity Nikki aesthetic: pastel terrain palettes per zone style
local MaterialPalette = {}

local MaterialService = game:GetService("MaterialService")

MaterialPalette.palettes = {
	VillagePastel = {
		name = "VillagePastel",
		baseMaterial = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(160, 210, 150),
		roughness = 0.7,
		metallic = 0.1,
	},
	PagodaStone = {
		name = "PagodaStone",
		baseMaterial = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(255, 240, 245),
		roughness = 0.6,
		metallic = 0.05,
	},
	MysticGlow = {
		name = "MysticGlow",
		baseMaterial = Enum.Material.Neon,
		color = Color3.fromRGB(180, 200, 255),
		roughness = 0.3,
		metallic = 0.4,
	},
	AncientStone = {
		name = "AncientStone",
		baseMaterial = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(200, 200, 200),
		roughness = 0.8,
		metallic = 0.1,
	},
	MountainRock = {
		name = "MountainRock",
		baseMaterial = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(145, 215, 195),
		roughness = 0.9,
		metallic = 0.05,
	},
	KitchenWarm = {
		name = "KitchenWarm",
		baseMaterial = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(255, 200, 80),
		roughness = 0.5,
		metallic = 0.2,
	},
}

function MaterialPalette.registerAll()
	for _, palette in pairs(MaterialPalette.palettes) do
		MaterialPalette.register(palette)
	end
	print("[MaterialPalette] Registered " .. #MaterialPalette.palettes .. " material palettes")
end

function MaterialPalette.register(palette)
	if not MaterialService then
		return
	end
	local variant = Instance.new("MaterialVariant")
	variant.Name = palette.name
	variant.BaseMaterial = palette.baseMaterial
	variant:SetAttribute("PaletteColor", palette.color)
	variant:SetAttribute("PaletteRoughness", palette.roughness)
	variant:SetAttribute("PaletteMetallic", palette.metallic)
	variant.Parent = MaterialService
	return variant
end

function MaterialPalette.getPalette(name)
	return MaterialPalette.palettes[name]
end

function MaterialPalette.getAllNames()
	local names = {}
	for name, _ in pairs(MaterialPalette.palettes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return MaterialPalette
