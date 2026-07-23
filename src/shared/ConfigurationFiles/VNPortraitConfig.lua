--!strict
-- VNPortraitConfig
-- Maps VN speaker keys (and the tutorial mascot) to uploaded Roblox IMAGE asset IDs.
--
-- NOTE: Roblox cannot render animated GIFs. To use the Zundamon emote art, upload a
-- frame (or spritesheet) of each emote as a Roblox image/decal asset and paste its
-- `rbxassetid://<id>` below. An empty string means "no image" — the VN/tutorial falls
-- back to the emoji portrait, so this is safe to ship with blanks.
--
-- Source art lives at site/assets/zundamon_emote_<group><variant>.gif (1a..7c).
-- Upload helper: scripts/upload_decal.py (needs ROBLOX_OPEN_CLOUD_API_KEY).
local VNPortraitConfig = {}

-- Speaker key -> portrait image asset id (""=emoji fallback).
VNPortraitConfig.speakerImages = {
	zundamon = "",
	zundapal = "",
}

-- Optional: emote-keyed variants, if you want the VN to swap expression per line
-- (wire via VNPortraitConfig.getEmoteImage). Group names are illustrative.
VNPortraitConfig.emoteImages = {
	cheer = "", -- emote_1x
	point = "", -- emote_2x
}

-- Small Zundamon mascot shown on tutorial cards ("" = hidden).
VNPortraitConfig.tutorialMascot = ""

function VNPortraitConfig.getSpeakerImage(key: string?): string
	if not key then
		return ""
	end
	return VNPortraitConfig.speakerImages[key] or ""
end

function VNPortraitConfig.getEmoteImage(emote: string?): string
	if not emote then
		return ""
	end
	return VNPortraitConfig.emoteImages[emote] or ""
end

return VNPortraitConfig
