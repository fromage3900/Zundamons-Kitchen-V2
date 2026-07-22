-- [[ModuleScript] DailyQuestConfig (ref: RBX7F60FA34B55B4FDBBA065EC35D13C716)]]
return {
    pool = {
        { id = "serve_5",       title = "Serve 5 guests",       metric = "serve",   goal = 5,  reward = { gold = 80,  xp = 60 } },
        { id = "serve_perfect", title = "Cook 3 perfect dishes",metric = "perfect", goal = 3,  reward = { gold = 100, xp = 80 } },
        { id = "gather_20",     title = "Gather 20 items",      metric = "gather",  goal = 20, reward = { gold = 60,  xp = 50 } },
        { id = "combo_8",       title = "Hit an 8x combo",      metric = "combo",   goal = 8,  reward = { gold = 120, xp = 100 } },
        { id = "craft_10",      title = "Craft 10 dishes",      metric = "craft",   goal = 10, reward = { gold = 100, xp = 80 } },
        { id = "serve_3perfect",title = "Cook 3 perfect dishes",metric = "perfect", goal = 3,  reward = { gold = 100, xp = 80 } },
        { id = "gather_10",     title = "Gather 10 items",      metric = "gather",  goal = 10, reward = { gold = 40,  xp = 30 } },
        { id = "craft_5",       title = "Craft 5 dishes",       metric = "craft",   goal = 5,  reward = { gold = 60,  xp = 40 } },
        { id = "combo_5",       title = "Hit a 5x combo",       metric = "combo",   goal = 5,  reward = { gold = 80,  xp = 60 } },
        { id = "fish_3",        title = "Catch 3 fish",         metric = "fish",    goal = 3,  reward = { gold = 70,  xp = 50 } },
        { id = "visit_visitor", title = "Visit the daily guest",metric = "visitor", goal = 1,  reward = { gold = 50,  xp = 40 } },
    },
    loginBonus = {
        baseGold = 50,
        streakBonus = 25,
        capDays = 7,
    },
    dailyVisitor = {
        npcId = "rbxassetid://128478553136178",
        npcName = "Nikki the Drifter",
        spawnPoint = Vector3.new(192, -518, -408),
        reward = { gold = 100, xp = 80, item = "Zunda Flower" },
        dialogueMorning = {
            "The morning breeze carries whispers of adventure... 🌄",
            "I've traveled far to taste your cooking today!",
            "A new day, a new recipe to discover~ ✨",
        },
        dialogueEvening = {
            "The stars are out... time for a warm meal! 🌙",
            "Evening is the best time for comfort food.",
            "The day's journey ends with a full belly~ 🌟",
        },
    },
    dailyResources = {
        { resourceType = "Zunda Flower", count = 3, meshHint = "ZundaFlower_Rare" },
        { resourceType = "Zunda Pea",    count = 5, meshHint = "ZundaPea_02" },
    },
}
