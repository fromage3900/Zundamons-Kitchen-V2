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
-- Upload helper: scripts/upload_decal.py (needs ROBLOX_OPEN_CLOUD_API_KEY)
-- One-shot converter+uploader: scripts/vn_emote_upload.py (see its header).
local VNPortraitConfig = {}

-- Speaker key -> portrait image asset id (""=emoji fallback).
VNPortraitConfig.speakerImages = {
	zundamon = "",
	zundapal = "",
}

-- Emote-keyed variants: each Zundamon expression maps to an uploaded decal.
-- Groups 1-7 = two poses (a = fists-up "ganbare", b = pointing/presenting),
-- plus a third c on group 7. Moods below are the semantic labels assigned to
-- each source frame (see scripts/vn_emote_upload.py for the mapping). Fill the
-- values with `rbxassetid://<id>` after upload; "" keeps the emoji fallback.
VNPortraitConfig.emoteImages = {
	-- Neutral / determined (fists up)
	neutral = "", -- 1a
	happy = "", -- 1b
	-- Presenting / explaining (pointing)
	presenting = "", -- 2a
	presenting_happy = "", -- 2b
	-- Surprised / excited
	surprised = "", -- 3a
	excited = "", -- 3b
	-- Emphatic pointing
	emphatic = "", -- 4a
	emphatic_happy = "", -- 4b
	-- Joyful (closed happy eyes)
	joyful = "", -- 5a
	confident = "", -- 5b
	joyful_point = "", -- 6a
	confident_point = "", -- 6b
	-- Content / calm
	content = "", -- 7a
	serious = "", -- 7b
	serious_point = "", -- 7c
}

-- Bond tier (1/2/3) -> default emote for that tier's dialogue, so the portrait
-- visibly grows with your bond without editing every line.
VNPortraitConfig.bondTierEmotes = {
	[1] = "neutral", -- freshly met
	[2] = "joyful", -- getting close
	[3] = "content", -- lifelong companion
}

-- Optional: emote-keyed variants per line, if you want the VN to swap
-- expression per line (wire via VNPortraitConfig.getEmoteImage + the `emote`
-- field on dialogue entries).
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

-- Map a bond tier to its default emote key ("" if unset).
function VNPortraitConfig.getBondTierEmote(bondTier: number?): string
	if not bondTier then
		return ""
	end
	return VNPortraitConfig.bondTierEmotes[bondTier] or ""
end

return VNPortraitConfig
