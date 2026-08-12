--!strict
-- ZoneProfiles: Infinity Nikki-style zone styling profiles
-- Each zone has a fashion identity, decoration weights, and style affinity
local ZoneProfiles = {}

ZoneProfiles.zones = {
	Village = {
		name = "Village",
		styleIdentity = "Casual Cute",
		bounds = { min = Vector3.new(-80, -10, -80), max = Vector3.new(80, 50, 80) },
		exclusionTags = { "NoScatter", "Building", "Interior" },
		decorationWeights = {
			lantern_post = 1.0,
			cherry_tree = 0.8,
			flower_cluster = 1.2,
			pastel_archway = 0.5,
			wind_chime = 0.7,
			signpost = 0.4,
		},
		materialVariant = "VillagePastel",
		styleAffinity = { "village", "garden", "path" },
	},
	Pagoda = {
		name = "Pagoda",
		styleIdentity = "Traditional Elegance",
		bounds = { min = Vector3.new(-60, -5, -60), max = Vector3.new(60, 80, 60) },
		styleAffinity = { "pagoda", "garden", "village" },
	},
	MysticForest = {
		name = "Mystic Forest",
		styleIdentity = "Dreamy Whimsy",
		bounds = { min = Vector3.new(-100, -20, -100), max = Vector3.new(100, 40, 100) },
		styleAffinity = { "forest", "mystic", "ruins" },
	},
	AncientRuins = {
		name = "Ancient Ruins",
		styleIdentity = "Vintage Romance",
		bounds = { min = Vector3.new(-90, -30, -90), max = Vector3.new(90, 30, 90) },
		styleAffinity = { "ruins", "mystic", "peaks" },
	},
	EastPeaks = {
		name = "East Peaks",
		styleIdentity = "Alpine Sporty",
		bounds = { min = Vector3.new(-120, 0, -120), max = Vector3.new(120, 100, 120) },
		styleAffinity = { "peaks", "mystic", "ruins" },
	},
	Kitchen = {
		name = "Kitchen",
		styleIdentity = "Culinary Cute",
		bounds = { min = Vector3.new(-30, -5, -30), max = Vector3.new(30, 20, 30) },
		styleAffinity = { "village", "garden", "path" },
	},
}

function ZoneProfiles.getZoneNames()
	local names = {}
	for name, _ in pairs(ZoneProfiles.zones) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ZoneProfiles.getZone(name)
	return ZoneProfiles.zones[name]
end

function ZoneProfiles.getStyleIdentity(zoneName)
	local zone = ZoneProfiles.zones[zoneName]
	return zone and zone.styleIdentity or "Unknown"
end

return ZoneProfiles
