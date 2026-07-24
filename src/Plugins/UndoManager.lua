--!strict
-- UndoManager: ChangeHistory-based undo for procedural decorations
-- Infinity Nikki aesthetic: "Outfit rollback" — undo a styling session
local UndoManager = {}

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Workspace = game:GetService("Workspace")

UndoManager._batches = {}
UndoManager._allPlaced = {}

function UndoManager.registerBatch(instances, zoneName)
	if not instances or #instances == 0 then return end

	local batchId = zoneName .. "_" .. tick()
	local batch = {
		id = batchId,
		zone = zoneName,
		instances = {},
		waypoint = "ZundaDecorator_" .. zoneName .. "_" .. math.random(1000, 9999),
	}

	ChangeHistoryService:SetWaypoint(batch.waypoint .. "_start")

	for _, inst in ipairs(instances) do
		if inst and inst.Parent then
			table.insert(batch.instances, inst)
			table.insert(UndoManager._allPlaced, inst)
		end
	end

	UndoManager._batches[batchId] = batch
	UndoManager._batches[zoneName] = batch

	ChangeHistoryService:SetWaypoint(batch.waypoint .. "_end")
end

function UndoManager.undoZone(zoneName)
	local batch = UndoManager._batches[zoneName]
	if not batch then
		warn("[UndoManager] No decorations found for zone: " .. tostring(zoneName))
		return
	end

	ChangeHistoryService:SetWaypoint(batch.waypoint .. "_undo_start")

	for _, inst in ipairs(batch.instances) do
		if inst and inst.Parent then
			inst:Destroy()
		end
	end

	UndoManager._batches[zoneName] = nil

	ChangeHistoryService:SetWaypoint(batch.waypoint .. "_undo_end")
	ChangeHistoryService:Undo()

	print("[UndoManager] Undid " .. #batch.instances .. " decorations in " .. zoneName)
end

function UndoManager.clearAll()
	ChangeHistoryService:SetWaypoint("ZundaDecorator_ClearAll_start")

	for _, inst in ipairs(UndoManager._allPlaced) do
		if inst and inst.Parent then
			inst:Destroy()
		end
	end

	UndoManager._allPlaced = {}
	UndoManager._batches = {}

	ChangeHistoryService:SetWaypoint("ZundaDecorator_ClearAll_end")

	print("[UndoManager] Cleared all decorations")
end

function UndoManager.getBatchInfo(zoneName)
	local batch = UndoManager._batches[zoneName]
	if not batch then return nil end
	return {
		zone = batch.zone,
		count = #batch.instances,
		id = batch.id,
	}
end

function UndoManager.listZones()
	local zones = {}
	for zoneName, batch in pairs(UndoManager._batches) do
		if type(zoneName) == "string" and zoneName ~= batch.id then
			table.insert(zones, zoneName)
		end
	end
	return zones
end

return UndoManager
