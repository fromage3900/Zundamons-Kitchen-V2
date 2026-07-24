--!strict
-- LODManager: Distance-based LOD for procedural decorations
-- Infinity Nikki aesthetic: sparkle density scales with distance
local LODManager = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

LODManager._registered = {}
LODManager._enabled = false
LODManager._heartbeatConn = nil

LODManager.LOD_LEVELS = {
	{ maxDistance = 30, detail = "full", sparkle = 1.0 },
	{ maxDistance = 60, detail = "medium", sparkle = 0.7 },
	{ maxDistance = 120, detail = "low", sparkle = 0.4 },
	{ maxDistance = 200, detail = "minimal", sparkle = 0.1 },
}

function LODManager.init()
	LODManager._enabled = true
	LODManager._registered = {}
	LODManager._heartbeatConn = RunService.Heartbeat:Connect(LODManager._update)
	print("[LODManager] Initialized — sparkle density will scale with distance ✨")
end

function LODManager.registerDecorations(instances)
	for _, inst in ipairs(instances or {}) do
		if inst and inst:IsA("Model") then
			LODManager._registered[inst] = {
				model = inst,
				lastUpdate = tick(),
			}
		end
	end
end

function LODManager._update()
	if not LODManager._enabled then return end

	local player = Players.LocalPlayer
	if not player then return end
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local camPos = camera.CFrame.Position

	for inst, data in pairs(LODManager._registered) do
		if inst and inst.Parent and inst:IsA("Model") then
			local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
			if primary then
				local distance = (primary.Position - camPos).Magnitude
				local lodLevel = LODManager._getLODLevel(distance)
				LODManager._applyLOD(inst, lodLevel)
			end
		else
			LODManager._registered[inst] = nil
		end
	end
end

function LODManager._getLODLevel(distance)
	for _, level in ipairs(LODManager.LOD_LEVELS) do
		if distance <= level.maxDistance then
			return level
		end
	end
	return LODManager.LOD_LEVELS[#LODManager.LOD_LEVELS]
end

function LODManager._applyLOD(model, lodLevel)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if lodLevel.detail == "minimal" then
				part.Transparency = math.clamp(part.Transparency + 0.5, 0, 0.95)
			elseif lodLevel.detail == "low" then
				part.Transparency = math.clamp(part.Transparency + 0.2, 0, 0.8)
			else
				part.Transparency = math.clamp(part.Transparency - 0.2, 0, 0.5)
			end
		elseif part:IsA("PointLight") then
			part.Brightness = part.Brightness * lodLevel.sparkle
		end
	end
end

function LODManager.shutdown()
	LODManager._enabled = false
	if LODManager._heartbeatConn then
		LODManager._heartbeatConn:Disconnect()
		LODManager._heartbeatConn = nil
	end
	LODManager._registered = {}
	print("[LODManager] Shutdown complete")
end

function LODManager.getRegisteredCount()
	local count = 0
	for _ in pairs(LODManager._registered) do
		count += 1
	end
	return count
end

return LODManager
