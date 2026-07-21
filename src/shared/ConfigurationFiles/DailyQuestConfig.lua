-- [[ModuleScript] DailyQuestConfig (ref: RBX7F60FA34B55B4FDBBA065EC35D13C716)]]
return {
    pool = {
        { id = "serve_5",       title = "Serve 5 guests",       metric = "serve",   goal = 5,  reward = { gold = 80,  xp = 60 } },
        { id = "serve_perfect", title = "Cook 3 perfect dishes",metric = "perfect", goal = 3,  reward = { gold = 100, xp = 80 } },
        { id = "gather_20",     title = "Gather 20 items",      metric = "gather",  goal = 20, reward = { gold = 60,  xp = 50 } },
        { id = "combo_8",       title = "Hit an 8x combo",      metric = "combo",   goal = 8,  reward = { gold = 120, xp = 100 } },
        { id = "craft_10",      title = "Craft 10 dishes",      metric = "craft",   goal = 10, reward = { gold = 100, xp = 80 } },
    },
    loginBonus = {
        baseGold = 50,
        streakBonus = 25,   -- per consecutive day
        capDays = 7,
    },
}
