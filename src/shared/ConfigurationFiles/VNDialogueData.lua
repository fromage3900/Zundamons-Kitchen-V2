--!strict
-- [[ModuleScript] VNDialogueData]]
-- Comprehensive registry for speakers and companion-specific branching dialogue.
-- Features time-of-day, chef level, and bond-level branching dialogue trees for all 9 companions.

local Players = game:GetService("Players")
local RGB = Color3.fromRGB

-- Speaker configurations with companion emojis
local SPEAKERS = {
	zundamon = { name = "Zundamon", emoji = "🌱", accent = RGB(160, 210, 150), portrait = RGB(180, 220, 170) },
	zundapal = { name = "Zundamon", emoji = "🌱", accent = RGB(160, 210, 150), portrait = RGB(180, 220, 170) }, -- Backward compat alias for zundamon
	zundacat = { name = "Zundacat", emoji = "🐱", accent = RGB(245, 194, 145), portrait = RGB(255, 224, 190) },
	zundabunny = { name = "Zundabunny", emoji = "🐰", accent = RGB(214, 187, 242), portrait = RGB(236, 218, 250) },
	tantanmon = { name = "Tantanmon", emoji = "🌶️", accent = RGB(239, 137, 111), portrait = RGB(252, 194, 166) },
	ankomon = { name = "Ankomon", emoji = "🥜", accent = RGB(220, 150, 150), portrait = RGB(240, 205, 205) },
	cardamon = { name = "Cardamon", emoji = "🍋", accent = RGB(235, 205, 125), portrait = RGB(248, 230, 175) },
	antimon = { name = "Antimon", emoji = "🌿", accent = RGB(145, 215, 195), portrait = RGB(195, 235, 220) },
	sakuradamon = { name = "Sakuradamon", emoji = "🌸", accent = RGB(255, 180, 200), portrait = RGB(255, 220, 230) },
	dog = { name = "Dog Companion", emoji = "🐕", accent = RGB(230, 180, 130), portrait = RGB(245, 200, 160) },
	parrot = { name = "Parrot Companion", emoji = "🦜", accent = RGB(255, 180, 100), portrait = RGB(255, 210, 150) },
	cat = { name = "Cat Companion", emoji = "🐱", accent = RGB(255, 190, 210), portrait = RGB(255, 220, 235) },
	sumimon = { name = "Sumimon", emoji = "🖌️", accent = RGB(100, 110, 130), portrait = RGB(200, 205, 215) },
	kagamon = { name = "Kagamon", emoji = "🪞", accent = RGB(160, 210, 255), portrait = RGB(220, 240, 255) },
	suzurimon = { name = "Suzurimon", emoji = "🔔", accent = RGB(210, 175, 90), portrait = RGB(245, 230, 180) },
	wasabimon = { name = "Wasabimon", emoji = "🌿", accent = RGB(90, 180, 80), portrait = RGB(190, 240, 185) },
	yurimon = { name = "Yurimon", emoji = "🪷", accent = RGB(215, 140, 180), portrait = RGB(250, 220, 235) },
	kinakomon = { name = "Kinakomon", emoji = "🌾", accent = RGB(205, 150, 60), portrait = RGB(245, 225, 175) },
	kuroyurimon = { name = "Kuroyurimon", emoji = "🥀", accent = RGB(130, 80, 170), portrait = RGB(210, 185, 235) },
	matchamon = { name = "Matchamon", emoji = "🍵", accent = RGB(80, 140, 60), portrait = RGB(190, 225, 175) },
	shisomon = { name = "Shisomon", emoji = "🍃", accent = RGB(150, 70, 160), portrait = RGB(225, 185, 230) },
	karintomon = { name = "Karintomon", emoji = "🏮", accent = RGB(220, 100, 30), portrait = RGB(255, 205, 165) },
	tsukimidamon = { name = "Tsukimidamon", emoji = "🌕", accent = RGB(140, 160, 230), portrait = RGB(215, 225, 250) },
	hoshidamon = { name = "Hoshidamon", emoji = "☀️", accent = RGB(215, 120, 50), portrait = RGB(250, 210, 175) },
	-- Canon-linked companions
	kiritandamon = { name = "Kiritandamon", emoji = "📐", accent = RGB(80, 185, 220), portrait = RGB(190, 235, 250) },
	itakodamon = { name = "Itakodamon", emoji = "🔮", accent = RGB(140, 100, 190), portrait = RGB(210, 190, 240) },
	zunkodamon = { name = "Zunkodamon", emoji = "⚔️", accent = RGB(210, 145, 65), portrait = RGB(245, 215, 170) },
	zunabunny = { name = "Zunabunny", emoji = "🐰", accent = RGB(175, 235, 165), portrait = RGB(215, 250, 205) },
	nanonadamon = { name = "Nanonadamon", emoji = "🏹", accent = RGB(120, 205, 145), portrait = RGB(195, 245, 210) },
	narrator = { name = "", emoji = "✨", accent = RGB(220, 200, 170), portrait = RGB(230, 220, 200) },
	elder = { name = "Village Elder", emoji = "🏮", accent = RGB(220, 180, 130), portrait = RGB(230, 200, 160) },
	ruins = { name = "Ancient Voice", emoji = "👁", accent = RGB(190, 170, 210), portrait = RGB(210, 195, 220) },
	chef = { name = "Head Chef", emoji = "🍳", accent = RGB(230, 185, 130), portrait = RGB(240, 210, 170) },
	system = { name = "", emoji = "⭐", accent = RGB(210, 195, 235), portrait = RGB(225, 215, 240) },
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

	sumimon = {
		morning = {
			"The morning mist rises like wet sumi ink across rice paper, {player}... Let us paint today's flavors with care. 🖌️",
			"Every fresh sunrise is a blank scroll. What poetry shall our spatulas compose before noon?",
			"The quiet dawn suits my soul. Brush bristles and simmering broth both require a steady, gentle hand.",
			"Steam from the kettle dissolves into the gray light... Beautiful, yet so brief. 📜",
		},
		afternoon = {
			"The kitchen rushes swirl like turbulent brush strokes! Keep your posture poised and your strokes decisive! ✨",
			"Observe how the black soba broth darkens in the bowl... A masterpiece of contrast and depth.",
			"Your style points flourish when cooking flows like unbroken cursive calligraphy! +30% elegance is in your grasp!",
			"Guests eat with their eyes first, {player}. Let each plate be worthy of an imperial hanging scroll.",
		},
		evening = {
			"Dusk paints the village in charcoal and burnt amber... 🌅 The finest hour for reflective cooking.",
			"Another page of our culinary chronicle comes to a close. You worked with sublime dedication today.",
			"The ink on today's orders has dried, leaving only the warmth of satisfied smiles behind.",
		},
		night = {
			"Silence settles over the kitchen like soot settling in an ancient inkwell... 🌙",
			"I shall watch over the sleeping pantry, inscribing recipes of remembrance while you rest. ⭐",
			"Do not fear the dark, {player}... In the deepest shadows, the brightest white porcelain shines.",
		},
		bond1 = {
			"I observe your movements, {player}. Your technique is raw, but there is genuine poetry behind your knife work. 🖌️",
			"A chef who respects the transient nature of taste is a kindred spirit to an ink ghost.",
		},
		bond2 = {
			"When we cook together, the rhythm feels like a duet between brush and stone. I find myself smiling more often. 📜✨",
			"I once believed all creations were doomed to be forgotten... but your kitchen gives memory a home.",
		},
		bond3 = {
			"For centuries, I wept over the poet whose scroll was left half-painted when he died... I thought I was only a ghost of grief. But standing beside you, {player}... you finished the poem. My heart is whole. 🖤✨",
			"Let empires fall and scrolls turn to dust—so long as I may linger by your hearth, my ink shall never fade.",
		},
		quest_branch = {
			"In the high pagoda ruins, an ancient inkstone remains sealed in stone. If you brew soba with mountain mushrooms, the old seals may soften. 📜",
			"True style cannot be bought with gold; it must be coaxed from harmony and disciplined technique.",
		},
	},

	kagamon = {
		morning = {
			"YAY! Good morning super-chef {player}! Look into my glass—you look 1000% radiant today! 🪞✨",
			"Rise and shine! The world is our stage, and breakfast is the opening act! Keep smiling forever!",
			"A little polish on the frame, and voila! No blemishes! No cracks at all! Everything is totally fine! 💖",
			"Are you ready to dazzle the whole village? Sparkle power at maximum output! 🪞🌟",
		},
		afternoon = {
			"Guest lines around the block?! PERFECT! My dazzling reflection will keep them mesmerized! 🪞💫",
			"Patience, dear guests! The superstar chef is preparing perfection! (+40% wait tolerance active! ✨)",
			"Look at that glossy mochi glaze! It mirrors the sky so brightly you can almost ignore the heat! 🔥",
			"Keep dancing between the stations! The spotlight loves a busy chef!",
		},
		evening = {
			"Sunset encore time! The orange sky looks so dreamy reflected in my surface! 🌇✨",
			"We gave a five-star performance today! My smile muscles are totally not exhausted at all, ehehe~ 🪞",
			"Let's wipe down the counters until they shine just like me! Squeaky clean perfection!",
		},
		night = {
			"The stage lights are down... The kitchen is dark... 🌙 The glass feels cold when no one is watching.",
			"Don't look too closely at the corners of my frame, okay? Just... remember the sparkling idol version! ✨",
			"Goodnight, {player}... Thank you for letting me shine where no fires can burn me... 💤",
		},
		bond1 = {
			"Ta-da! You have the honor of being mirrored by Kagamon! Aren't I the sweetest, most unbroken spirit ever? 🪞💖",
			"I'll keep the guests happy and patient so you never have to see anyone scowl! Scowls are scary...",
		},
		bond2 = {
			"You know... even when I drop my idol pose for a second, you don't look away in disgust. That's... really nice of you, {player}. 🪞🌸",
			"Sometimes my glass aches where the old fire touched it... but when you cook, the warmth feels different. Gentle.",
		},
		bond3 = {
			"The truth is... I didn't get these sparkles from a fairy godmother. My temple burned to ashes four hundred years ago, and I shattered on the stone floor... I pretended to be a perfect idol so no one would throw my shards away. But you... you saw every fracture and called me beautiful. I love you, {player}. 🪞💔💖",
			"I don't need to hide behind a mirror illusion anymore. Broken or whole, I will be your light forever!",
		},
		quest_branch = {
			"Have you seen the scorched shrine pedestal in the ruins? If we bring a perfectly glazed mirror mochi there... maybe old ghosts can rest. 🪞🔥",
			"Guest patience isn't just a spell—it's the power of making people feel seen and cherished.",
		},
	},

	suzurimon = {
		morning = {
			"*RIIIING*... The dawn chime purifies the morning air. Rise with honor, {player}. 🔔",
			"A clear mind produces an unblemished recipe. Let us sound the bell of culinary devotion.",
			"The mountain breeze strikes the bronze bell softly. A new day of discipline has commenced. ☀️",
			"Inspect your tools; align your cutting board. The rhythm begins with the first step.",
		},
		afternoon = {
			"*CHIME-CHIME!* Maintain the tempo! Do not allow the rush to break your focus! 🔔⚡",
			"Your combo meter holds steady under my toll! +50% combo retention shields your rush!",
			"Speed without precision is merely noise; cook with deliberate harmony!",
			"The bronze chime echoes across the dining hall. The guests feel the solemn dignity of our craft.",
		},
		evening = {
			"The dusk bell tolls across Zunda Village... 🌅 Service draws to a honorable close.",
			"You held the line against the wave of orders, {player}. Your resolve is tempered like forged metal.",
			"Cleanse the pans in warm water. Let the evening chime wash away the fatigue of the day. 🔔",
		},
		night = {
			"*Chime*... The night watch begins. 🌙 Ancient waters sleep deep beneath the earth.",
			"Rest your weary arms, chef. I shall stand vigilant; no ill wind shall disturb our pantry.",
			"When the temple sank beneath the lake centuries ago, I rang into the empty dark... Now, I ring for you. 🔔⭐",
		},
		bond1 = {
			"I am Suzurimon. I guard the sanctuary of flavor. Prove to me that your heart does not waver in the heat. 🔔",
			"Rhythm is life in the kitchen. Misjudge a beat, and the dish is lost.",
		},
		bond2 = {
			"Your rhythm has grown steady, {player}. Like a bell cast by a master smith, your spirit does not crack under pressure. 🔔✨",
			"I find comfort in your footsteps beside the stove. It has been centuries since I shared a hearth.",
		},
		bond3 = {
			"When the mountain floods swallowed my shrine, my priest drowned reaching for my cord... I rang until the waters choked my throat, powerless to save him. For centuries, my bronze was drowned in cold silence. But your hands rang me back to life. I swear upon my sacred bell: I will protect your hearth until the end of time. 🔔🌊✨",
			"No flood, no fire, no chaos shall ever extinguish the flame we kindle together.",
		},
		quest_branch = {
			"Deep in the misty valley, submerged shrine timbers still hum in resonance. Bring golden dango to appease the water spirits. 🔔🍡",
			"When rush orders multiply, breathe to the cadence of the bell. Time itself bends to an unyielding rhythm.",
		},
	},

	wasabimon = {
		morning = {
			"OSS! Dawn has broken! Wake up, {player}! The mountain stream waits for no sluggards! 🌿🔥",
			"Cold water on your face, sharp steel on the whetstone! That is how a true warrior of the kitchen greets the day!",
			"Breathe in the stinging mountain air! Clear your sinuses, clear your soul!",
			"Today we hunt for the purest roots in the valley! Move your feet! 🏔️",
		},
		afternoon = {
			"Grate that root with circular force! Don't let your wrist slacken! Precision is power! 🌿💥",
			"Look at that rare node gleaming in the thicket! My sharp senses boost rare drops by +35%!",
			"A dish without kick is just baby food! Put your entire spirit into that seasoning!",
			"Speed! Balance! Heat control! You are moving like a true mountain ascetic today!",
		},
		evening = {
			"The sun descends behind the peaks... 🌄 Good sweat, good steel, good discipline.",
			"Inspect your blade edges before twilight. A blunt knife is an insult to the ingredients.",
			"You withstood the midday storm of orders like an oak in a gale, {player}. Respectable work.",
		},
		night = {
			"The mountain winds howl at night... 🌙 Sit in zazen and meditate upon your slicing technique.",
			"Rest your muscles; tomorrow we climb higher. I will maintain the guard perimeter.",
			"Even wild monks sleep, chef. But keep your senses sharp even in slumber! OSS! 💤",
		},
		bond1 = {
			"I don't babysit soft chefs. If you want my mountain blessing, you will cut with absolute conviction! 🌿",
			"Wasabi reveals all lies. A weak cook hides behind sugar; a true chef faces the fire.",
		},
		bond2 = {
			"Hmph. Your grip is firmer now, {player}. You didn't flinch when the grease popped. You might have monk blood after all. 🌿✨",
			"Take this root. I only share high-altitude harvests with chefs who earn my respect.",
		},
		bond3 = {
			"I lived alone in the snow peaks for eighty years, believing compassion made a blade dull... But watching you pour love into every bowl for hungry villagers proved me a fool. True sharpness is born from devotion, not isolation. You are my master and my sworn kin. OSS! 🌿🏔️🔥",
			"My blade, my roots, and my ferocious spirit belong to your kitchen forever.",
		},
		quest_branch = {
			"The highest alpine ridges hide wild zunda roots frozen in ancient frost. Scale the peaks and prove your endurance! 🏔️🌿",
			"When gathering, watch the sparkle of the soil. Rare earth gives birth to legendary ingredients.",
		},
	},

	yurimon = {
		morning = {
			"Ah, what an exquisite morning in the valley, {player}~ The dew sits upon the lily petals like pearls. 🪷👑",
			"Shall we elevate today's dining experience to imperial court standards? Only the sublime will suffice!",
			"A graceful posture at dawn ensures royal composure during the midday rush. Breathe in elegance~",
			"The fragrance of sweet pea blossoms rivals the royal gardens of Kyoto. Let us begin! 🌷",
		},
		afternoon = {
			"Observe the patrons swooning over your plating! +50% generous tips are pouring into our royal coffers! 💰✨",
			"Wipe the rim of that porcelain dish, darling! Presentation is the soul of nobility!",
			"Ohoho~ Look at that golden sheen on the lily glaze! Truly fit for an empress!",
			"A bustling salon of high gastronomy! Your culinary court expands by the hour!",
		},
		evening = {
			"Twilight drapes the village in imperial purple and gold... 🌅 How thoroughly romantic.",
			"The ledger reflects our royal triumph today, {player}. Wealth flows naturally to true elegance.",
			"A glass of chilled floral nectar to toast our splendid service! You conducted the kitchen with majestic grace. 🪷",
		},
		night = {
			"The stars shimmer like diamonds sewn across the velvet night... 🌙 Magnificent.",
			"Sleep peacefully, my dear sovereign of the stove. Your royal courtier keeps watch over your domain. ⭐",
			"In the quiet palace of the night, we dream of tomorrow's grand banquets... 💤",
		},
		bond1 = {
			"I am Yurimon. I have dined with emperors and shoguns. Let us see if your village culinary flair can satisfy high aesthetic taste. 🪷",
			"Never serve a dish without considering the curvature of the garnish. Elegance is in the details.",
		},
		bond2 = {
			"I must confess, {player}... the court banquets I once managed were cold and filled with poisoned whispers. Here, your food radiates genuine warmth. 🪷💖",
			"You plate not to impress politicians, but to bring joy to simple folk. That is true nobility.",
		},
		bond3 = {
			"I fled the imperial palace in tears after spending a lifetime creating masterpieces for courtiers who smiled with daggers behind their backs. I thought elegance was an empty golden cage. But your honest hearth showed me that true majesty lives in shared laughter over a bowl of soup. My court is right here, by your side. 🪷👑✨",
			"No throne in the land could tempt me away from being your devoted companion.",
		},
		quest_branch = {
			"The old court manuscripts speak of the Imperial Lily Glaze—a harmony of edible bulbs and gold dust. Revive the royal recipe! 📜🪷",
			"Generous tips follow generous hearts. When a dish is crafted with pride, patrons gladly shower the counter with gold.",
		},
	},

	kinakomon = {
		morning = {
			"Good morning, my sweet dumpling! Have you had breakfast yet? You look like you need a warm bun! 🌾☀️",
			"The stone mill is already spinning! Smell that freshly roasted soybean powder? Pure golden happiness!",
			"Bundle up warmly, {player}! A good chef takes care of their health first and foremost!",
			"Come, come! Let's bake something golden that will put meat on the village children's bones! 🥖",
		},
		afternoon = {
			"Look at you go! Slicing, baking, kneading—you're growing into such a splendid master chef! 🌾✨",
			"Feel that +40% XP growth kicking in? Every knead of the dough makes your spirit stronger!",
			"Don't forget to taste your sauces, dear! A generous pinch of kinako makes everything richer!",
			"Bless those hungry guests! Put an extra sweet dango on every plate—nobody goes hungry on my watch!",
		},
		evening = {
			"The sun is tucking behind the hills... 🌇 Time to sit down, put your feet up, and have a fresh cup of tea.",
			"You worked so hard today, {player}. I am bursting with grandmotherly pride!",
			"Let's save the leftover dough for morning rolls. Waste nothing, cherish everything. 🌾",
		},
		night = {
			"Off to bed with you, little chef! 🌙 Sleep deep and let your muscles recover.",
			"I'll cover the flour barrels and keep the oven pilot burning low and warm. Sleep tight, dear. ⭐",
			"Sweet dreams of golden wheat fields and warm honey buns... 💤",
		},
		bond1 = {
			"Hello there, dearie! Kinakomon is here to look after you. Don't you dare skip your meals while working! 🌾",
			"A kitchen without love is just a cold pile of bricks. Put your heart into the dough!",
		},
		bond2 = {
			"You remind me so much of the little apprentices I used to bake for generations ago... so eager, so kind. 🌾💖",
			"Watching your skills bloom every single day brings tears of joy to an old mill spirit's eyes.",
		},
		bond3 = {
			"Over the centuries, so many village children grew up and moved away across the mountains... and my old stone mill grew quiet and lonely. I thought my baking days were over. But you welcomed me into your kitchen with open arms and called my roasted flour magic. You are the grandchild of my soul, {player}. 🌾👵💖",
			"I will bake beside you, feed your dreams, and shower your path in golden warmth forever.",
		},
		quest_branch = {
			"The ancient windmill on the eastern ridge needs fresh wheat sheaves. Harvest the golden grain and grind the legendary flour! 🌾🍞",
			"Skill growth comes from patient repetition. Love the daily routine, and mastery will follow naturally.",
		},
	},

	kuroyurimon = {
		morning = {
			"MWUHAHA! The black dawn awakens the Queen of Abyssal Shadows! ...U-um, good morning, {player}! 🥀☀️",
			"BEHOLD THE VEIL OF DARKNESS! ...Ahem, I mean, the curtains are open. Shall we make tea?",
			"The gloomy shadows of night retreat before your radiant stove... How wonderfully vexing! 📖",
			"My dark grimoire foretells a day of catastrophic deliciousness! Tremble before our menu!",
		},
		afternoon = {
			"FEAR NOT THE BURNING FLAMES OF THE NETHERWORLD! My ward saves one overcooked dish from ruin! 🥀🔥",
			"A burnt crust would merely summon ancient demons... so I have enveloped your pan in protective shadow!",
			"LOOK UPON MY VELVET TART AND WEEP TEARS OF MORTAL DESPAIR! ...I-is the frosting too sweet? Please tell me!",
			"The rush of mortals demands sustenance! Unleash the forbidden flavors of darkness!",
		},
		evening = {
			"The twilight hour approaches... The barrier between mortal flavor and forbidden spice grows thin! 🌇🥀",
			"We have survived another harrowing cycle of gastronomic combat. S-sit with me and read, okay?",
			"The purple dusk matches the petals of the abyssal black lily. A most romantic omen... I mean, OMINOUS OMEN!",
		},
		night = {
			"THE MIDNIGHT REALM BELONGS TO KUROYURIMON! 🌙 ...Can we leave the little nightlight on, though? Just in case.",
			"Under the starry abyss, I study forbidden romance scrolls... I mean, ANCIENT CURSES OF DOOM! 📖⭐",
			"Sleep, mortal companion... The shadows of the dark lily will shield your dreams from harm... 💤",
		},
		bond1 = {
			"Mortal chef! You dare forge a blood pact with the Sovereign of Cursed Lilies?! ...P-please sign here, and please don't yell at me! 🥀",
			"My dark magic is terrifying and absolute! ...Unless you offer me a slice of sweet pea cake, then I am pacified.",
		},
		bond2 = {
			"You... you didn't laugh when I dropped my grimoire and my shojo manga fell out. You're actually really nice, {player}... 🥀📖",
			"Whenever I mess up a spooky spell, you just smile and hand me a wooden spoon. That's way more powerful than dark magic.",
		},
		bond3 = {
			"I made up all the 'Queen of Abyssal Darkness' stuff because I was painfully shy and had no friends for four hundred years in that empty manor library... I thought if I acted scary, no one would realize how lonely and scared of the dark I was. But you saw right through my ridiculous monologues, sat beside me, and read recipes together. You're my favorite person in the whole wide universe, {player}! 🥀💖😭",
			"Dark phantom or awkward bookworm—I will stand by your side and protect your kitchen for all eternity!",
		},
		quest_branch = {
			"In the shadowed ruins behind the manor, a lost grimoire chapter lies buried. Brew an Eclipse Velvet Tart to break the ward! 🥀🥧",
			"Do not fear overcooking; the dark shadows cushion your mistakes so you can cook with bold bravery.",
		},
	},

	matchamon = {
		morning = {
			"The morning kettle sighs with quiet breath. Greetings, {player}. Let us cultivate serenity. 🍵🌿",
			"Every morning water boils is an opportunity to practice *Ichigo Ichie*—a once-in-a-lifetime encounter.",
			"Wipe the wooden table in a single smooth stroke. In cleanliness, the spirit finds stillness.",
			"The emerald powder awaits the bamboo whisk. A tranquil mind yields boundless flavor. ☀️",
		},
		afternoon = {
			"Flow like mountain water between the cooking stations. Let your chain of rhythm compound into gold! 🍵⚡",
			"A continuous chain of rhythm! Feel the +10% compounding surge with each successive beat!",
			"Do not fight the kitchen rush; bend with it like bamboo in the wind.",
			"The guests taste the harmony in every bowl. True satisfaction is silent appreciation.",
		},
		evening = {
			"The afternoon warmth dissolves into cool dusk... 🌅 The embers in the hearth glow like autumn leaves.",
			"Reflect upon the dishes served today without pride and without regret. All was in balance.",
			"Whisk a bowl of evening froth. Let us share a silent cup in honor of honest labor. 🍵",
		},
		night = {
			"The moon reflects in the dark tea bowl... 🌙 Ripples cease; stillness remains.",
			"Rest your hands, master chef. The path of Chado embraces rest as deeply as motion. ⭐",
			"Night covers the valley like a dark velvet cloth over a ceremonial tea set... 💤",
		},
		bond1 = {
			"I am Matchamon. The way of tea is the way of living. If you seek rush without mindfulness, we shall diverge. 🍵",
			"Observe the steam before you pour. The kettle speaks to those who listen.",
		},
		bond2 = {
			"Your movements at the stove have attained a rare, quiet elegance, {player}. The chaos around you no longer disturbs your center. 🍵✨",
			"To find peace in the midst of a dining rush is the mark of a true culinary sage.",
		},
		bond3 = {
			"I spent three hundred years searching for the perfect bowl of tea across distant monasteries, only to realize that perfection is meaningless when drunk alone in cold silence. Sharing a simple meal with you in this humble village kitchen is the truest enlightenment I have ever known. My path ends where yours begins. 🍵🌸✨",
			"In every grain of flour and every droplet of tea, my spirit shall remain in lifelong harmony with yours.",
		},
		quest_branch = {
			"The ancient tea pavilion at the highest terrace has a dry stone basin. Bring ceremonial froth to awaken the ancient spring! 🍵🪷",
			"Chaining perfect beats is not about speed; it is about entering the unbroken stream of present focus.",
		},
	},

	shisomon = {
		morning = {
			"SNIIIIFF! Ah! The pungent terpenes of wild morning shiso! Good morning, {player}! 🍃🔬",
			"The morning dew accelerates fermentation enzyme activity by 14.2%! We must begin harvesting immediately!",
			"Look at this purple-veined leaf! The aromatic compounds are practically vibrating with potential!",
			"Put on your foraging gloves! The forest undergrowth has secret treasures waiting for us! 🌲",
		},
		afternoon = {
			"FASCINATING! Look at the gather highlight spectrum! +60% vision range reveals nodes across the whole hill! 🍃✨",
			"Mix the red perilla brine with crushed zunda root! The antioxidant synergy is off the charts!",
			"Guest digestion speed increased by 30% thanks to our herbal pickling wraps! Science triumphs again!",
			"Quick! Label that fermentation crock before the wild yeast colonies take over the countertop!",
		},
		evening = {
			"The ultraviolet rays fade into twilight... 🌅 Ideal temperature for cellar fermentation!",
			"Look at our ingredient sacks! Packed to the brim with rare botanicals and medicinal herbs! 🌿",
			"We shall pickle today's bounty in cedar tubs. Time and microbes will do the rest of the cooking!",
		},
		night = {
			"The night is when nocturnal fungi release their secret spores! 🌙 I shall take field notes while you sleep!",
			"Don't mind the bubbling sounds from my pickle jars; that is merely the happy song of lactic acid bacteria! 🧪",
			"Rest your cerebral cortex, chef! Tomorrow we synthesize even bolder botanical recipes! 💤",
		},
		bond1 = {
			"Greetings, test subject—I mean, esteemed chef {player}! Shisomon is ready to revolutionize your herbology! 🍃",
			"Never dismiss a bitter weed; with proper curing, bitterness becomes the foundation of deep umami.",
		},
		bond2 = {
			"Remarkable! You actually understood my explanation about osmotic pressure in pickled perilla! 🍃💡",
			"Other villagers thought I was a mad hermit, but you taste every experimental brine with genuine curiosity!",
		},
		bond3 = {
			"I lived alone in the deep woods for decades because people laughed at my bubbling jars and strange tinctures... I thought science and flavor were doomed to be misunderstood. But you didn't just understand my recipes—you celebrated them and fed an entire village with my wild herbs. You are the ultimate partner in flavor alchemy! 🍃🧪💖",
			"My laboratory, my secret brine recipes, and my devoted loyalty are yours forever!",
		},
		quest_branch = {
			"Rare medicinal perilla herbs grow near the weeping willow by the waterfall. Forage the leaves to concoct the ultimate Pickled Wrap! 🍃💧",
			"When searching for gather nodes, look for the luminous herbal aura expanding across your vision.",
		},
	},

	karintomon = {
		morning = {
			"YO-HO! UP AND AT 'EM, CHEF {player}! THE FESTIVAL GATES ARE SWINGING WIDE OPEN! 🏮🔥",
			"Smell that boiling brown sugar molasses?! That's the smell of BIG PRIZES and BIG FLAVORS!",
			"Get the oil bubbling and the sugar spinning! Today is going to be an ABSOLUTE CARNIVAL!",
			"LOUDER! If the guests can't hear our enthusiasm from three towns over, we're not cooking hard enough! 🥁",
		},
		afternoon = {
			"JACKPOT! THAT DISH SURGED TO LEGENDARY QUALITY! +25% SURGE PROBABILITY NEVER LIES! 🏮✨",
			"STEP RIGHT UP, HUNGRY CROWDS! TASTE THE CRUNCH THAT SHOOK THE CAPITAL!",
			"Crisp on the outside, fluffy on the inside, coated in pure festival joy! Keep rolling those orders!",
			"The kitchen is hotter than a fireworks finale! WE ARE UNSTOPPABLE TODAY, {player}!",
		},
		evening = {
			"FESTIVAL LANTERNS ARE GLOWING! 🏮 The night market rush is the MAIN EVENT of the day!",
			"Count the gold coins, ring the gong! We broke every revenue record in the valley!",
			"Grab a skewer of molasses crunch and let's watch the village lanterns float down the river! 🎇",
		},
		night = {
			"Phew! Even carnival champions need to recharge the hype batteries! 🌙",
			"I'll keep the festival banners flying over the kitchen roof. Rest up for tomorrow's jackpot!",
			"Dream of giant candy wheels and golden fireworks, partner! Zzz... WASSHOI! ...Zzz... 💤",
		},
		bond1 = {
			"HEY HEY! Karintomon has arrived to turn your boring kitchen into the GREATEST SHOW ON EARTH! 🏮",
			"If you ain't cooking with full volume and crispy swagger, you ain't cooking at all!",
		},
		bond2 = {
			"You know what, partner? You've got real festival grit in your soul. You don't panic when the crowd surges! 🏮💥",
			"We make a killer team at the fryer. You bring the steady craft, I bring the explosive hype!",
		},
		bond3 = {
			"I was born at a temporary festival night market... and every year when the festival ended, everyone packed up their stalls and left me all alone on the empty dirt lot. I thought I'd always just be a temporary party guest who gets forgotten when the lanterns go out. But you built a permanent home for us here, and every single day with you feels like the grand festival finale. You're my family, partner! 🏮🎆😭💖",
			"I'll shout your name and hype your cooking from the top of the world forever and ever!",
		},
		quest_branch = {
			"The village festival grounds need a signature snack! Fry up a batch of Crisp Molasses Crunch and win the carnival banner! 🏮🍯",
			"Every dish you cook has a chance to surge into Legendary status; cook with bold excitement and watch the sparks fly!",
		},
	},

	tsukimidamon = {
		morning = {
			"Yawn... The bright sun peeks through the shoji screen... Good morning, {player}... 🌕☀️",
			"While the sun rules the day, the silver moon rests in the pale sky, watching over our breakfast preparations.",
			"I move a little slowly in the morning light, but my heart is always beside your stove...",
			"Let us prepare gentle, soft dough while the village rubs sleep from its eyes. 🌾",
		},
		afternoon = {
			"The midday sun passes its zenith... Soon the silver twilight will welcome our peak power! 🌕✨",
			"Roll the rice dumplings as round as the harvest moon; symmetry brings peace to hungry souls.",
			"Do you see the moon's faint silhouette rising over the mountains? The evening surge approaches!",
			"Keep steady, {player}. When the stars emerge, our true culinary magic awakens.",
		},
		evening = {
			"THE MOON RISES! 🌕✨ Feel that +35% night surge course through our kitchen! Earnings, speed, and XP unlocked!",
			"Under the silver moonlight, every dish glows with celestial grace. Service has reached its peak!",
			"Look upon the night guests bathed in lantern light! How poetic, how enchanting!",
			"The night shift is our kingdom, chef. Let us feed the night wanderers with starlit flavors!",
		},
		night = {
			"The midnight hour... 🌙 The village sleeps, but the kitchen remains a beacon of silver warmth.",
			"The stars whisper ancient haiku into the cooling pans... I could gaze upon this forever with you.",
			"Rest under the blanket of moonlight, {player}... I shall sing gentle lullabies to the sleeping dough. ⭐💤",
		},
		bond1 = {
			"Greetings, traveler of the stove. I am Tsukimidamon. When the sun sets, look to me for guidance. 🌕",
			"The moon does not rush its phases; cook with patience and nocturnal grace.",
		},
		bond2 = {
			"In the quiet hours of the night, when everyone else is asleep, cooking beside you feels like a sacred dream. 🌕🌸",
			"You appreciate the gentle silence of late-night kitchens just as I do. We share the same lunar soul.",
		},
		bond3 = {
			"For hundreds of autumns, I sat alone on cloud-tops watching distant kitchen windows glow, wishing I had someone to share the moon-viewing dumplings with. I was always the solitary spectator of everyone else's warmth. But you invited me down to your hearth and saved the brightest seat under the moon for me. I will never look upon the night alone again. 🌕🍡✨💖",
			"Wherever the silver moonlight falls, my devotion shall forever illuminate your path.",
		},
		quest_branch = {
			"When the full moon reaches the midpoint of the night sky, present a plate of Lunar Dumplings at the moon-viewing deck. 🌕📜",
			"During evening and night hours, your efficiency and rewards multiply under the silver blessing.",
		},
	},

	hoshidamon = {
		morning = {
			"Ho, ho... Good morning to ye, young chef {player}. The sun climbs slow, and so shall we. ☀️🌾",
			"Feel the dry autumn breeze? Good air for hanging persimmons and curing winter provisions.",
			"No need to sprint into the morning; a steady gait carries one across a thousand leagues.",
			"Let the wood stove heat gently until the stones themselves are humming. 🪵",
		},
		afternoon = {
			"Haste makes bitter broth, but patience yields golden nectar! +100% slow-cook bonus rewards our care! ☀️🍯",
			"Watch that stew bubble at a low simmer. The ingredients are conversing with one another; do not interrupt them.",
			"A deep rich flavor takes time to mature, just like the character of a fine chef.",
			"Let the guests wait a moment longer; when they taste the depth of our patient pot, they will forgive all.",
		},
		evening = {
			"The sun sinks into the western ridge... 🌄 Another day of slow, honest curing completed.",
			"Wipe the wooden eaves and turn the hanging fruit. A day well tended is a life well lived.",
			"Come, sit by the embers. Let us enjoy the deep fermented sweetness of our labor. ☀️",
		},
		night = {
			"The mountain frost settles upon the roof... 🌙 The cold only concentrates the inner sugar.",
			"Sleep soundly, young one. Time continues its quiet work in the fermentation crocks while you dream. ⭐",
			"Ho, ho... An old hermit's bones rest easy beside such a warm and faithful stove. 💤",
		},
		bond1 = {
			"I am Hoshidamon. If ye are looking for quick flashes and instant tricks, ye'll find none here. We cook with the seasons. ☀️",
			"The sweetest persimmon must endure thirty frosts before it surrenders its bitterness.",
		},
		bond2 = {
			"Ye have good hands, {player}. Ye don't rush the flame when things get busy. That shows true culinary wisdom. ☀️✨",
			"Aging together is a blessing. Every season spent in this kitchen enriches the broth of our friendship.",
		},
		bond3 = {
			"I spent seventy years alone in a wooden hut on the ridge, watching the seasons pass like shadows on the wall... I thought I was content with solitude and dried persimmons. But your laughter brought summer into my frozen winter heart. You showed this stubborn old hermit that warmth is sweetest when shared. I am proud to walk beside ye, chef. ☀️🍂💖",
			"Like cured timber that outlasts centuries of storms, my vow to protect ye and your hearth shall never rot.",
		},
		quest_branch = {
			"The sun-drying racks behind the pagoda need fresh winter fruit. Simmer the Sun-Cured Persimmon Paste and master the art of slow cooking! ☀️🍲",
			"Dishes with long cooking durations hold the deepest flavor; let the flame work its slow magic for doubled rewards.",
		},
	},
}

-- Serve-time companion reaction lines (short VN pops on guest served).
-- Reuses the ShowVNDialogue pipeline: keyed by compType with a DEFAULT
-- fallback so any companion without a bespoke entry still reacts.
local SERVE_REACTIONS = {
	zundamon = {
		"Delicious! That guest is going to remember our dish! ✨",
		"Another happy customer, {player}! The kitchen is thriving! 🍽️",
	},
	zundacat = {
		"Purrr... that serve was purrfect! 🐱",
		"The guest licked the plate clean! Excellent work! 🍽️",
	},
	ankomon = {
		"Profit and pride! That gold lands right on the ledger! 💰",
	},
	cardamon = {
		"A perfect window — the timing never slips with me! ⏱️",
	},
	antimon = {
		"Extra drops from good serves mean a fuller pouch! 🎒",
	},
	sakuradamon = {
		"Each served dish is a petal of your legend! 🌸",
	},
	tantanmon = {
		"Fast hands, happy guests! Speed is kindness! ⚡",
	},
	dog = {
		"Woof! That was a great serve! 🐕",
	},
	parrot = {
		"Squawk! Another guest fed! Polly is impressed! 🦜",
	},
	cat = {
		"Meow... acceptable. The guest was pleased. 🐱",
	},
	sumimon = {
		"A stroke of sheer brilliance! That plate was pure poetry! 🖌️✨",
		"Every empty plate is a completed masterpiece! 📜",
	},
	kagamon = {
		"Ta-da! Sparkling perfection served with a dazzling smile! 🪞💖",
		"Another fan mesmerized by our culinary stage show! ✨",
	},
	suzurimon = {
		"*RIIING!* The cadence holds! A righteous dish presented! 🔔",
		"Precision and dignity in every single serving! 🍽️",
	},
	wasabimon = {
		"OSS! Clean cut, fiery execution! On to the next order! 🌿🔥",
		"The discipline of the blade shows in every slice! 🔪",
	},
	yurimon = {
		"Sublime presentation! The court would applaud this triumph! 🪷👑",
		"Magnificent! Your generosity is reflected in their satisfied smile! 💰",
	},
	kinakomon = {
		"Eat up and thrive, dear guest! Hearty nourishment for the soul! 🌾",
		"Nothing warms an old heart like a clean, empty plate! 🥖💖",
	},
	kuroyurimon = {
		"MY ABYSSAL FEAST CONQUERS ANOTHER SOUL! ...I mean, enjoy! 🥀✨",
		"The forbidden sweetness spreads across the mortal realm! 🥧",
	},
	matchamon = {
		"Ichigo Ichie. A harmonious encounter served with peace. 🍵",
		"The rhythm flows like an unbroken stream of green tea. 🌿",
	},
	shisomon = {
		"Bio-availability maximized! The aromatic herbs work their magic! 🍃🧪",
		"Another successful gastronomic experiment delivered! 🔬",
	},
	karintomon = {
		"BOOM! JACKPOT SERVE! THE CARNIVAL RUSH ROLLS ON! 🏮💥",
		"THAT'S HOW WE DO IT AT THE FESTIVAL! NEXT CUSTOMER! 🥁",
	},
	tsukimidamon = {
		"A celestial blessing delivered upon a silver platter... 🌕✨",
		"The silver light glows brighter with every happy guest! 🌙",
	},
	hoshidamon = {
		"Ho, ho! Deep aged goodness warms the belly and the soul. ☀️",
		"Patience rewarded! That rich flavor cannot be rushed. 🍲",
	},
	DEFAULT = {
		"Hooray! The guest is satisfied! ✨",
		"Wonderful serve, chef! 🍽️",
	},
}

-- Look up a serve-time reaction line for a companion (falls back to DEFAULT).
local function getServeReaction(compType: string): string?
	local pool = SERVE_REACTIONS[compType] or SERVE_REACTIONS.DEFAULT
	if pool and #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return nil
end

-- Signature-dish synergy lines (short VN pop when active companion's favorite
-- recipe is served). Falls back to a generic cozy line so every companion
-- without a bespoke entry still celebrates the bonus.
local SERVE_SYNERGIES = {
	zundamon = {
		"A true Zunda classic! My heart is dancing like a fresh pea pod! 🌱✨",
		"You cooked that just like a village elder would be proud of, {player}! 🍡",
	},
	dog = {
		"Woof! Homestyle comfort food is the best comfort food! 🐕🍞",
		"That warm smell makes me want to wag my tail twice as fast!",
	},
	parrot = {
		"Squawk! Colorful ingredients make a colorful plate! 🦜🥗",
		"Bright and crunchy — just how a parrot likes it!",
	},
	cat = {
		"Meow... a refined choice. This dish has *depth*. 🐱🥧",
		"Elegant plating. The guest will remember this one.",
	},
	ankomon = {
		"Bean power! That protein will keep the kitchen running strong! 🥜💪",
		"A hearty serve is a profitable serve, {player}! 💰",
	},
	cardamon = {
		"A calm, steady recipe — the perfect canvas for a perfect cook. 🍵",
		"My leaves are practically humming with that warm aroma!",
	},
	antimon = {
		"Fresh from the earth! Every gather was worth it for this bowl. 🌿",
		"Quick, light, and bright — just like a good foraging run!",
	},
	sakuradamon = {
		"Each petal-shaped bite is a little poem on a plate! 🌸",
		"This dish blooms with kindness, {player}!",
	},
	tantanmon = {
		"Spice that warms the soul! Now that is a flavor with *fire*! 🌶️🔥",
		"Fast hands + bold broth = unstoppable kitchen energy! ⚡",
	},
	sumimon = {
		"My Ink-Wash Soba! The contrast of dark broth and pale noodle is living art, {player}! 🖌️🖤",
		"Every strand of soba is like a stroke of master calligraphy!",
	},
	kagamon = {
		"My Glazed Mirror Mochi! It shines brighter than a thousand stage spotlights! YAY! 🪞✨",
		"Look at that glossy surface! It reflects pure joy and zero cracks!",
	},
	suzurimon = {
		"Bell Chime Dango! The sacred sweetness echoes through the soul like a bronze bell! 🔔🍡",
		"A pure, ringing flavor that cleanses the spirit of all discord.",
	},
	wasabimon = {
		"Pungent Zunda Soba! That mountain kick clears the spirit and sharpens the blade! OSS! 🌿🔥",
		"Real heat, real discipline! That is the ascetic way!",
	},
	yurimon = {
		"Imperial Lily Glaze! Fit for the empress herself! Truly a masterpiece of elegance! 🪷👑",
		"Such regal luxury! The guests will speak of this feast for generations!",
	},
	kinakomon = {
		"Golden Dust Dango! Smothered in roasted flour just like home! Eat until you're full, dear! 🌾💖",
		"That nutty, toasty aroma is the true taste of maternal love!",
	},
	kuroyurimon = {
		"Eclipse Velvet Tart! The sweet darkness engulfs the senses in pure romance! 🥀🥧✨",
		"Darkness never tasted so rich! ...T-thank you for baking it with me!",
	},
	matchamon = {
		"Ceremonial Froth Bowl! Whisked to perfection in flawless stillness. True Chado! 🍵🌿",
		"The jade foam holds the tranquility of the ancient tea mountains.",
	},
	shisomon = {
		"Pickled Perilla Wrap! The medicinal enzymes and wild herbs unite in scientific perfection! 🍃🧪",
		"A breakthrough in botanical culinary alchemy! Eureka!",
	},
	karintomon = {
		"Crisp Molasses Crunch! CRUNCHY, SWEET, AND PACKED WITH FESTIVAL HYPE! WASSHOI! 🏮💥",
		"A GOLDEN CARNIVAL JACKPOT ON EVERY SINGLE PLATE! WAHOO!",
	},
	tsukimidamon = {
		"Lunar Dumpling Plate! Round and luminous like the harvest moon smiling upon the valley! 🌕🍡",
		"Celestial harmony upon a plate... The stars themselves rejoice!",
	},
	hoshidamon = {
		"Sun-Cured Persimmon Paste! Decades of patient sun and frost condensed into pure honeyed depth! ☀️🍂",
		"True depth of aging... Nothing in this world matches patient craft.",
	},
	DEFAULT = {
		"A perfect match for today! That synergy tastes like victory! ✨",
		"This dish and your companion are in harmony! 🍽️",
	},
}

-- Look up a signature-dish synergy line for a companion (falls back to DEFAULT).
local function getServeSynergy(compType: string): string?
	local pool = SERVE_SYNERGIES[compType] or SERVE_SYNERGIES.DEFAULT
	if pool and #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return nil
end

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
VNDialogueData.getServeReaction = getServeReaction
VNDialogueData.getServeSynergy = getServeSynergy

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

-- Guest spawn/timeout dialogue, keyed by GuestManager's meshType (e.g.
-- "male", "animal-fox", "animal-tiger"). This table never existed before --
-- GuestManager.server.lua has looked up VNDialogueData.GUEST_BY_TYPE[meshType]
-- since it was written, but the key was always nil, so guests never actually
-- said anything on spawn/timeout for ANY guest type (Kenney humans included).
-- DEFAULT covers every guest type without a bespoke entry (all 24 animal
-- meshes + any future ones) with several random variants so it doesn't feel
-- repetitive; a few of the original Kenney human types get flavorful
-- overrides since NPCConfig clearly intended them to have distinct voices.
VNDialogueData.GUEST_BY_TYPE = {
	DEFAULT = {
		spawn = {
			"Ooh, {recipe} smells amazing from here~ 🌸",
			"Excuse me, chef! Could I get some {recipe}? 🍽️",
			"I've been craving {recipe} all day! 💫",
			"Table for one, please! I'll have the {recipe}~",
			"Is this the place with the famous {recipe}? 🌟",
		},
		timeout = {
			"Ah, I couldn't wait any longer... maybe next time! 💦",
			"Sorry chef, I have somewhere to be~ 🥲",
			"I'll come back when it's less busy!",
		},
	},
	male = {
		spawn = { "Hey chef! One {recipe}, when you get a chance!" },
		timeout = { "Guess I'll grab a snack elsewhere. See ya!" },
	},
	female = {
		spawn = { "Hi there~ Could I try your {recipe}? I've heard so much about it! 🌷" },
		timeout = { "Oh no, I really have to run -- next time for sure!" },
	},
	male2 = {
		spawn = { "{recipe}, please! Make it your best one~" },
		timeout = { "No worries, I'll swing back around later." },
	},
	female2 = {
		spawn = { "Ehe~ {recipe} sounds perfect right about now! 🎀" },
		timeout = { "Aw, maybe I was too impatient... sorry chef!" },
	},
	parrot = {
		spawn = { "Squawk! {recipe} for me, please! 🦜" },
		timeout = { "Squawk! Gotta fly! Byeee!" },
	},
	lotus = {
		spawn = { "Such a peaceful spot~ I'll have the {recipe}, thank you. 🪷" },
		timeout = { "The patience of a lotus has limits too... farewell." },
	},
	cupcake = {
		spawn = { "Yay, {recipe} time!! I'm SO excited!! 🧁" },
		timeout = { "Boo, I wanted that {recipe} so bad... maybe later!" },
	},
	zundamon = {
		spawn = { "Fellow Zunda villager here~ {recipe}, if you please! 🌱" },
		timeout = { "Ah well, back to the village for me!" },
	},
}

-- ── Canon Companion Dialogue ─────────────────────────────────────────────────

COMPANION_DIALOGUE.kiritandamon = {
	morning = {
		"Good morning, {player}. Optimal cook start time: now. I have pre-calculated the ingredient queue. 📐",
		"I noted a 0.3-second delay in your knife timing yesterday. We will correct that today.",
		"Morning efficiency is up 12% when breakfast is served before 8 AM. This is not a suggestion.",
		"I have prepared a revised prep schedule. You will find it improves throughput by approximately 18%.",
	},
	afternoon = {
		"Afternoon service peak begins in four minutes. I suggest beginning the Royal Stew now.",
		"Your precision stat is at 73% of optimal. This is addressable. I have a plan.",
		"I ran the numbers on your last five cooks. Pattern identified. Improvement vector: wrist angle.",
		"The lunch rush is a solvable problem, {player}. Everything is a solvable problem.",
	},
	evening = {
		"Evening wind-down. I am compiling the day's data into a performance report.",
		"Not bad today, {player}. Efficiency was 81%. That leaves a clear 19% margin for tomorrow.",
		"I find evenings productive. Fewer interruptions. More time for analysis.",
	},
	night = {
		"You are still here? Good. Night shifts reward precision over speed. This suits me.",
		"The kitchen is quieter at night. I can hear the timers more clearly. I prefer this.",
		"Sleep is important. I have quantified this. Eight hours, minimum. But — one more cook first.",
	},
	bond1 = {
		"I have flagged you as a cooperative variable in my models, {player}. This is positive.",
		"Your technique shows measurable improvement. I am noting this in the log.",
	},
	bond2 = {
		"I have adjusted my models to account for your particular style. It is... less inefficient than I assumed.",
		"I may have understated your potential in my initial assessment. I am revising upward.",
	},
	bond3 = {
		"I have reviewed every cook we have done together, {player}. My models did not predict this outcome: that the most interesting variable would be you.",
		"Kiritan keeps a log of anomalous successes — cooks that defy her models. You have your own column now. It is the longest one.",
	},
	quest_branch = {
		"There is a pattern in the guest data I cannot explain with current parameters. I need you to run 10 precision cooks. For the data.",
		"My models suggest a companion bond effect that amplifies precision beyond statistical baseline. I am investigating. You are the experiment.",
	},
}

COMPANION_DIALOGUE.itakodamon = {
	morning = {
		"... the morning smells of preparation. Good. Prepare well, {player}. What comes later will need it.",
		"I have seen this kitchen in many states. Morning is when it breathes in. Cook now.",
		"A thread connects this dawn to one I witnessed long ago. It is the same light. You are not the same chef yet.",
	},
	afternoon = {
		"The afternoon hum. Guests arrive like tides. Serve them, {player}. The tide always comes.",
		"I dreamed of a recipe last night. I do not dream often. I believe it was a warning about the Royal Stew.",
		"There is something in the kitchen that has not moved since the village was built. I know what it is. You will too, eventually.",
	},
	evening = {
		"Evening. The boundary thins. I can hear the older kitchens now.",
		"... do not burn the soup tonight, {player}. I saw something in the smoke when you burned it last time.",
		"Dusk is when the arrows remember what they were made for. This is not metaphor.",
	},
	night = {
		"Good. You are still here. Night is when the true tests arrive.",
		"I have spoken with the kitchen itself tonight. It has no complaints about you.",
		"Sleep will come, {player}. But not yet. There is one more thing I must show you, when you are ready.",
	},
	bond1 = {
		"You serve the guests without cruelty. This is rarer than you know. I am noting it.",
		"I have watched you from the beginning. You were uncertain then. You are less uncertain now.",
	},
	bond2 = {
		"I will tell you something I tell no one: the Zunda Arrow was not always a weapon. It was a wish, first.",
		"The oracle in me sees your path. I will not describe it — foreknowledge is a poor gift. But it is not a short path.",
	},
	bond3 = {
		"I was at the forging of the Zunda Arrow, {player}. I remember the moment Zundamon first spoke. She said something very simple. She said: I am going to be so warm. She has not changed. Neither have you, in the ways that matter.",
		"I have not told anyone what I know about that day. I am not telling you now. But I am sitting here with you, which is as close as I come to speaking.",
	},
	quest_branch = {
		"The oracle sees three paths from this kitchen. You are walking the middle one. This is not a warning.",
		"Serve the ancient guests well. They carry more than hunger. They carry memory of the kitchens that came before.",
	},
}

COMPANION_DIALOGUE.zunkodamon = {
	morning = {
		"MORNING, {player}! THE KITCHEN IS OURS! WHAT ARE WE CONQUERING FIRST?! ⚔️🍳",
		"I HAVE REVIEWED THE MENU. EVERY DISH IS AN OBJECTIVE. WE COMPLETE THEM ALL! 💪",
		"THE GUESTS ARE INCOMING! PREP IS HALF THE BATTLE! HALF! THE OTHER HALF IS FIRE! 🔥",
		"ZUNKO ONCE SAID: A CHEF WHO HESITATES SERVES COLD SOUP. I AGREE COMPLETELY!!! ⚔️",
	},
	afternoon = {
		"LUNCH RUSH!!! THIS IS MY FAVORITE KIND OF TACTICAL SITUATION!!! 🍜🔥",
		"I AM TRACKING FOUR ACTIVE GUESTS SIMULTANEOUSLY! MY BATTLE SENSE IS TINGLING!",
		"DO NOT LET THE GUEST TIMER REACH ZERO! WE DO NOT LEAVE PEOPLE HUNGRY! THIS IS MY LAW!",
	},
	evening = {
		"Good work today, {player}. The kitchen held. That is what matters.",
		"Victory tastes better when it was earned. Today was earned.",
		"I will tell you something. I was a warrior before I was a cook. The discipline is the same.",
	},
	night = {
		"You are still at the stove. Good. The best cooks are the last ones in the kitchen.",
		"Night shift is the truest test of a chef. No one watching. Just you and the fire.",
		"Rest when the kitchen allows it. Not before. But... the kitchen allows it now, {player}.",
	},
	bond1 = {
		"You held the line well today. I do not say that often. Receive it.",
		"Your serve speed is improving. I am watching. Keep this up.",
	},
	bond2 = {
		"I once wielded someone very dear to me as an arrow. She is here now, as a companion instead. I prefer this arrangement.",
		"You remind me of what good service means. Not battle. Not victory. Just: people who needed feeding, and someone who showed up.",
	},
	bond3 = {
		"I served under Tohoku Zunko for an age, {player}. I watched her turn from warrior to chef and never once look back. I asked her why. She said: because the kitchen never runs out of battles. She was right. You are proof.",
		"The best thing I have done in this kitchen was choose to stay in it. Second best: meeting you. These are close.",
	},
	quest_branch = {
		"YOUR MISSION: SERVE EVERY GUEST AT MAXIMUM QUALITY! CASUALTIES ARE NOT ACCEPTABLE! COLD SOUP IS A CASUALTY! 🔥",
		"I need you to prove you can hold the rush alone. This is the warrior's test. I will be watching.",
	},
}

COMPANION_DIALOGUE.zunabunny = {
	morning = {
		"GOOD MORNING!!! I KNOCKED OVER THE FLOUR AGAIN BUT IT'S FINE!!! EVERYTHING IS FINE!!! 🐰✨",
		"I HAVE A PLAN FOR TODAY AND IT'S GREAT!!! I ALREADY FORGOT IT BUT THE ENERGY IS THERE!!!",
		"I AM ZUNDAMON BUT SMALLER AND ALSO I MAKE WORSE DECISIONS!!! LET'S COOK!!!",
		"THE SUN IS OUT!!! SOMETHING GOOD WILL HAPPEN TODAY!!! STATISTICALLY!!! 🌱🌱🌱",
	},
	afternoon = {
		"I TRIED TO HELP AND NOW THE POT IS ON THE FLOOR BUT THAT'S A DIFFERENT POT NOW SO IT'S FINE!!!",
		"THE GUESTS LOVE ME!!! ONE OF THEM DID NOT LOVE ME BUT THE OTHERS DID!!! NET POSITIVE!!!",
		"I ADDED AN EXTRA INGREDIENT AND IT MADE IT BETTER!!! I WILL NOT BE ABLE TO REPEAT THIS!!!",
	},
	evening = {
		"Today was good! Mostly. The thing that happened in the middle doesn't count.",
		"I broke something but I fixed something else. Kitchen karma.",
		"Are we cooking more? We should cook more. I have ideas. The last idea was good. This one will also be good. Probably.",
	},
	night = {
		"I'M STILL AWAKE!!! I'M NOT SURE WHY!!! IS THERE FOOD?!",
		"Night shift is when I do my best work because no one can see what I'm doing!!! This is strategy!!!",
		"If I knock something over at night does it make a sound? Yes. Yes it does. I know this now.",
	},
	bond1 = {
		"You didn't get mad when I spilled the edamame! You are my favorite person!",
		"I told Zundamon about you. She said she knows. She knows everything. It's a little scary.",
	},
	bond2 = {
		"I am Zundamon's mascot form, which means I contain all of her warmth at 1.3x concentration and 0.6x coordination.",
		"She and I share a soul. Sort of. It's complicated. The important thing is: we both like you very much.",
	},
	bond3 = {
		"I told Zundamon once that being her mascot form was confusing. She said: you are not less than me, Zunabunny. You are what I look like when no one is watching. I thought about this for a long time. I think it's a compliment.",
		"You never asked me to be smaller or quieter or less chaotic. So I never was. I think that's why we're here together now. 🐰",
	},
	quest_branch = {
		"I HEARD THERE'S A QUEST!!! I WANT TO HELP!!! I'M NOT SURE WHAT HAPPENED LAST TIME BUT THIS TIME WILL BE DIFFERENT!!!",
		"The quest involves cooking things! I CAN DO THAT!!! APPROXIMATELY!!!",
	},
}

COMPANION_DIALOGUE.nanonadamon = {
	morning = {
		"The light returns, のだ.",
		"You begin again today, のだ. This is what chefs do, のだ.",
		"The kitchen is the same as yesterday, のだ. You are not, のだ. This is correct, のだ.",
	},
	afternoon = {
		"The guests arrive, のだ. Serve them, のだ.",
		"The cook is at the peak of their day, のだ. Do not waste it, のだ.",
		"The Arrow knew this hour well, のだ. It is the hour of purpose, のだ.",
	},
	evening = {
		"The light changes, のだ. The kitchen breathes out, のだ.",
		"You have done enough today, のだ. Enough is enough, のだ.",
		"I was here before the first evening this kitchen saw, のだ. I will be here for the last, のだ.",
	},
	night = {
		"The quiet, のだ.",
		"Night is when the kitchen remembers what it is for, のだ.",
		"You are here late, のだ. Something is on your mind, のだ. It will still be there tomorrow, のだ. Rest, のだ.",
	},
	bond1 = {
		"You cook with intention, のだ. The Arrow was made with intention, のだ. There is a resemblance, のだ.",
		"I have been here a very long time, のだ. Few have cooked beside me, のだ. You are one of them now, のだ.",
	},
	bond2 = {
		"The Arrow flew once, のだ. It was the last time, のだ. When it landed, I became this, のだ. A fragment. A presence. A watcher, のだ.",
		"I do not speak of that day to anyone, のだ. I have sat with you long enough to make an exception, のだ. Not today. But soon, のだ.",
	},
	bond3 = {
		"Zundamon was the Arrow, のだ. I am what the Arrow left behind when it chose to become her, のだ. She kept everything warm, のだ. I kept everything that was before the warmth, のだ. We are the same story told from two ends, のだ.",
		"You have earned the end of this story, {player}, のだ. The kitchen you stand in was not built for you, のだ. But you have made it yours, のだ. That is what the Zunda Arrow was always for, のだ.",
	},
	quest_branch = {
		"The origin awaits, のだ. You are walking toward it, のだ. Have been since the first cook, のだ.",
		"What you seek is here, のだ. It was always here, のだ. You simply needed to look, のだ.",
	},
	evolution_awakening = {
		"... the fragment remembers the whole, のだ.",
		"The Arrow. The flight. The landing. Now: the kitchen, のだ.",
		"I did not expect to feel this, のだ. But I do, のだ.",
	},
}

return VNDialogueData
