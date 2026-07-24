--!strict
-- [[ModuleScript] VNDialogueData]]
-- Comprehensive registry for speakers and companion-specific branching dialogue.
-- Features time-of-day, chef level, and bond-level branching dialogue trees for all 9 companions.

local Players = game:GetService("Players")
local RGB = Color3.fromRGB

-- Speaker configurations with companion emojis
local SPEAKERS = {
	zundamon    = { name = "Zundamon", emoji = "🌱", accent = RGB(160, 210, 150), portrait = RGB(180, 220, 170) },
	zundapal    = { name = "Zundamon", emoji = "🌱", accent = RGB(160, 210, 150), portrait = RGB(180, 220, 170) }, -- Backward compat alias for zundamon
	zundacat    = { name = "Zundacat", emoji = "🐱", accent = RGB(245, 194, 145), portrait = RGB(255, 224, 190) },
	zundabunny  = { name = "Zundabunny", emoji = "🐰", accent = RGB(214, 187, 242), portrait = RGB(236, 218, 250) },
	tantanmon   = { name = "Tantanmon", emoji = "🌶️", accent = RGB(239, 137, 111), portrait = RGB(252, 194, 166) },
	ankomon     = { name = "Ankomon", emoji = "🥜", accent = RGB(220, 150, 150), portrait = RGB(240, 205, 205) },
	cardamon    = { name = "Cardamon", emoji = "🍋", accent = RGB(235, 205, 125), portrait = RGB(248, 230, 175) },
	antimon     = { name = "Antimon", emoji = "🌿", accent = RGB(145, 215, 195), portrait = RGB(195, 235, 220) },
	sakuradamon = { name = "Sakuradamon", emoji = "🌸", accent = RGB(255, 180, 200), portrait = RGB(255, 220, 230) },
	dog         = { name = "Dog Companion", emoji = "🐕", accent = RGB(230, 180, 130), portrait = RGB(245, 200, 160) },
	parrot      = { name = "Parrot Companion", emoji = "🦜", accent = RGB(255, 180, 100), portrait = RGB(255, 210, 150) },
	cat         = { name = "Cat Companion", emoji = "🐱", accent = RGB(255, 190, 210), portrait = RGB(255, 220, 235) },
	narrator    = { name = "", emoji = "✨", accent = RGB(220, 200, 170), portrait = RGB(230, 220, 200) },
	elder       = { name = "Village Elder", emoji = "🏮", accent = RGB(220, 180, 130), portrait = RGB(230, 200, 160) },
	ruins       = { name = "Ancient Voice", emoji = "👁", accent = RGB(190, 170, 210), portrait = RGB(210, 195, 220) },
	chef        = { name = "Head Chef", emoji = "🍳", accent = RGB(230, 185, 130), portrait = RGB(240, 210, 170) },
	system      = { name = "", emoji = "⭐", accent = RGB(210, 195, 235), portrait = RGB(225, 215, 240) },
}

-- Companion-specific branching dialogue (time + level + bond based)
local COMPANION_DIALOGUE = {
	zundamon = {
		morning = {
			"Good morning, {player}! The garden is sparkling with dew, and I can smell Zunda Peas blooming~ ☀️🌱",
			"Ready to cook up something wonderful today? Let us make one dish we are proud of!",
			"I'll be right here beside you as you explore and gather. What should we cook first?",
			"The morning breeze carries the sweet scent of crushed edamame! Perfect timing for Zunda Mochi! 🍡",
		},
		afternoon = {
			"You are finding your rhythm, {player}! I can see it in every move~ 🔥",
			"The guests look hungry — let's get cooking! I will stay close while you work your magic.",
			"You're doing great! Have you tried crafting the Edamame Parfait yet?",
			"A full kitchen makes my heart leap nanoda! Keep that cooking streak glowing! ✨",
		},
		evening = {
			"The kitchen feels warm after a long day of good work. The sunset is so pretty from here... 🌅",
			"What was your favorite little moment today, {player}? You worked so hard.",
			"I'll be right here beside you, always~ The stars are beginning to twinkle.",
			"Let's count our gold revenue and prepare fresh dough for tomorrow's sunrise rush! 💰",
		},
		night = {
			"Psst — {player}... still awake? 🌙 Quiet kitchens keep the sweetest memories.",
			"The stars are beautiful tonight... Even chefs deserve a rest. I'll keep watch~",
			"Rest when you are ready; tomorrow brings new recipes! I will guard the kitchen while you sleep. ⭐",
		},
		level1_10 = { "Welcome to Zunda Village! I believe in you, and I will guide your journey! 🌱" },
		level11_20 = { "You're getting the hang of this! Your rhythm cooking accuracy is getting sharper! ✨" },
		level21_50 = { "A true Master Chef! The whole village talks about your amazing food! 👑" },
		quest_branch = {
			"Did you know Zunda Mochi has been crafted since the Sengoku era nanoda? Ancient samurai used to crush fresh soybeans for energy! ⚔️🍡",
			"If you want maximum tips from hungry guests, land 5 Perfect hits in a row during rhythm minigames! 🎯",
		},
	},

	zundacat = {
		morning = {
			"Mrrp! I found the sunniest gathering path! 🐱☀️",
			"Race you to the next shiny ingredient node!",
			"Morning purrs mean good luck on cooking minigames~",
		},
		afternoon = {
			"I inspected every harvest basket. Very professional. 🧺",
			"There may be a sparkling Zunda Berry near the garden wall!",
			"Napping in the sun while you cook is my job~",
		},
		evening = {
			"Serving guests is better with a cat supervisor! 🍽️",
			"You cook; I will accept the compliments and headpats.",
			"The village lanterns look like tiny fireflies!",
		},
		night = {
			"The village is full of tiny night sounds... 🌙",
			"I will keep watch from the comfiest stool in the kitchen.",
			"Purrrr... sleep well, chef~ 💤",
		},
		level1_10 = { "A new chef! I will allow you to feed me Zunda Mochi. 🐾" },
		level11_20 = { "Your cooking speed is feline fast! ✨" },
		level21_50 = { "You are officially my favorite chef in all the realms! 👑" },
	},

	zundabunny = {
		morning = {
			"Hop, hop—good morning, {player}! 🐰☀️",
			"Let us gather something colorful in the meadow today!",
			"My ears twitch when rare ingredients drop nearby~ 🌾",
		},
		afternoon = {
			"You make hard work look gentle and dreamy~ 🌸",
			"A tiny tea break can be part of the adventure too!",
			"The breeze smells like sweet pea blossoms!",
		},
		evening = {
			"The sunset makes the whole village blush pink! 💖",
			"Can we visit the Hilltop Shrine before supper?",
			"Your cooking makes everyone smile so bright~ 💫",
		},
		night = {
			"The night sky looks like crushed star sprinkles! 🌌",
			"Rest your feet, chef... you hopped so far today.",
			"Sweet dreams, little chef~ ⭐",
		},
		level1_10 = { "Hoppy to meet you! Let's explore together! 🐰" },
		level11_20 = { "Your rhythm cooking feels like a happy dance! ✨" },
		level21_50 = { "You're the brightest star in Zunda Village! 🌟" },
	},

	tantanmon = {
		morning = {
			"Up and sizzling, chef {player}! 🌶️🔥",
			"Let us turn breakfast into a spicy little festival!",
			"Morning heat fuels maximum cooking streak speeds!",
		},
		afternoon = {
			"That cooking streak has some serious spice! 💥",
			"One more guest—let us make it spectacular!",
			"Speed + Precision = Unlimited Gold! 💰",
		},
		evening = {
			"A warm kitchen is the heart of the village! 🏮",
			"You brought the spark today, {player}!",
			"Sizzling pans make the best evening music!",
		},
		night = {
			"Even little flames need time to glow low. 🌙",
			"I will save the fireworks for tomorrow's rush!",
			"Rest up, firebrand chef! 🔥",
		},
		level1_10 = { "Bring the heat! Time to start cooking! 🌶️" },
		level11_20 = { "Your movement speed buff is blazing fast! ⚡" },
		level21_50 = { "Unstoppable spicy cooking power! 🔥👑" },
	},

	ankomon = {
		morning = {
			"Training begins at dawn, {player}. 🥜",
			"Every great chef needs discipline and focus. ⚖️",
			"Shall we practice precision timing today?",
		},
		afternoon = {
			"Your gold bonus from guest orders increases with focus! 💰",
			"Try perfect timing for maximum tip rewards!",
			"Sweet red bean paste requires exact recipe steps.",
		},
		evening = {
			"Reflect on today's service. Every mistake is a lesson. 📜",
			"Your growth as a chef honors Zunda Village.",
		},
		night = {
			"The kitchen rests. Rest your mind as well, {player}. 🌙",
			"Tomorrow brings greater culinary trials.",
		},
		level1_10 = { "Don't rush technique. Master the basics first. 🌱" },
		level11_20 = { "Excellent form! Your +15% gold bonus is active. 💰" },
		level21_50 = { "True discipline! A legendary chef walks among us. 👑" },
	},

	cardamon = {
		morning = {
			"Breathe in the fresh botanical aromas, {player}~ 🍋",
			"Patience reveals the deepest flavors in every dish. 🧘",
			"The morning sun warms our cooking herbs.",
		},
		afternoon = {
			"Your timing window is +30% wider with my blessing! ✨",
			"Smooth timing creates flawless S-Rank dishes.",
		},
		evening = {
			"The evening breeze carries hints of citrus and tea. 🍵",
			"You cooked with grace today, chef.",
		},
		night = {
			"The herbs whisper secrets in the moonlight... 🌙",
			"Rest well, young chef. Tomorrow brings new discoveries.",
		},
		level1_10 = { "Slower timing gives better results for beginners. 🌱" },
		level11_20 = { "Your timing window is wider now — use it wisely! ✨" },
		level21_50 = { "Perfect zen state achieved — flawless cooking ahead! 🧘👑" },
	},

	antimon = {
		morning = {
			"Time is ingredients, {player}! 🌿⚡",
			"Let's gather at lightning speed today!",
			"My minty breeze spots hidden resource nodes!",
		},
		afternoon = {
			"Faster harvest speed means more fresh produce! 🧺",
			"I can feel your gathering energy accelerating!",
			"Did you catch the +20% extra drop bonus?",
		},
		evening = {
			"We filled the inventory pouch to the brim today! 🎒",
			"Great gathering work, chef {player}!",
		},
		night = {
			"Even speedsters need sleep... 🌙",
			"I will scout the gathering paths for sunrise!",
		},
		level1_10 = { "Haste makes waste... but I'll help you go fast! ⚡" },
		level11_20 = { "Your extra gather drop buff is active! 🌿" },
		level21_50 = { "No time wasted — pure efficiency mastery! 👑" },
	},

	sakuradamon = {
		morning = {
			"The sakura blossoms bloom with the morning dew~ 🌸",
			"Seek rare ingredients for seasonal recipes!",
			"A gentle pink petals drift across the kitchen court...",
		},
		afternoon = {
			"Your XP bonus is active! Every dish grants extra experience! ✨",
			"Cooking with love turns meals into magic.",
		},
		evening = {
			"The dusk sky is painted in sakura pink and lavender. 💖",
			"Thank you for sharing this day with me, {player}.",
		},
		night = {
			"The moon blesses rare flowers in the dark... 🌙",
			"If you listen closely, the wind tells ancient tales.",
		},
		level1_10 = { "Blossoms take time to bloom. Be patient with yourself. 🌸" },
		level11_20 = { "Your +25% XP bonus fuels your culinary growth! ✨" },
		level21_50 = { "A legendary blossom chef! Pure perfection! 🌸👑" },
	},

	dog = {
		morning = { "Woof! Good morning {player}! Ready to explore? 🐕☀️", "Tail wagging at maximum speed!" },
		afternoon = { "Bark! I smelled fresh food from a mile away! 🍖", "I'll fetch any ingredient you drop!" },
		evening = { "Arf! Sitting by your side while you cook is the best. 🌇" },
		night = { "Yawn... sleeping at your feet tonight, chef! 🌙💤" },
	},

	parrot = {
		morning = { "Squawk! Good morning! Cook the mochi! 🦜✨", "Polly wants Zunda Peas! Squawk!" },
		afternoon = { "Squawk! Fast hands! Perfect timing! 🍳", "Look at all the hungry guests!" },
		evening = { "Squawk! Beautiful sunset! Good job chef! 🌅" },
		night = { "Squawk... quiet night... zzz... 🌙" },
	},

	cat = {
		morning = { "Meow~ Morning human. Is breakfast ready? 🐱", "Stretching in the morning sunlight..." },
		afternoon = { "Purrrr... you're doing great cooking today. 💖", "I am supervising your recipe steps." },
		evening = { "Meow! Time for evening treats and headpats! 🌇" },
		night = { "Purrrrr... curled up in your warm pouch... 🌙💤" },
	},
}

-- Side dialogue triggers (item/lore discoveries)
local SIDE_DIALOGUES = {
	zunda_pea = {
		speaker = "zundamon",
		text = "Oh! You found some Zunda Peas! 🌱",
		hint = "Those are my favorite~ They're so sweet and green!",
		recipe = "Did you know you can make Zunda Mochi with them? 🍡",
	},
	zunda_mochi = {
		speaker = "zundamon",
		text = "Zunda Mochi! The pride of Zunda Village! 🍡",
		hint = "Serve it to guests while it's fresh for extra gold!",
	},
}

local VNDialogueData = {}

-- Exposed directly for consumers (e.g. VNController) that read the tables
-- rather than going through the getter functions below.
VNDialogueData.SPEAKERS = SPEAKERS
VNDialogueData.COMPANION_DIALOGUE = COMPANION_DIALOGUE
VNDialogueData.SIDE_DIALOGUES = SIDE_DIALOGUES

function VNDialogueData.getSpeaker(id: string)
	return SPEAKERS[id] or SPEAKERS.zundamon
end

function VNDialogueData.getCompanionDialogue(compType: string, timeOfDay: string?, level: number?)
	local compPool = COMPANION_DIALOGUE[compType] or COMPANION_DIALOGUE.zundamon
	local tod = timeOfDay or "morning"

	-- Level overrides
	if level then
		if level >= 21 and compPool.level21_50 then
			return compPool.level21_50[math.random(1, #compPool.level21_50)]
		elseif level >= 11 and compPool.level11_20 then
			return compPool.level11_20[math.random(1, #compPool.level11_20)]
		elseif level <= 10 and compPool.level1_10 then
			return compPool.level1_10[math.random(1, #compPool.level1_10)]
		end
	end

	local pool = compPool[tod] or compPool.morning or { "Hello chef! Let's cook together! 🌱" }
	return pool[math.random(1, #pool)]
end

function VNDialogueData.getSideDialogue(key: string)
	return SIDE_DIALOGUES[key]
end

return VNDialogueData
