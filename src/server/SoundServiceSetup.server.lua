-- Creates letter-named Sound objects in SoundService for ZundaSoundController
-- Nomagician UI SFX pack (CC BY 4.0, nomagician.itch.io) recommended for custom uploads
-- This script sets up placeholder sounds that can be overridden in Studio

local SoundService = game:GetService("SoundService")

local UI_SOUNDS = {
	a = "rbxassetid://130892937201109", -- PanelOpen
	b = "rbxassetid://137810591146694", -- PanelClose
	c = "rbxassetid://120688551132909", -- ButtonHover
	d = "rbxassetid://101203621407636", -- ButtonClick
	e = "rbxassetid://108539778381969", -- ButtonConfirm
	f = "rbxassetid://102868290720640", -- ButtonCancel
	g = "rbxassetid://135198929165189", -- WheelOpen
	h = "rbxassetid://78940657789079",  -- WheelClose
	i = "rbxassetid://97320963967128",  -- WheelSelect
	j = "rbxassetid://83728048243563",  -- WheelNavigate
	k = "rbxassetid://79443534594425",  -- Notification
	l = "rbxassetid://133565712308985", -- Success
	m = "rbxassetid://115283511772131", -- Error
	n = "rbxassetid://137864973480093", -- Sparkle
	o = "rbxassetid://103621008452520", -- TabSwitch
	p = "rbxassetid://73558635732798",  -- CookingTick
	q = "rbxassetid://70615351304496",  -- CookingPerfect
	r = "rbxassetid://118823484418091", -- CookingMiss
	s = "rbxassetid://135590210918208", -- LevelUp
	t = "rbxassetid://138364422775995", -- QuestComplete
	u = "rbxassetid://97192669521415",  -- CoinEarn
	v = "rbxassetid://83051723346121",  -- Extra
	w = "rbxassetid://124595962197616", -- Extra
	h2 = "rbxassetid://136757242175376",-- WheelClose variant
	i2 = "rbxassetid://74881096957907", -- WheelSelect variant
	u2 = "rbxassetid://79124840858038", -- CoinEarn variant
}

local soundCount = 0
for letter, soundId in pairs(UI_SOUNDS) do
	soundCount += 1
	local existing = SoundService:FindFirstChild(letter)
	if existing and existing:IsA("Sound") then
		if existing.SoundId ~= soundId then
			existing.SoundId = soundId
		end
	else
		if existing then existing:Destroy() end
		local s = Instance.new("Sound")
		s.Name = letter
		s.SoundId = soundId
		s.Volume = 1
		s.Parent = SoundService
	end
end

-- Set master volume for UI sounds
SoundService:SetAttribute("SettingsBaseVolume", 0.7)

-- UI_SOUNDS is string-keyed, so #UI_SOUNDS was always 0 here regardless of the
-- pairs() loop above actually creating every sound correctly.
print("[SoundServiceSetup] " .. soundCount .. " UI sounds initialized (Nomagician-ready)")
