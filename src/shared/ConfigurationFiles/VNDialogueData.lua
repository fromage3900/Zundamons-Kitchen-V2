-- [[ModuleScript] VNDialogueData]]
-- Registry for speakers and companion-specific branching dialogue
-- 5 companions with unique personalities + level-based branches

local Players = game:GetService("Players")

local RGB = Color3.fromRGB

-- Speaker configurations with companion emojis
local SPEAKERS = {}
SPEAKERS.zundamon = { name = "Zundamon", emoji = "🍙", accent = RGB(160, 210, 150), portrait = RGB(180, 220, 170) }
SPEAKERS.zundapal = { name = "Zundapal", emoji = "🍡", accent = RGB(200, 230, 180), portrait = RGB(210, 235, 195) }
SPEAKERS.narrator = { name = "", emoji = "✨", accent = RGB(220, 200, 170), portrait = RGB(230, 220, 200) }
SPEAKERS.elder = { name = "Village Elder", emoji = "🏮", accent = RGB(220, 180, 130), portrait = RGB(230, 200, 160) }
SPEAKERS.ruins = { name = "Ancient Voice", emoji = "👁", accent = RGB(190, 170, 210), portrait = RGB(210, 195, 220) }
SPEAKERS.chef = { name = "Head Chef", emoji = "🍳", accent = RGB(230, 185, 130), portrait = RGB(240, 210, 170) }
SPEAKERS.system = { name = "", emoji = "⭐", accent = RGB(210, 195, 235), portrait = RGB(225, 215, 240) }
SPEAKERS.ankomon = { name = "Ankomon", emoji = "🦴", accent = RGB(180, 180, 190), portrait = RGB(200, 200, 210) }
SPEAKERS.cardamon = { name = "Cardamon", emoji = "🌿", accent = RGB(180, 210, 180), portrait = RGB(200, 230, 200) }
SPEAKERS.antimon = { name = "Antimon", emoji = "⚡", accent = RGB(210, 220, 150), portrait = RGB(230, 240, 180) }
SPEAKERS.sakuradamon =
	{ name = "Sakuradamon", emoji = "🌸", accent = RGB(255, 180, 200), portrait = RGB(255, 220, 230) }

-- Companion-specific branching dialogue (time + level based)
local COMPANION_DIALOGUE = {}
COMPANION_DIALOGUE.zundapal = {
	morning = {
		"Good morning, {player}~ ☀️",
		"Ready to cook up something wonderful today?",
		"I can already smell the kitchen from here! 🍳",
	},
	afternoon = {
		"Hey, {player}! You're doing great~ ✨",
		"Have you tried any of the new recipes yet?",
		"The guests look hungry... let's get cooking! 🍡",
	},
	evening = {
		"The sunset is so pretty from here... 🌅",
		"You worked so hard today, {player}.",
		"I'll be right here beside you, always~ 💫",
	},
	night = {
		"Psst — {player}... still awake? 🌙",
		"The stars are beautiful tonight...",
		"Even chefs deserve a rest. I'll keep watch~ ⭐",
	},
	level1_10 = { "Starting your journey? I believe in you! 🌱", "Let's gather some basic ingredients first." },
	level11_20 = { "You're getting the hang of this! ✨", "Try making Zunda Mochi - it's my favorite!" },
	level21_50 = { "Amazing progress, chef! 🌟", "You've mastered so many recipes already." },
}
COMPANION_DIALOGUE.ankomon = {
	morning = {
		"Training begins at dawn, {player}.",
		"Every great chef needs discipline. ⚖️",
		"Shall we practice precision cooking? 🔥",
	},
	afternoon = { "Your XP gain increases with focused effort.", "Try perfect timing for maximum efficiency!" },
	level1_10 = { "Don't rush technique. Master the basics first." },
	level11_20 = { "Excellent form! Your XP multiplier is active." },
	level21_50 = { "True mastery! Double XP for you now." },
}
COMPANION_DIALOGUE.cardamon = {
	morning = { "Breathe in the fresh aromas, {player}~", "Patience reveals the best flavors. 🧘" },
	night = { "The herbs whisper secrets in the moonlight...", "Rest well, young chef. Tomorrow brings new recipes." },
	level1_10 = { "Slower timing gives better results for beginners." },
	level11_20 = { "Your timing window is wider now - use it wisely!" },
	level21_50 = { "Perfect zen state achieved - flawless cooking ahead." },
}
COMPANION_DIALOGUE.antimon = {
	morning = { "Time is ingredients, {player}! ⚡", "Let's cook at lightning speed!" },
	afternoon = { "Faster craft time means more dishes! 🚀", "I can feel the energy accelerating!" },
	level1_10 = { "Haste makes waste... but I'll help you go fast!" },
	level11_20 = { "Your crafting speed buff is ready!" },
	level21_50 = { "No time wasted - pure efficiency!" },
}
COMPANION_DIALOGUE.sakuradamon = {
	morning = { "The sakura blossoms bloom with the seasons~ 🌸", "Seek rare ingredients for special recipes!" },
	night = { "The moon blesses secret ingredients tonight...", "If you listen closely, you'll find their locations." },
	level1_10 = { "Rare drops appear with luck - I sense some nearby!" },
	level11_20 = { "Your rare drop chance has increased!" },
	level21_50 = { "Legendary ingredients reveal themselves to you..." },
}

-- Side dialogue triggers (item/lore discoveries)
local SIDE_DIALOGUES = {}
SIDE_DIALOGUES.zunda_pea = {
	speaker = "zundapal",
	text = "Oh! You found some Zunda Peas! 🫛",
	hint = "Those are my favorite~ They're so sweet and green!",
	recipe = "Did you know you can make Zunda Mochi with them? 🍡",
}
SIDE_DIALOGUES.zunda_mochi = {
	speaker = "zundapal",
	text = "Zunda Mochi is a special treat! 🍡",
	lore = "It's made from sweet green peas, mashed into paste~",
	tip = "The texture is so chewy and delicious! 💚",
}
SIDE_DIALOGUES.wheat = {
	speaker = "zundapal",
	text = "Wheat is the base of so many dishes! 🌾",
	tip = "Harvest carefully - golden wheat makes golden bread!",
}
SIDE_DIALOGUES.royal_stew = {
	speaker = "ankomon",
	text = "Royal Stew - the pinnacle of cooking! 👑",
	tip = "Requires Gold Ore for true regality.",
}
SIDE_DIALOGUES.seasonal = {
	summer = {
		speaker = "sakuradamon",
		text = "Summer brings the rare Summer Salad! ☀️",
		hint = "Add Zunda Berry to your Bread for a seasonal twist.",
	},
	winter = {
		speaker = "sakuradamon",
		text = "Winter's warmth comes from Warm Stew! ❄️",
		hint = "Gold Ore makes it extra nourishing in cold months.",
	},
}

-- Guest dialogue triggers
local GUEST_DIALOGUE = {}
GUEST_DIALOGUE.spawn = {
    speaker = "guest",
    text = "Hi there! I'd love some {recipe}! 🍽️",
}
GUEST_DIALOGUE.served = {
    speaker = "guest",
    text = "Thank you! This is delicious! 😋 +{gold} gold",
}
GUEST_DIALOGUE.timeout = {
    speaker = "guest",
    text = "I've been waiting too long... I'm leaving! 😞",
}
GUEST_DIALOGUE.wrong_dish = {
    speaker = "guest",
    text = "This isn't what I ordered... 🤔",
}

-- Guest type-specific dialogues
local GUEST_BY_TYPE = {}
GUEST_BY_TYPE.female = {
    spawn = "Hello! Could I get some {recipe}? 💕",
    served = "Perfect! Thank you so much! ✨",
    timeout = "I can't wait any longer... 💔",
    wrong_dish = "This isn't what I wanted... 😢",
}
GUEST_BY_TYPE.male = {
    spawn = "Hey, got any {recipe}? 🍽️",
    served = "Awesome! Thanks, chef! 👍",
    timeout = "Gotta go, can't wait forever! 🚶",
    wrong_dish = "Wrong order, buddy! 😕",
}
GUEST_BY_TYPE.parrot = {
    spawn = "Squawk! {recipe}! Squawk! 🦜",
    served = "Pretty good! Squawk! 🎉",
    timeout = "Squawk! Too slow! Fly away! 🦜💨",
    wrong_dish = "Squawk! Wrong! Squawk! ❌",
}
GUEST_BY_TYPE.lotus = {
    spawn = "I seek the essence of {recipe}... 🌸",
    served = "The flavors bloom... thank you. 🌺",
    timeout = "The petals wilt... I must depart. 🥀",
    wrong_dish = "This is not the essence I seek... 🌑",
}
GUEST_BY_TYPE.cupcake = {
    spawn = "I'm craving something sweet! {recipe}? 🧁",
    served = "So yummy! Thank you! 🍰",
    timeout = "My sweet tooth is losing patience... 🍬",
    wrong_dish = "This isn't sweet enough... 😕",
}
GUEST_BY_TYPE.zundamon = {
    spawn = "Zunda! I want {recipe}! 🍙",
    served = "Zunda-zunda! Delicious! 🎊",
    timeout = "Zunda... too slow... leaving now! 😤",
    wrong_dish = "Not zunda enough! 😠",
}

-- Add guest speaker to SPEAKERS table
SPEAKERS.guest = { name = "Guest", emoji = "🍽️", accent = RGB(220, 200, 170), portrait = RGB(230, 220, 200) }

return {
    SPEAKERS = SPEAKERS,
    COMPANION_DIALOGUE = COMPANION_DIALOGUE,
    SIDE_DIALOGUES = SIDE_DIALOGUES,
    GUEST_DIALOGUE = GUEST_DIALOGUE,
    GUEST_BY_TYPE = GUEST_BY_TYPE,
}
