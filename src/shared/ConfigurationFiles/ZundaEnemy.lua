-- ZundaEnemy: Configuration for Zundamon-based enemy actors ("Zun Darooms")
-- The Zundamon FBX was imported as asset 90496451961258 and placed in ServerStorage.
-- Reference: game.ServerStorage.Zundamon_Enemy_Mesh
--
-- To spawn a Zun Daroom:
-- 1. Clone from ServerStorage.Zundamon_Enemy_Mesh
-- 2. Parent to workspace
-- 3. Apply CollectionService tag "Enemy" for damage/combat system
-- 4. Use Zunda_EnemyGlow texture for hostile aura

return {
	meshAssetId = 90496451961258,
	modelPath = "Zundamon_Enemy_Mesh",

	-- Visual effects for enemy state
	visuals = {
		idleGlow = "rbxassetid://108800516066749",
		aggroColor = Color3.fromRGB(255, 80, 80),
		hurtColor = Color3.fromRGB(255, 200, 200),
		shieldColor = Color3.fromRGB(100, 180, 255),
	},

	-- Combat stats placeholder
	stats = {
		health = 100,
		speed = 16,
		damage = 10,
		aggroRange = 40,
	},

	-- Spawn locations near kitchen
	spawnPoints = {
		Vector3.new(20, 10, 20),
		Vector3.new(-20, 10, -20),
		Vector3.new(25, 10, -15),
		Vector3.new(-22, 10, 18),
	},
}
