--!strict
-- [[ModuleScript] DiscordWebhookService]]
-- Server service that broadcasts high-dopamine game events (5-star Gacha pulls,
-- Wave 20+ Challenge wins, Weekly Boss defeats) to Discord channels via HttpService.

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")

local DiscordWebhookService = {}
local webhookUrl = os.getenv("DISCORD_GACHA_WEBHOOK") or ""

local function postEmbed(embedData: { [string]: any })
	if webhookUrl == "" or not webhookUrl:find("http") then return end

	local payload = HttpService:JSONEncode({
		embeds = { embedData }
	})

	task.spawn(function()
		pcall(function()
			HttpService:PostAsync(webhookUrl, payload, Enum.HttpContentType.ApplicationJson)
		end)
	end)
end

function DiscordWebhookService.setWebhookUrl(url: string)
	webhookUrl = url
end

function DiscordWebhookService.broadcastGachaPull(player: Player, itemName: string, rarity: string, bannerName: string)
	if rarity ~= "5star" and rarity ~= "SSR" and rarity ~= "Legendary" then return end

	local embed = {
		title = "🌟 5-STAR LEGENDARY PULL! 🌟",
		description = string.format("**%s** just pulled **[%s]** from the *%s* banner nanoda! 🌱✨", player.Name, itemName, bannerName or "Whim Banner"),
		color = 16766720, -- Gold #FFC800
		fields = {
			{ name = "🎮 Play Now", value = "[Join Zundamon's Kitchen V2](https://www.roblox.com/)", inline = true },
			{ name = "📊 Web Hub", value = "[Zunda-OS 95 Portal](https://fromage3900.github.io/Zundamons-Kitchen-V2/)", inline = true }
		},
		footer = { text = "Zundamon's Kitchen V2 · Live Community Feed" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	}

	postEmbed(embed)
end

function DiscordWebhookService.broadcastChallengeWave(player: Player, waveNumber: number, score: number)
	if waveNumber < 20 then return end

	local embed = {
		title = "🌊 CHALLENGE WAVE MILESTONE! 🌊",
		description = string.format("Chef **%s** reached **Wave %d** in Challenge Mode with **%d points** nanoda! 🔥", player.Name, waveNumber, score),
		color = 5814783, -- Neon Mint #58B9FF
		fields = {
			{ name = "🏆 Rank Tier", value = "Zunda Royal Chef", inline = true }
		},
		footer = { text = "Zundamon's Kitchen V2 · Challenge Mode" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	}

	postEmbed(embed)
end

function DiscordWebhookService.broadcastBossDefeat(player: Player, bossName: string)
	local embed = {
		title = "👑 WEEKLY BOSS CONQUERED! 👑",
		description = string.format("Master Chef **%s** has defeated the Weekly Boss **[%s]** nanoda! 🎉", player.Name, bossName),
		color = 16724889, -- Sakura Pink #FF477E
		footer = { text = "Zundamon's Kitchen V2 · Weekly Event" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
	}

	postEmbed(embed)
end

print("[DiscordWebhookService] Initialized ✓")
return DiscordWebhookService
