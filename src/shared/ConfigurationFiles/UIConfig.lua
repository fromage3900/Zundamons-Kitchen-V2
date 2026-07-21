--!strict
-- [[ModuleScript] UIConfig]]
-- Centralized design tokens for all UI elements.
-- Colors, typography, spacing, corner radii, and animation curves live here.
-- Merged with DesignSystemConfig (Windsurf) — single source of truth.

local UIConfig = {
	-- Brand colors
	COLORS = {
		Primary       = Color3.fromRGB(100, 200, 80),   -- Zundamon green
		PrimaryDark   = Color3.fromRGB(60, 140, 50),
		Secondary     = Color3.fromRGB(255, 200, 80),   -- Warm gold
		SecondaryDark = Color3.fromRGB(200, 150, 40),
		Accent        = Color3.fromRGB(120, 180, 255),   -- Sky blue
		Danger        = Color3.fromRGB(220, 60, 60),
		Warning       = Color3.fromRGB(240, 180, 40),
		Success       = Color3.fromRGB(80, 200, 100),

		-- Neutrals (dark theme)
		Background    = Color3.fromRGB(30, 25, 20),
		Surface       = Color3.fromRGB(50, 42, 35),
		SurfaceLight  = Color3.fromRGB(70, 60, 50),
		Border        = Color3.fromRGB(200, 180, 150),
		BorderDim     = Color3.fromRGB(100, 90, 75),

		-- Light theme
		CreamWhite    = Color3.fromRGB(252, 248, 240),
		CreamLight    = Color3.fromRGB(255, 250, 245),
		CreamDark     = Color3.fromRGB(248, 240, 230),
		PanelBg       = Color3.fromRGB(252, 248, 240),
		PanelBorder   = Color3.fromRGB(180, 150, 110),

		-- Text
		TextPrimary   = Color3.fromRGB(255, 250, 240),
		TextSecondary = Color3.fromRGB(200, 190, 170),
		TextDisabled  = Color3.fromRGB(120, 110, 100),
		TextOnPrimary = Color3.fromRGB(20, 15, 10),
		TextWhite     = Color3.fromRGB(255, 255, 255),
		TextDark      = Color3.fromRGB(45, 45, 45),
		TextDarkSec   = Color3.fromRGB(77, 77, 77),

		-- Nature tones
		LeafGreen     = Color3.fromRGB(143, 201, 143),
		WoodLight     = Color3.fromRGB(212, 184, 150),
		WoodDefault   = Color3.fromRGB(196, 180, 148),
		WoodDark      = Color3.fromRGB(168, 144, 112),

		-- Rarity
		RarityCommon  = Color3.fromRGB(168, 168, 168),
		RarityUncommon = Color3.fromRGB(125, 217, 125),
		RarityRare    = Color3.fromRGB(120, 184, 248),
		RarityEpic    = Color3.fromRGB(184, 159, 247),
		RarityLegendary = Color3.fromRGB(255, 207, 80),

		-- Zundamon Brand Colors
		ZundamonGreen = Color3.fromRGB(124, 184, 124),
		PeaGreen = Color3.fromRGB(143, 201, 143),
		PeaLight = Color3.fromRGB(184, 224, 184),
		PeaDark = Color3.fromRGB(110, 175, 110),
		ZundamonPink = Color3.fromRGB(232, 152, 168),
		ZundamonGold = Color3.fromRGB(255, 200, 80),

		-- Kitchen Theme
		KitchenCream = Color3.fromRGB(252, 248, 240),
		KitchenWood = Color3.fromRGB(196, 180, 148),
	},

	-- Transparency presets (0 = opaque, 1 = invisible)
	TRANSPARENCY = {
		Opaque      = 0,
		Panel       = 0.1,
		Overlay     = 0.3,
		Ghost       = 0.6,
		Invisible   = 1,
	},

	-- Typography (Font.new for Roblox Font API)
	FONTS = {
		Title    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		Heading  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
		Body     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
		Caption  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
		Mono     = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
		Decorative = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
	},

	FONT_SIZES = {
		Title   = 28,
		TitleLarge = 36,
		Heading = 22,
		Body    = 16,
		Small   = 14,
		Caption = 12,
		Button  = 18,
		Tooltip = 14,
	},

	-- Spacing scale (pixels)
	SPACING = {
		XS  = 4,
		SM  = 8,
		MD  = 12,
		LG  = 16,
		XL  = 24,
		XXL = 32,
	},

	-- Corner radius
	CORNER_RADIUS = {
		None   = UDim.new(0, 0),
		Tiny   = UDim.new(0, 4),
		Small  = UDim.new(0, 8),
		Medium = UDim.new(0, 12),
		Large  = UDim.new(0, 16),
		Pill   = UDim.new(0, 999),
		Circle = UDim.new(0.5, 0),
	},

	-- Stroke / border
	STROKE = {
		Thin   = 1,
		Normal = 2,
		Thick  = 3,
		Thickest = 4,
	},

	-- Animation durations (seconds)
	ANIMATION = {
		Instant  = 0,
		Fast     = 0.15,
		Normal   = 0.25,
		Slow     = 0.4,
		Slowest  = 0.8,
		FadeIn   = 0.3,
		FadeOut  = 0.2,
		SlideIn  = 0.35,
	},

	-- Easing styles
	EASING = {
		Default  = Enum.EasingStyle.Quad,
		Bounce   = Enum.EasingStyle.Back,
		Smooth   = Enum.EasingStyle.Sine,
		Snappy   = Enum.EasingStyle.Exponential,
		Elastic  = Enum.EasingStyle.Elastic,
	},

	-- Standard component sizes
	SIZES = {
		ButtonHeight      = 44,
		ButtonMinWidth    = 120,
		ButtonPadding     = 24,
		ButtonLargeHeight = 56,
		ButtonSmallHeight = 36,
		IconSmall         = 24,
		IconMedium        = 36,
		IconLarge         = 48,
		ItemSlot          = 64,
		ProgressBarHeight = 24,
		ProgressBarWidth  = 200,
		TooltipMaxWidth   = 280,
		PanelMinWidth     = 300,
		InputHeight       = 48,
		InputPadding      = 16,
		CardPadding       = 20,
	},

	-- Game-specific colors (cooking, HUD, progression)
	GAME_COLORS = {
		CookingTrack   = Color3.fromRGB(235, 255, 225),
		CookingTarget  = Color3.fromRGB(180, 245, 190),
		CookingPerfect = Color3.fromRGB(255, 200, 80),
		CookingGreat   = Color3.fromRGB(120, 220, 140),
		CookingGood    = Color3.fromRGB(180, 180, 220),
		CookingMiss    = Color3.fromRGB(220, 100, 110),
		HUDBg          = Color3.fromRGB(40, 32, 60),
		HUDText        = Color3.fromRGB(255, 255, 255),
		HUDAccent      = Color3.fromRGB(120, 200, 130),
		ProgressBg     = Color3.fromRGB(255, 248, 235),
		ProgressText   = Color3.fromRGB(80, 55, 35),
		ProgressSub    = Color3.fromRGB(140, 110, 80),
		ProgressAccent = Color3.fromRGB(180, 150, 110),
		SparkleGold    = Color3.fromRGB(255, 220, 90),
		ComboFire      = Color3.fromRGB(255, 100, 80),
		ComboWarm      = Color3.fromRGB(255, 180, 80),
	},

	-- Visual effects (shadows, glows)
	EFFECTS = {
		ButtonShadow = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.85, Offset = Vector2.new(0, 4), Size = 12 },
		PanelShadow  = { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.9,  Offset = Vector2.new(0, 8), Size = 16 },
		Glow         = { Color = Color3.fromRGB(100, 200, 80), Transparency = 0.7, Offset = Vector2.new(0, 0), Size = 8 },
		HUDGlow      = { Color = Color3.fromRGB(120, 200, 130), Transparency = 0.6, Offset = Vector2.new(0, 0), Size = 6 },
	},

	-- Z-index layers
	LAYERS = {
		Background   = 1,
		Content      = 10,
		Panel        = 20,
		Overlay      = 30,
		Modal        = 40,
		Tooltip      = 50,
		Notification = 60,
	},

	-- Helper: get color by name with fallback
	getColor = function(self, name)
		return self.COLORS[name] or Color3.fromRGB(128, 128, 128)
	end,

	-- Helper: get font size by name
	getFontSize = function(self, name)
		return self.FONT_SIZES[name] or 16
	end,
}

return UIConfig
