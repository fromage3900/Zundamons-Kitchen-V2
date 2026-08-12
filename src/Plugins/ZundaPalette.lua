--!strict
-- ZundaPalette: canonical Infinity Nikki pastel material presets for
-- Zundamon's Kitchen (AGENTS.md section 7).
-- Single source of truth for the Zunda material authoring workflows: the
-- Studio plugin (src/Plugins), level painters, and MaterialVariant configs.

local MaterialService = game:GetService("MaterialService")

local ZundaPalette = {}

ZundaPalette.materials = {
	ZundaGreen = {
		name = "ZundaGreen",
		displayName = "Zunda Green",
		color = Color3.fromRGB(160, 210, 150),
		baseMaterial = "SmoothPlastic",
		roughness = 0.6,
		metallic = 0.1,
		attributes = { Reflectance = 0.1 },
		notes = "Primary pea green",
	},
	ZundaGold = {
		name = "ZundaGold",
		displayName = "Zunda Gold",
		color = Color3.fromRGB(255, 200, 80),
		baseMaterial = "SmoothPlastic",
		roughness = 0.4,
		metallic = 0.2,
		attributes = { Reflectance = 0.15 },
		notes = "Accent gold",
	},
	ZundaPink = {
		name = "ZundaPink",
		displayName = "Zunda Pink",
		color = Color3.fromRGB(255, 150, 200),
		baseMaterial = "SmoothPlastic",
		roughness = 0.5,
		metallic = 0.1,
		attributes = { Reflectance = 0.2 },
		notes = "Blush accent",
	},
	ZundaMint = {
		name = "ZundaMint",
		displayName = "Zunda Mint",
		color = Color3.fromRGB(145, 215, 195),
		baseMaterial = "SmoothPlastic",
		roughness = 0.6,
		metallic = 0.1,
		attributes = { Reflectance = 0.1 },
		notes = "Mint accent",
	},
	MochiCream = {
		name = "MochiCream",
		displayName = "Mochi Cream",
		color = Color3.fromRGB(255, 245, 235),
		baseMaterial = "SmoothPlastic",
		roughness = 0.7,
		metallic = 0.05,
		attributes = {},
		notes = "Base/neutral surface",
	},
	EdamameDeep = {
		name = "EdamameDeep",
		displayName = "Edamame Deep",
		color = Color3.fromRGB(90, 140, 90),
		baseMaterial = "SmoothPlastic",
		roughness = 0.65,
		metallic = 0.1,
		attributes = {},
		notes = "Dark contrast",
	},
}

local BASE_MATERIALS: { [string]: Enum.Material } = {
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Plastic = Enum.Material.Plastic,
	Neon = Enum.Material.Neon,
	Wood = Enum.Material.WoodPlanks,
	Stone = Enum.Material.Cobblestone,
	Metal = Enum.Material.Metal,
	Glass = Enum.Material.Glass,
	Concrete = Enum.Material.Concrete,
	Grass = Enum.Material.Grass,
	Sand = Enum.Material.Sand,
	Brick = Enum.Material.Brick,
}

function ZundaPalette.getMaterial(name: string)
	return ZundaPalette.materials[name]
end

function ZundaPalette.getAllNames(): { string }
	local names = {}
	for name, _ in pairs(ZundaPalette.materials) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ZundaPalette.resolveBaseMaterial(name: string?): Enum.Material
	if name and BASE_MATERIALS[name] then
		return BASE_MATERIALS[name]
	end
	return Enum.Material.SmoothPlastic
end

-- Find (or create) the MaterialVariant in MaterialService. MaterialService is
-- the Studio-owned shared hub: variants persist with the place and travel with
-- it through Rojo/Git, so the palette stays the runtime source of truth.
function ZundaPalette.findOrCreateVariant(name: string, spec: any): MaterialVariant?
	local existing = MaterialService:FindFirstChild(name)
	if existing and existing:IsA("MaterialVariant") then
		return existing
	end
	local variant = Instance.new("MaterialVariant")
	variant.Name = name
	variant.BaseMaterial = ZundaPalette.resolveBaseMaterial(spec.baseMaterial)
	variant:SetAttribute("PaletteColor", spec.color)
	variant:SetAttribute("PaletteRoughness", spec.roughness)
	variant:SetAttribute("PaletteMetallic", spec.metallic)
	variant.Parent = MaterialService
	return variant
end

function ZundaPalette.registerAll()
	local count = 0
	for name, spec in pairs(ZundaPalette.materials) do
		ZundaPalette.findOrCreateVariant(name, spec)
		count += 1
	end
	return count
end

return ZundaPalette
