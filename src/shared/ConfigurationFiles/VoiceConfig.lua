--!strict
-- [[ModuleScript] VoiceConfig]]
-- Zundamon character voice (VO) bank — GENERATED FILE, DO NOT HAND-EDIT.
--
-- Source of truth: scripts/voiceline_manifest.py
-- Regenerate:      python scripts/voicevox_voiceline_worker.py
--                  python scripts/upload_audio.py
--                  python scripts/emit_voice_config.py
--
-- Attribution (see CREDITS.md): VOICEVOX:ずんだもん
-- Zundamon character rights: SSS LLC (https://zunko.jp)
--
-- Lines are Japanese by design: VOICEVOX synthesizes Japanese only, and Zundamon
-- is canonically Japanese-voiced. UI text stays English.
--
-- Each moment holds several variants; the runtime picks at random so repeated
-- actions don't replay one identical clip. Cooldowns throttle high-frequency
-- moments — see ZundaSoundController.playVoice.

local VoiceConfig = {}

-- Master switch + volume. Voice sits above UI SFX in the mix but below music
-- stingers, so it reads as character presence rather than narration.
VoiceConfig.Enabled = true
VoiceConfig.MasterVolume = 0.8

-- Minimum seconds between two plays of the same moment. 0 = always play.
VoiceConfig.Cooldowns = {
	challenge_start = 0.0,
	coin_earn = 15.0,
	companion_buff = 10.0,
	companion_greeting = 30.0,
	companion_pet = 2.0,
	cook_good = 10.0,
	cook_miss = 6.0,
	cook_perfect = 4.0,
	cook_start = 8.0,
	daily_claim = 0.0,
	guest_left = 8.0,
	guest_served = 5.0,
	idle_weary = 90.0,
	idle_whisper = 45.0,
	level_up = 0.0,
	quest_complete = 0.0,
	tier_up = 0.0,
	wave_complete = 0.0,
}

-- 0/42 clips uploaded. Pending clips are listed
-- as comments and simply aren't picked until they resolve.
VoiceConfig.Moments = {
	challenge_start = {
		-- PENDING UPLOAD: challenge_start_1 -- 本気を出すのだ！ [tsun, 1.23s]
		-- PENDING UPLOAD: challenge_start_2 -- 負けないのだ！ [tsun, 0.98s]
	},
	coin_earn = {
		-- PENDING UPLOAD: coin_earn_1 -- お金が増えたのだ！ [normal, 1.58s]
		-- PENDING UPLOAD: coin_earn_2 -- ずんだ餅が買えるのだ！ [normal, 1.92s]
	},
	companion_buff = {
		-- PENDING UPLOAD: companion_buff_1 -- ずんだパワー、注入なのだ！ [normal, 2.44s]
		-- PENDING UPLOAD: companion_buff_2 -- 力が湧いてくるのだ！ [normal, 1.58s]
	},
	companion_greeting = {
		-- PENDING UPLOAD: companion_greeting_1 -- やっほー、今日も一緒に料理するのだ！ [normal, 2.7s]
		-- PENDING UPLOAD: companion_greeting_2 -- ずんだもん、参上なのだ！ [normal, 2.21s]
		-- PENDING UPLOAD: companion_greeting_3 -- おかえりなのだ、待ってたのだ！ [sweet, 2.81s]
	},
	companion_pet = {
		-- PENDING UPLOAD: companion_pet_1 -- えへへ、くすぐったいのだ〜 [sweet, 2.67s]
		-- PENDING UPLOAD: companion_pet_2 -- もっと撫でてもいいのだ！ [sweet, 1.96s]
		-- PENDING UPLOAD: companion_pet_3 -- ずんだもん、幸せなのだ〜 [sweet, 3.08s]
	},
	cook_good = {
		-- PENDING UPLOAD: cook_good_1 -- いい感じなのだ！ [normal, 1.38s]
		-- PENDING UPLOAD: cook_good_2 -- その調子なのだ！ [normal, 1.47s]
	},
	cook_miss = {
		-- PENDING UPLOAD: cook_miss_1 -- あぁ、惜しいのだ〜 [tsun, 1.81s]
		-- PENDING UPLOAD: cook_miss_2 -- 次はうまくやるのだ！ [tsun, 1.57s]
	},
	cook_perfect = {
		-- PENDING UPLOAD: cook_perfect_1 -- 完璧なのだ！ [sweet, 1.32s]
		-- PENDING UPLOAD: cook_perfect_2 -- すごく上手なのだ！ [sweet, 1.59s]
		-- PENDING UPLOAD: cook_perfect_3 -- これぞ最高の一品なのだ！ [sweet, 2.31s]
	},
	cook_start = {
		-- PENDING UPLOAD: cook_start_1 -- さあ、料理を始めるのだ！ [normal, 2.26s]
		-- PENDING UPLOAD: cook_start_2 -- 腕の見せどころなのだ！ [normal, 1.65s]
	},
	daily_claim = {
		-- PENDING UPLOAD: daily_claim_1 -- 今日のご褒美なのだ！ [sweet, 1.82s]
		-- PENDING UPLOAD: daily_claim_2 -- 毎日来てくれて嬉しいのだ！ [sweet, 2.61s]
	},
	guest_left = {
		-- PENDING UPLOAD: guest_left_1 -- あぁ、行っちゃったのだ…… [teary, 3.35s]
		-- PENDING UPLOAD: guest_left_2 -- 次はもっと早く作るのだ…… [teary, 2.98s]
	},
	guest_served = {
		-- PENDING UPLOAD: guest_served_1 -- 喜んでるのだ！ [sweet, 1.41s]
		-- PENDING UPLOAD: guest_served_2 -- いただきます、なのだ〜！ [sweet, 2.17s]
		-- PENDING UPLOAD: guest_served_3 -- 大成功なのだ！ [sweet, 1.5s]
	},
	idle_weary = {
		-- PENDING UPLOAD: idle_weary_1 -- ちょっと疲れたのだ〜 [weary, 2.34s]
	},
	idle_whisper = {
		-- PENDING UPLOAD: idle_whisper_1 -- のんびりするのも、いいのだ〜 [whisper, 2.84s]
		-- PENDING UPLOAD: idle_whisper_2 -- いい匂いがするのだ…… [whisper, 1.6s]
		-- PENDING UPLOAD: idle_whisper_3 -- ずんだ餅、食べたいのだ…… [hushed, 3.08s]
		-- PENDING UPLOAD: idle_whisper_4 -- 今日はいい天気なのだ [whisper, 1.89s]
	},
	level_up = {
		-- PENDING UPLOAD: level_up_1 -- レベルアップなのだ！やったのだ！ [sweet, 2.7s]
		-- PENDING UPLOAD: level_up_2 -- また一歩、名シェフに近づいたのだ！ [sweet, 3.37s]
		-- PENDING UPLOAD: level_up_3 -- すごいのだ！ずんだもん感動なのだ！ [sweet, 3.05s]
	},
	quest_complete = {
		-- PENDING UPLOAD: quest_complete_1 -- クエスト達成なのだ！ [normal, 1.64s]
		-- PENDING UPLOAD: quest_complete_2 -- よくやったのだ！ [normal, 1.14s]
	},
	tier_up = {
		-- PENDING UPLOAD: tier_up_1 -- ランクが上がったのだ！ [sweet, 1.66s]
		-- PENDING UPLOAD: tier_up_2 -- もう一人前のシェフなのだ！ [sweet, 2.21s]
	},
	wave_complete = {
		-- PENDING UPLOAD: wave_complete_1 -- ウェーブ突破なのだ！ [sweet, 1.59s]
		-- PENDING UPLOAD: wave_complete_2 -- この調子で行くのだ！ [sweet, 1.66s]
	},
}

-- Pick a random variant for `moment`, or nil if none are available yet.
function VoiceConfig.pick(moment: string): string?
	local variants = VoiceConfig.Moments[moment]
	if not variants or #variants == 0 then
		return nil
	end
	return variants[math.random(1, #variants)]
end

-- Cooldown for `moment` (0 when unthrottled).
function VoiceConfig.getCooldown(moment: string): number
	return VoiceConfig.Cooldowns[moment] or 0
end

return VoiceConfig
