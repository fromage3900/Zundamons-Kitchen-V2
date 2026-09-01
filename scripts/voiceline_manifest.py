#!/usr/bin/env python3
"""
Zundamon Voiceline Manifest — Zundamon's Kitchen V2

The authoritative script for every Zundamon VO clip in the game. Each entry maps
a *game moment* to Japanese line text, a VOICEVOX style, and prosody tweaks.

Design notes:
- Zundamon canonically speaks Japanese ending in 〜のだ / 〜なのだ. UI text stays
  English; the VO is Japanese. That pairing is intentional and matches how the
  character is voiced everywhere else.
- Every moment has MULTIPLE variants. Single-clip VO becomes grating fast on
  high-frequency events (cooking, serving), so the runtime picks at random —
  same pattern SoundConfig already uses for its {"u","u2"} letter tables.
- `key` is the runtime lookup name and must stay stable: VoiceConfig.lua and any
  uploaded asset descriptions are keyed off it.
- Keep lines SHORT. These fire during play, not in a cutscene. Anything over
  ~2.5s will talk over the next action.

Attribution (see CREDITS.md): VOICEVOX:ずんだもん — character rights SSS LLC.
"""

from voicevox_client import STYLES

# ─── Prosody presets ─────────────────────────────────────────────────────────
# speed / pitch / intonation / volume, passed through to VOICEVOX.

EXCITED = {"speed": 1.12, "pitch": 0.03, "intonation": 1.25, "volume": 1.0}
WARM = {"speed": 1.0, "pitch": 0.0, "intonation": 1.1, "volume": 1.0}
CALM = {"speed": 0.92, "pitch": -0.02, "intonation": 0.9, "volume": 0.9}
ASMR = {"speed": 0.86, "pitch": -0.03, "intonation": 0.8, "volume": 0.85}
SHARP = {"speed": 1.08, "pitch": 0.0, "intonation": 1.2, "volume": 0.95}
SAD = {"speed": 0.9, "pitch": -0.04, "intonation": 0.95, "volume": 0.9}


def line(key, text, style, prosody, note=""):
    return {
        "key": key,
        "text": text,
        "style": STYLES[style],
        "style_name": style,
        "note": note,
        **prosody,
    }


# ─── The script ──────────────────────────────────────────────────────────────
# Grouped by the system that fires them. `note` documents the code hook so the
# wiring pass has a map to work from.

VOICELINES = [
    # ── Companion: greeting ──────────────────────────────────────────────
    # Replaces SoundConfig.Companion.greeting (placeholder 4612374495)
    line("companion_greeting_1", "やっほー、今日も一緒に料理するのだ！", "normal", EXCITED,
         "CompanionManager spawn"),
    line("companion_greeting_2", "ずんだもん、参上なのだ！", "normal", EXCITED,
         "CompanionManager spawn"),
    line("companion_greeting_3", "おかえりなのだ、待ってたのだ！", "sweet", WARM,
         "CompanionManager spawn / rejoin"),

    # ── Companion: pet ───────────────────────────────────────────────────
    # Replaces SoundConfig.Companion.pet
    line("companion_pet_1", "えへへ、くすぐったいのだ〜", "sweet", WARM, "pet interaction"),
    line("companion_pet_2", "もっと撫でてもいいのだ！", "sweet", WARM, "pet interaction"),
    line("companion_pet_3", "ずんだもん、幸せなのだ〜", "sweet", CALM, "pet interaction"),

    # ── Companion: buff ──────────────────────────────────────────────────
    # Replaces SoundConfig.Companion.buff
    line("companion_buff_1", "ずんだパワー、注入なのだ！", "normal", EXCITED, "companion buff apply"),
    line("companion_buff_2", "力が湧いてくるのだ！", "normal", EXCITED, "companion buff apply"),

    # ── Cooking ──────────────────────────────────────────────────────────
    line("cook_start_1", "さあ、料理を始めるのだ！", "normal", EXCITED, "CookingController session start"),
    line("cook_start_2", "腕の見せどころなのだ！", "normal", EXCITED, "CookingController session start"),
    # Kept short on purpose: these fire inside the rhythm minigame, where a long
    # line overlaps the next note. Ceremonial moments below can run longer.
    line("cook_perfect_1", "完璧なのだ！", "sweet", EXCITED,
         "SoundMap.CookingPerfect / quality=='perfect'"),
    line("cook_perfect_2", "すごく上手なのだ！", "sweet", EXCITED, "quality=='perfect'"),
    line("cook_perfect_3", "これぞ最高の一品なのだ！", "sweet", EXCITED, "quality=='perfect'"),
    line("cook_good_1", "いい感じなのだ！", "normal", WARM, "quality=='great'/'good'"),
    line("cook_good_2", "その調子なのだ！", "normal", WARM, "quality=='great'/'good'"),
    line("cook_miss_1", "あぁ、惜しいのだ〜", "tsun", SHARP, "SoundMap.CookingMiss"),
    line("cook_miss_2", "次はうまくやるのだ！", "tsun", SHARP, "SoundMap.CookingMiss"),

    # ── Serving / guests ─────────────────────────────────────────────────
    line("guest_served_1", "喜んでるのだ！", "sweet", EXCITED, "ServingService serve success"),
    line("guest_served_2", "いただきます、なのだ〜！", "sweet", WARM, "ServingService serve success"),
    line("guest_served_3", "大成功なのだ！", "sweet", EXCITED, "ServingService serve success"),
    line("guest_left_1", "あぁ、行っちゃったのだ……", "teary", SAD, "GuestManager patience expired"),
    line("guest_left_2", "次はもっと早く作るのだ……", "teary", SAD, "GuestManager patience expired"),

    # ── Progression ──────────────────────────────────────────────────────
    line("level_up_1", "レベルアップなのだ！やったのだ！", "sweet", EXCITED, "RewardEvents.LevelUpEvent"),
    line("level_up_2", "また一歩、名シェフに近づいたのだ！", "sweet", EXCITED, "RewardEvents.LevelUpEvent"),
    line("level_up_3", "すごいのだ！ずんだもん感動なのだ！", "sweet", EXCITED, "RewardEvents.LevelUpEvent"),
    line("tier_up_1", "ランクが上がったのだ！", "sweet", EXCITED, "chef tier promotion"),
    line("tier_up_2", "もう一人前のシェフなのだ！", "sweet", EXCITED, "chef tier promotion"),
    line("quest_complete_1", "クエスト達成なのだ！", "normal", EXCITED, "SoundMap.QuestComplete"),
    line("quest_complete_2", "よくやったのだ！", "normal", EXCITED, "SoundMap.QuestComplete"),
    line("coin_earn_1", "お金が増えたのだ！", "normal", WARM, "SoundMap.CoinEarn"),
    line("coin_earn_2", "ずんだ餅が買えるのだ！", "normal", WARM, "SoundMap.CoinEarn"),

    # ── Challenge / daily ────────────────────────────────────────────────
    line("challenge_start_1", "本気を出すのだ！", "tsun", EXCITED, "ChallengeModeService start"),
    line("challenge_start_2", "負けないのだ！", "tsun", EXCITED, "ChallengeModeService start"),
    line("wave_complete_1", "ウェーブ突破なのだ！", "sweet", EXCITED, "ChallengeModeService wave clear"),
    line("wave_complete_2", "この調子で行くのだ！", "sweet", EXCITED, "ChallengeModeService wave clear"),
    line("daily_claim_1", "今日のご褒美なのだ！", "sweet", WARM, "DailyChallengeService claim"),
    line("daily_claim_2", "毎日来てくれて嬉しいのだ！", "sweet", WARM, "DailyChallengeService claim"),

    # ── Ambient / ASMR (the cozy-identity ask) ───────────────────────────
    # Low-frequency, proximity-gated idle barks. Whisper styles by design.
    line("idle_whisper_1", "のんびりするのも、いいのだ〜", "whisper", ASMR, "idle ambient bark"),
    line("idle_whisper_2", "いい匂いがするのだ……", "whisper", ASMR, "idle ambient bark"),
    line("idle_whisper_3", "ずんだ餅、食べたいのだ……", "hushed", ASMR, "idle ambient bark"),
    line("idle_whisper_4", "今日はいい天気なのだ", "whisper", ASMR, "idle ambient bark"),
    line("idle_weary_1", "ちょっと疲れたのだ〜", "weary", CALM, "long-session / low stamina bark"),

    # ── 12 Novel -damon Companions (Key Moments) ─────────────────────────
    # 1. Sumimon (墨もん)
    line("companion_sumimon_greet_1", "墨の香りと共に参上した……今日も美しき一皿を描こう。", "normal", CALM, "Sumimon spawn / equip"),
    line("companion_sumimon_bond3_1", "私の心に遺された空白を……そなたの料理が埋めてくれたのだ。", "whisper", ASMR, "Sumimon bond 3 confession"),
    line("companion_sumimon_unlock_1", "我が筆は、永遠にそなたの厨房を讃え続けよう！", "sweet", WARM, "Sumimon quest mastery unlock"),

    # 2. Kagamon (鏡もん)
    line("companion_kagamon_greet_1", "キラキラ輝く鏡もん登場だよ〜！ヒビなんて見えな〜い！", "sweet", EXCITED, "Kagamon spawn / equip"),
    line("companion_kagamon_bond3_1", "割れた破片を拾い集めてくれたのは……あなただけだよ。", "teary", SAD, "Kagamon bond 3 confession"),
    line("companion_kagamon_unlock_1", "最高のステージへ！二人でまぶしい光を届けようね！", "sweet", EXCITED, "Kagamon quest mastery unlock"),

    # 3. Suzurimon (鈴もん)
    line("companion_suzurimon_greet_1", "チリン……清めの鈴音とともに、厨房を守護いたす。", "normal", CALM, "Suzurimon spawn / equip"),
    line("companion_suzurimon_bond3_1", "深く沈んだ記憶も……この鈴の音がそなたへ導いてくれた。", "whisper", CALM, "Suzurimon bond 3 confession"),
    line("companion_suzurimon_unlock_1", "我が響き、永久にそなたのリズムを狂わせはせぬ！", "normal", SHARP, "Suzurimon quest mastery unlock"),

    # 4. Wasabimon (山葵もん)
    line("companion_wasabimon_greet_1", "精神を研ぎ澄ませ！雑念を捨てて包丁を握るのだ！", "tsun", SHARP, "Wasabimon spawn / equip"),
    line("companion_wasabimon_bond3_1", "……ふん。そなたの一皿なら、我が誇りとして認めよう。", "sweet", WARM, "Wasabimon bond 3 confession"),
    line("companion_wasabimon_unlock_1", "極意伝承！我が気迫をその包丁に宿すがよい！", "normal", EXCITED, "Wasabimon quest mastery unlock"),

    # 5. Yurimon (百合もん)
    line("companion_yurimon_greet_1", "宮廷の雅をこの厨房へ……優雅におもてなし致しましょう。", "sweet", WARM, "Yurimon spawn / equip"),
    line("companion_yurimon_bond3_1", "絢爛な宮殿よりも……そなたと囲む鍋こそ至高の宝ですわ。", "sweet", WARM, "Yurimon bond 3 confession"),
    line("companion_yurimon_unlock_1", "百合の香気と共に、最高級の栄誉をあなたに捧げます！", "sweet", EXCITED, "Yurimon quest mastery unlock"),

    # 6. Kinakomon (黄粉もん)
    line("companion_kinakomon_greet_1", "しっかり食べて大きくなるんだよ！今日もたっぷり粉を挽いたよ。", "sweet", WARM, "Kinakomon spawn / equip"),
    line("companion_kinakomon_bond3_1", "お前の成長を見るのが、何よりの幸せだよ……いつもありがとうね。", "sweet", WARM, "Kinakomon bond 3 confession"),
    line("companion_kinakomon_unlock_1", "黄金のきな粉で、心も体もぽかぽかにしてあげるからね！", "sweet", EXCITED, "Kinakomon quest mastery unlock"),

    # 7. Kuroyurimon (黒百合もん)
    line("companion_kuroyurimon_greet_1", "我が漆黒の契約に応じよ……な、なんてね！よろしくね！", "tsun", EXCITED, "Kuroyurimon spawn / equip"),
    line("companion_kuroyurimon_bond3_1", "闇の呪縛などではない……ただ、あなたと共にいたいだけなのだ。", "whisper", CALM, "Kuroyurimon bond 3 confession"),
    line("companion_kuroyurimon_unlock_1", "真なる盟約の結実！漆黒の魔力で厨房を焦がさず守護しよう！", "normal", EXCITED, "Kuroyurimon quest mastery unlock"),

    # 8. Matchamon (抹茶もん)
    line("companion_matchamon_greet_1", "一期一会の心で……今日も静けさと共に点てましょう。", "normal", CALM, "Matchamon spawn / equip"),
    line("companion_matchamon_bond3_1", "一服の茶を分かち合う……これ以上の平穏は世にございません。", "whisper", CALM, "Matchamon bond 3 confession"),
    line("companion_matchamon_unlock_1", "茶道の極致、ここに！そなたの連鎖を静かに後押しいたそう。", "sweet", WARM, "Matchamon quest mastery unlock"),

    # 9. Shisomon (紫蘇もん)
    line("companion_shisomon_greet_1", "クンクン……！良質な薬草の匂い！新種の実験を始めるぞ！", "normal", EXCITED, "Shisomon spawn / equip"),
    line("companion_shisomon_bond3_1", "この秘伝の漬物壺……世界でそなたにだけ見せてやろう！", "sweet", WARM, "Shisomon bond 3 confession"),
    line("companion_shisomon_unlock_1", "野草の神秘よ！遠くの採集素材もすべて丸見えにしてやるぞ！", "normal", EXCITED, "Shisomon quest mastery unlock"),

    # 10. Karintomon (花林糖もん)
    line("companion_karintomon_greet_1", "わっしょい！祭りだ祭りだー！カリッと香ばしく揚げるぜ！", "tsun", EXCITED, "Karintomon spawn / equip"),
    line("companion_karintomon_bond3_1", "祭りの後も寂しくねえ……お前とずっと屋台を引けるからな！", "sweet", WARM, "Karintomon bond 3 confession"),
    line("companion_karintomon_unlock_1", "大当たり連発！ドカンと大吉の奇跡を起こしてやるぜ！", "normal", EXCITED, "Karintomon quest mastery unlock"),

    # 11. Tsukimidamon (月見もん)
    line("companion_tsukimidamon_greet_1", "月影が厨房を照らします……静寂の夜を共に紡ぎましょう。", "whisper", CALM, "Tsukimidamon spawn / equip"),
    line("companion_tsukimidamon_bond3_1", "どれほど遠い月夜でも……あなたの灯りだけは見失いません。", "sweet", WARM, "Tsukimidamon bond 3 confession"),
    line("companion_tsukimidamon_unlock_1", "満月の祝福を！夜の静寂を黄金の輝きに変えてみせます。", "sweet", EXCITED, "Tsukimidamon quest mastery unlock"),

    # 12. Hoshidamon (干しもん)
    line("companion_hoshidamon_greet_1", "慌てるでない……お日様を浴びて、じっくり味を深めようぞ。", "normal", CALM, "Hoshidamon spawn / equip"),
    line("companion_hoshidamon_bond3_1", "年輪を重ねた木のように……そなたとの絆も熟成されたのう。", "sweet", WARM, "Hoshidamon bond 3 confession"),
    line("companion_hoshidamon_unlock_1", "天日干しの極意！じっくり煮込んだ鍋に二倍の旨味を注ごう！", "normal", WARM, "Hoshidamon quest mastery unlock"),

    # ── 5 Canon-linked Companions (Key Moments) ──────────────────────────
    # 1. Kiritandamon (きりたんもん)
    line("kiritandamon_morning", "計算通りです。朝の仕込みを始めましょう。", "normal", CALM, "Kiritandamon morning greeting"),
    line("kiritandamon_bond", "あなたのデータは...予想を超えています。修正します。", "normal", WARM, "Kiritandamon bond moment"),
    line("kiritandamon_questcomplete", "結果が出ました。合格です。", "tsundere", SHARP, "Kiritandamon approves"),

    # 2. Itakodamon (イタコもん)
    line("itakodamon_morning", "今朝の調理台に、古い記憶が宿っている。", "whisper", ASMR, "Itakodamon cryptic morning"),
    line("itakodamon_bond", "あの矢が放たれた日のことを、いつか話しましょう。", "whisper", SAD, "Itakodamon reveals bond"),
    line("itakodamon_questcomplete", "予言通りでした。よくやりました。", "normal", CALM, "Itakodamon oracle approves"),

    # 3. Zunkodamon (ずん子もん)
    line("zunkodamon_morning", "今日も厨房を制しましょう！出陣です！", "normal", EXCITED, "Zunkodamon battle cry"),
    line("zunkodamon_bond", "あなたと並んで戦えることを誇りに思います。", "normal", WARM, "Zunkodamon honor"),
    line("zunkodamon_questcomplete", "見事な勝利です！この一皿が全てを語っています！", "normal", EXCITED, "Zunkodamon victory"),

    # 4. Zunabunny (ずなばにー)
    line("zunabunny_morning", "おはようございます！今日もなんかやらかしそうな予感！", "sweet", EXCITED, "Zunabunny chaos morning"),
    line("zunabunny_bond", "ずんだもんに言ったら、知ってるって言われました！すごい！", "sweet", EXCITED, "Zunabunny tells Zundamon"),
    line("zunabunny_questcomplete", "えっ、うまくいったの？！奇跡！！！", "sweet", EXCITED, "Zunabunny surprised success"),

    # 5. Nanonadamon (なのだもん)
    line("nanonadamon_morning", "夜明けが来た、のだ。", "whisper", CALM, "Nanonadamon dawn observation"),
    line("nanonadamon_bond", "あなたの料理に、矢の記憶を感じる、のだ。", "whisper", ASMR, "Nanonadamon arrow memory"),
    line("nanonadamon_questcomplete", "これが、あの矢が目指した場所なのだ。", "whisper", CALM, "Nanonadamon finale"),
]


# ─── Grouping helper ─────────────────────────────────────────────────────────
# Runtime picks a random variant per moment; group by stripping the _N suffix.


def groups() -> dict:
    """Return {moment: [key, ...]} derived from the _N variant suffix."""
    out: dict = {}
    for entry in VOICELINES:
        moment = entry["key"].rsplit("_", 1)[0]
        out.setdefault(moment, []).append(entry["key"])
    return out


if __name__ == "__main__":
    g = groups()
    print(f"{len(VOICELINES)} lines across {len(g)} moments\n")
    for moment, keys in sorted(g.items()):
        print(f"  {moment:24s} x{len(keys)}")
