-- [[Script] CompanionCreatorServer]
-- Wires the companion creator to the client. Exposes two RemoteFunctions:
--   CreateCompanion(spec)  -> (ok, idOrReason)  — register a validated spec
--   SummonCompanion(theme) -> (ok, idOrReason)  — AI-generate + register
-- Plus a RemoteEvent CompanionCreated(id) fired to the client when a custom
-- companion is registered, so the UI can equip/show it immediately.
--
-- The client never supplies arbitrary values: CompanionCreatorService.validate
-- whitelists buff stats, emojis, colors, and string lengths, so a hostile client
-- cannot inject junk into player data.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Creator = require(ServerScriptService.Services.CompanionCreatorService)

-- ── Remotes (create if the place hasn't got them yet) ─────────
local RE = RS:FindFirstChild("RemoteEvents") or Instance.new("Folder")
if not RE.Parent then
	RE.Name = "RemoteEvents"
	RE.Parent = RS
end
local RF = RS:FindFirstChild("RemoteFunctions") or Instance.new("Folder")
if not RF.Parent then
	RF.Name = "RemoteFunctions"
	RF.Parent = RS
end

local CreateCompanion = RF:FindFirstChild("CreateCompanion")
if not CreateCompanion then
	CreateCompanion = Instance.new("RemoteFunction")
	CreateCompanion.Name = "CreateCompanion"
	CreateCompanion.Parent = RF
end

local SummonCompanion = RF:FindFirstChild("SummonCompanion")
if not SummonCompanion then
	SummonCompanion = Instance.new("RemoteFunction")
	SummonCompanion.Name = "SummonCompanion"
	SummonCompanion.Parent = RF
end

local CompanionCreated = RE:FindFirstChild("CompanionCreated")
if not CompanionCreated then
	CompanionCreated = Instance.new("RemoteEvent")
	CompanionCreated.Name = "CompanionCreated"
	CompanionCreated.Parent = RE
end

-- ── Handlers ──────────────────────────────────────────────────
CreateCompanion.OnServerInvoke = function(player, spec)
	local ok, result = Creator.create(player, spec)
	if ok then
		CompanionCreated:FireClient(player, result)
		return true, result
	end
	return false, result
end

-- Summon = AI-generate a companion from a theme, then register it.
SummonCompanion.OnServerInvoke = function(player, theme)
	local voice = nil -- future: pass a voicevox style here
	local generated = Creator.generate(player, theme, voice)
	local ok, result = Creator.create(player, generated)
	if ok then
		CompanionCreated:FireClient(player, result)
		return true, result, generated
	end
	return false, result, generated
end

print("[CompanionCreatorServer] online")
