--!strict
-- Install as a local Studio plugin. This file is intentionally outside the
-- default game Rojo tree and never executes in a published server.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

-- Fail-safe: this script must only run in a Studio plugin context (where the
-- `plugin` global exists). If a copy of this Model is ever left inside Workspace
-- and saved into the place, it would otherwise throw on `plugin:CreateToolbar`
-- every load at runtime. Bail out cleanly instead.
if not plugin then
	return
end

local toolbar = plugin:CreateToolbar("Zunda Kitchen")
local toolbarButton = toolbar:CreateButton("Resource Visuals", "Replace harvest visuals safely", "")
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 360, 620, 300, 420)
local widget = plugin:CreateDockWidgetPluginGui("ZundaResourceVisualAuthoringV1", widgetInfo)
widget.Title = "Resource Visual Authoring"

local rootFrame = Instance.new("ScrollingFrame")
rootFrame.Name = "Root"
rootFrame.Size = UDim2.fromScale(1, 1)
rootFrame.CanvasSize = UDim2.fromOffset(0, 0)
rootFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
rootFrame.ScrollBarThickness = 6
rootFrame.BackgroundColor3 = Color3.fromRGB(244, 251, 239)
rootFrame.BorderSizePixel = 0
rootFrame.Parent = widget

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = rootFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = rootFrame

local function label(text: string, height: number?): TextLabel
	local item = Instance.new("TextLabel")
	item.Size = UDim2.new(1, 0, 0, height or 24)
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.Gotham
	item.TextSize = 13
	item.TextColor3 = Color3.fromRGB(52, 67, 49)
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Text = text
	item.Parent = rootFrame
	return item
end

local function input(placeholder: string, initial: string?): TextBox
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 32)
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.BorderColor3 = Color3.fromRGB(160, 210, 150)
	box.Font = Enum.Font.Code
	box.TextSize = 13
	box.TextColor3 = Color3.fromRGB(35, 45, 35)
	box.PlaceholderText = placeholder
	box.ClearTextOnFocus = false
	box.Text = initial or ""
	box.Parent = rootFrame
	return box
end

local function button(text: string, color: Color3?): TextButton
	local item = Instance.new("TextButton")
	item.Size = UDim2.new(1, 0, 0, 34)
	item.BackgroundColor3 = color or Color3.fromRGB(160, 210, 150)
	item.BorderSizePixel = 0
	item.Font = Enum.Font.GothamBold
	item.TextSize = 13
	item.TextColor3 = Color3.fromRGB(42, 48, 39)
	item.Text = text
	item.Parent = rootFrame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = item
	return item
end

label("Select one or more harvest roots, paste an experience-owned asset ID, validate, preview, then apply.", 48)
label("Resource archetype")
local archetypeBox = input("Rock, GoldRock, AppleTree, Wheat…", "Rock")
label("Variant name")
local variantBox = input("Rock_Common", "Rock_Common")
label("Roblox asset ID or URL")
local assetBox = input("rbxassetid://123456789 or Creator URL")
label("Asset type: Mesh or Model")
local typeBox = input("Mesh", "Mesh")
label("Uniform scale / Y offset / Y rotation")
local transformBox = input("1, 0, 0", "1, 0, 0")

local status = label("Ready. No changes made.", 44)
status.BackgroundColor3 = Color3.fromRGB(230, 241, 225)
status.BackgroundTransparency = 0

local validateButton = button("1. Validate asset", Color3.fromRGB(145, 215, 195))
local previewButton = button("2. Preview on selection", Color3.fromRGB(255, 200, 80))
local applyButton = button("3. Apply to selection", Color3.fromRGB(160, 210, 150))
local replaceAllButton = button("Replace all nodes using this variant", Color3.fromRGB(255, 200, 80))
local createButton = button("Make selection a ResourceNode")
local restoreButton = button("Restore previous visual", Color3.fromRGB(255, 190, 205))
local fallbackButton = button("Use procedural fallback", Color3.fromRGB(220, 220, 220))
local diagnosticsButton = button("Scan resource diagnostics", Color3.fromRGB(145, 215, 195))
label("Catalog snapshot JSON (copy this into project notes for recovery)")
local catalogBox = input("Exported catalog JSON appears here")
catalogBox.MultiLine = true
catalogBox.Size = UDim2.new(1, 0, 0, 72)
local exportButton = button("Export Studio catalog")
local importButton = button("Import catalog JSON")

local function report(message: string, level: string?)
	status.Text = message
	status.BackgroundColor3 = if level == "error"
		then Color3.fromRGB(255, 190, 205)
		elseif level == "warning" then Color3.fromRGB(255, 225, 150)
		else Color3.fromRGB(205, 239, 199)
end

local function parseAssetId(value: string): (number?, string)
	local digits = string.match(value, "%d+")
	local numeric = digits and tonumber(digits) or nil
	return numeric, if numeric then "rbxassetid://" .. tostring(numeric) else ""
end

local function normalizedAssetType(): string
	return string.lower(string.gsub(typeBox.Text, "%s+", ""))
end

local function validateFields(): (boolean, string)
	if string.match(archetypeBox.Text, "^%s*$") then
		return false, "Resource archetype cannot be empty."
	end
	if string.match(variantBox.Text, "^%s*$") then
		return false, "Variant name cannot be empty."
	end
	local assetType = normalizedAssetType()
	if assetType ~= "mesh" and assetType ~= "model" then
		return false, "Asset type must be Mesh or Model."
	end
	return true, ""
end

local function parseTransform(): (number, number, number)
	local values = string.split(transformBox.Text, ",")
	local scale = math.clamp(tonumber(values[1]) or 1, 0.05, 100)
	local yOffset = math.clamp(tonumber(values[2]) or 0, -100, 100)
	local yRotation = tonumber(values[3]) or 0
	return scale, yOffset, yRotation
end

local function selectedRoots(): { BasePart }
	local roots = {}
	local seen = {}
	for _, selected in Selection:Get() do
		local root: BasePart? = nil
		if selected:IsA("BasePart") then
			root = selected
		elseif selected:IsA("Model") then
			root = selected.PrimaryPart or selected:FindFirstChildWhichIsA("BasePart", true)
		end
		if root and not seen[root] then
			seen[root] = true
			table.insert(roots, root)
		end
	end
	return roots
end

local function sanitize(instance: Instance)
	for _, descendant in instance:GetDescendants() do
		if
			descendant:IsA("LuaSourceContainer")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent")
			or descendant:IsA("BindableFunction")
			or descendant:IsA("ClickDetector")
			or descendant:IsA("ProximityPrompt")
		then
			descendant:Destroy()
		end
	end
end

local function validateAsset(): (boolean, Instance?, string)
	local fieldsValid, fieldError = validateFields()
	if not fieldsValid then
		return false, nil, fieldError
	end
	local numeric, normalized = parseAssetId(assetBox.Text)
	if not numeric then
		return false, nil, "No numeric Roblox asset ID found."
	end
	local assetType = normalizedAssetType()
	if assetType == "model" then
		local ok, loaded = pcall(function()
			return InsertService:LoadAsset(numeric)
		end)
		if not ok or not loaded then
			return false, nil, "Model could not be loaded. Check ownership and experience permissions."
		end
		sanitize(loaded)
		if not loaded:FindFirstChildWhichIsA("BasePart", true) then
			loaded:Destroy()
			return false, nil, "Loaded model contains no BasePart."
		end
		return true, loaded, normalized
	elseif assetType == "mesh" then
		local probe = Instance.new("Part")
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = normalized
		mesh.Parent = probe
		local success = false
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ probe }, function(_, fetchStatus)
				if fetchStatus == Enum.AssetFetchStatus.Success then
					success = true
				end
			end)
		end)
		probe:Destroy()
		return ok and success,
			nil,
			if ok and success
				then normalized
				else "Mesh delivery failed. Upload it under the experience owner/group and grant access."
	end
	return false, nil, "Asset type must be Mesh or Model."
end

local function visualParts(container: Instance): { BasePart }
	local parts = {}
	if container:IsA("BasePart") then
		table.insert(parts, container)
	end
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function prepareVisual(container: Instance, root: BasePart, scale: number, offset: CFrame): boolean
	local parts = visualParts(container)
	if #parts == 0 then
		return false
	end
	local pivot = if container:IsA("Model") then container:GetPivot() else parts[1].CFrame
	for _, part in parts do
		local relative = pivot:ToObjectSpace(part.CFrame)
		part.Size *= scale
		part.CFrame = root.CFrame * offset * CFrame.new(relative.Position * scale) * relative.Rotation
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Name = "ResourceVisualWeld"
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end
	return true
end

local function makeVisual(asset: Instance?, normalized: string, root: BasePart): Instance
	local scale, yOffset, yRotation = parseTransform()
	local offset = CFrame.new(0, yOffset, 0) * CFrame.Angles(0, math.rad(yRotation), 0)
	local candidate: Instance
	if asset then
		candidate = asset:Clone()
	else
		local part = Instance.new("Part")
		part.Name = "MeshVisual"
		part.Size = Vector3.new(2, 2, 2)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = normalized
		-- FIX: Set TextureId to prevent untextured rendering (untextured bug fix)
		-- Extract numeric ID and use it for texture lookup (Roblox often uses matching IDs)
		local numericId = string.match(normalized, "%d+")
		if numericId then
			mesh.TextureId = "rbxassetid://" .. numericId
		end
		mesh.Scale = Vector3.new(scale, scale, scale)
		mesh.Parent = part
		candidate = part
	end
	candidate.Name = "Candidate"
	assert(prepareVisual(candidate, root, if asset then scale else 1, offset), "Visual contains no parts")
	return candidate
end

local function clearPreview()
	local preview = workspace:FindFirstChild("_ResourceVisualPreview")
	if preview then
		preview:Destroy()
	end
end

local function catalogRoot(): Folder
	local catalog = ServerStorage:FindFirstChild("ResourceVisualCatalog")
	if not catalog then
		catalog = Instance.new("Folder")
		catalog.Name = "ResourceVisualCatalog"
		catalog.Parent = ServerStorage
	end
	local entries = catalog:FindFirstChild("Entries")
	if not entries then
		entries = Instance.new("Folder")
		entries.Name = "Entries"
		entries.Parent = catalog
	end
	return catalog :: Folder
end

local function writeCatalogEntry(normalized: string)
	local catalog = catalogRoot()
	local entries = catalog:FindFirstChild("Entries") :: Folder
	local variant = if variantBox.Text ~= "" then variantBox.Text else archetypeBox.Text
	local entry = entries:FindFirstChild(variant) or Instance.new("Configuration")
	entry.Name = variant
	entry:SetAttribute("AssetId", normalized)
	entry:SetAttribute("AssetType", if normalizedAssetType() == "model" then "Model" else "Mesh")
	local scale, yOffset, yRotation = parseTransform()
	entry:SetAttribute("Scale", Vector3.new(scale, scale, scale))
	entry:SetAttribute("Offset", CFrame.new(0, yOffset, 0) * CFrame.Angles(0, math.rad(yRotation), 0))
	entry:SetAttribute("Enabled", true)
	entry.Parent = entries
end

local function getAssetLibraryPrefab(variantId: string): Model?
	if variantId == "" then
		return nil
	end
	local assetLibrary = ServerStorage:FindFirstChild("AssetLibrary")
	if not assetLibrary then
		return nil
	end
	local resourceNodes = assetLibrary:FindFirstChild("ResourceNodes")
	if not resourceNodes then
		return nil
	end
	local prefab = resourceNodes:FindFirstChild(variantId)
	if prefab and prefab:IsA("Model") then
		return prefab
	end
	return nil
end

local function applyToRoot(root: BasePart, loaded: Instance?, normalized: string)
	-- FIX: First check for baked prefab in ServerStorage.AssetLibrary.ResourceNodes (invisible/untextured bug fix)
	local variantId = variantBox.Text
	local prefab = getAssetLibraryPrefab(variantId)
	local candidate: Instance

	if prefab then
		-- Clone the complete baked model from AssetLibrary
		candidate = prefab:Clone()
		candidate.Name = "Candidate"
		-- Prepare it for the root with proper welds and physics.
		-- (Each parenthesized/truncated parseTransform() call below used to
		-- collapse to its first return value, so the offset accidentally
		-- reused `scale` in place of `yOffset` -- compute all three once.)
		local scale, yOffset, yRotation = parseTransform()
		local offset = CFrame.new(0, yOffset, 0) * CFrame.Angles(0, math.rad(yRotation), 0)
		if not prepareVisual(candidate, root, scale, offset) then
			candidate:Destroy()
			candidate = makeVisual(loaded, normalized, root)
		end
	else
		-- Fall back to makeVisual (either from loaded asset or bare mesh)
		candidate = makeVisual(loaded, normalized, root)
	end

	local old = root:FindFirstChild("_ResourceVisual")
	local backup = root:FindFirstChild("_ResourceVisualBackup")
	if backup then
		backup:Destroy()
	end
	if old then
		backup = old:Clone()
		backup.Name = "_ResourceVisualBackup"
		backup.Parent = root
		old:Destroy()
	end
	root:SetAttribute("PreviousVisualAssetId", root:GetAttribute("VisualAssetId"))
	root:SetAttribute("PreviousVisualAssetType", root:GetAttribute("VisualAssetType"))
	root:SetAttribute("PreviousVisualVariant", root:GetAttribute("VisualVariant"))
	root:SetAttribute("PreviousVisualScale", root:GetAttribute("VisualScale"))
	root:SetAttribute("PreviousVisualOffset", root:GetAttribute("VisualOffset"))
	local managed = Instance.new("Folder")
	managed.Name = "_ResourceVisual"
	managed.Parent = root
	candidate.Parent = managed
	if root:GetAttribute("ResourceRootTransparency") == nil then
		root:SetAttribute("ResourceRootTransparency", root.Transparency)
	end
	-- FIX: Only set root.Transparency = 1 AFTER confirming candidate was created successfully (invisible bug fix)
	root.Transparency = 1
	-- FIX: Adjust root size to match the visual's actual extents to fix collision/visual decoupling (collision bug fix)
	-- Calculate the extents of the candidate visual
	local candidateParts = visualParts(candidate)
	if #candidateParts > 0 then
		local minBound = Vector3.new(math.huge, math.huge, math.huge)
		local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, part in candidateParts do
			local size = part.Size / 2
			local cf = part.CFrame
			-- Check all 8 corners of the part's bounding box
			for dx = -1, 1, 2 do
				for dy = -1, 1, 2 do
					for dz = -1, 1, 2 do
						local corner = cf * CFrame.new(size.X * dx, size.Y * dy, size.Z * dz)
						local pos = corner.Position
						minBound = Vector3.new(math.min(minBound.X, pos.X), math.min(minBound.Y, pos.Y), math.min(minBound.Z, pos.Z))
						maxBound = Vector3.new(math.max(maxBound.X, pos.X), math.max(maxBound.Y, pos.Y), math.max(maxBound.Z, pos.Z))
					end
				end
			end
		end
		-- Set root size to match the visual bounds
		if minBound.X ~= math.huge then
			local newSize = maxBound - minBound
			local newCenter = (minBound + maxBound) / 2
			local rootToCenter = newCenter - root.Position
			root.Size = Vector3.new(math.max(newSize.X, 0.2), math.max(newSize.Y, 0.2), math.max(newSize.Z, 0.2))
		end
	end
	root:SetAttribute("ResourceArchetype", archetypeBox.Text)
	root:SetAttribute("VisualVariant", variantBox.Text)
	root:SetAttribute("VisualAssetId", normalized)
	root:SetAttribute("VisualAssetType", if normalizedAssetType() == "model" then "Model" else "Mesh")
	local scale, yOffset, yRotation = parseTransform()
	root:SetAttribute("VisualScale", Vector3.new(scale, scale, scale))
	root:SetAttribute("VisualOffset", CFrame.new(0, yOffset, 0) * CFrame.Angles(0, math.rad(yRotation), 0))
	root:SetAttribute("UseFallbackOnFailure", true)
	root:SetAttribute("RegistryMeshStatus", "authored_validated")
	CollectionService:AddTag(root, "ResourceNode")
end

validateButton.MouseButton1Click:Connect(function()
	local ok, loaded, detail = validateAsset()
	if loaded then
		loaded:Destroy()
	end
	report(if ok then "Valid and deliverable: " .. detail else detail, if ok then nil else "error")
end)

previewButton.MouseButton1Click:Connect(function()
	local roots = selectedRoots()
	if #roots == 0 then
		report("Select a BasePart or Model first.", "warning")
		return
	end
	local ok, loaded, detail = validateAsset()
	if not ok then
		report(detail, "error")
		return
	end
	clearPreview()
	local preview = makeVisual(loaded, detail, roots[1])
	preview.Name = "_ResourceVisualPreview"
	preview.Parent = workspace
	if loaded then
		loaded:Destroy()
	end
	report("Preview created. It is temporary and will not alter harvesting.")
end)

applyButton.MouseButton1Click:Connect(function()
	local roots = selectedRoots()
	if #roots == 0 then
		report("Select at least one resource root.", "warning")
		return
	end
	local ok, loaded, detail = validateAsset()
	if not ok then
		report(detail .. " Existing visuals were preserved.", "error")
		return
	end
	ChangeHistoryService:SetWaypoint("Before resource visual replacement")
	for _, root in roots do
		applyToRoot(root, loaded, detail)
	end
	clearPreview()
	writeCatalogEntry(detail)
	if loaded then
		loaded:Destroy()
	end
	ChangeHistoryService:SetWaypoint("Applied resource visual replacement")
	report(string.format("Applied %s to %d selected node(s).", variantBox.Text, #roots))
end)

replaceAllButton.MouseButton1Click:Connect(function()
	local ok, loaded, detail = validateAsset()
	if not ok then
		report(detail, "error")
		return
	end
	local count = 0
	ChangeHistoryService:SetWaypoint("Before batch resource replacement")
	for _, node in CollectionService:GetTagged("ResourceNode") do
		local root = if node:IsA("BasePart") then node else node:FindFirstChildWhichIsA("BasePart", true)
		local nodeVariant = node:GetAttribute("VisualVariant") or (root and root:GetAttribute("VisualVariant"))
		if root and nodeVariant == variantBox.Text then
			applyToRoot(root, loaded, detail)
			count += 1
		end
	end
	writeCatalogEntry(detail)
	if loaded then
		loaded:Destroy()
	end
	ChangeHistoryService:SetWaypoint("Batch resource replacement")
	report(string.format("Replaced %d node(s) using %s.", count, variantBox.Text))
end)

createButton.MouseButton1Click:Connect(function()
	local roots = selectedRoots()
	for _, root in roots do
		CollectionService:AddTag(root, "ResourceNode")
		root:SetAttribute("ResourceArchetype", archetypeBox.Text)
		root:SetAttribute("VisualVariant", variantBox.Text)
		root:SetAttribute("UseFallbackOnFailure", true)
	end
	ChangeHistoryService:SetWaypoint("Configured resource nodes")
	report(string.format("Configured %d ResourceNode root(s).", #roots))
end)

restoreButton.MouseButton1Click:Connect(function()
	local count = 0
	for _, root in selectedRoots() do
		local backup = root:FindFirstChild("_ResourceVisualBackup")
		if backup then
			local current = root:FindFirstChild("_ResourceVisual")
			if current then
				current:Destroy()
			end
			backup.Name = "_ResourceVisual"
			root:SetAttribute("VisualAssetId", root:GetAttribute("PreviousVisualAssetId"))
			root:SetAttribute("VisualAssetType", root:GetAttribute("PreviousVisualAssetType"))
			root:SetAttribute("VisualVariant", root:GetAttribute("PreviousVisualVariant"))
			root:SetAttribute("VisualScale", root:GetAttribute("PreviousVisualScale"))
			root:SetAttribute("VisualOffset", root:GetAttribute("PreviousVisualOffset"))
			count += 1
		end
	end
	ChangeHistoryService:SetWaypoint("Restored resource visuals")
	report(string.format("Restored %d previous visual(s).", count), if count > 0 then nil else "warning")
end)

fallbackButton.MouseButton1Click:Connect(function()
	for _, root in selectedRoots() do
		local visual = root:FindFirstChild("_ResourceVisual")
		if visual then
			visual:Destroy()
		end
		root:SetAttribute("VisualAssetId", nil)
		root:SetAttribute("VisualAssetType", "Fallback")
		root:SetAttribute("RegistryMeshStatus", "fallback_requested")
	end
	ChangeHistoryService:SetWaypoint("Requested resource fallbacks")
	report("Selected nodes will use their safe procedural fallback in Play mode.")
end)

diagnosticsButton.MouseButton1Click:Connect(function()
	local total, missing, failed = 0, 0, 0
	for _, node in CollectionService:GetTagged("ResourceNode") do
		total += 1
		if not node:GetAttribute("ResourceArchetype") then
			missing += 1
		end
		local nodeStatus = node:GetAttribute("RegistryMeshStatus")
		if nodeStatus == "fallback" or nodeStatus == "error" then
			failed += 1
		end
	end
	report(
		string.format("%d resources: %d missing archetypes, %d currently failed/fallback.", total, missing, failed),
		if missing + failed > 0 then "warning" else nil
	)
end)

exportButton.MouseButton1Click:Connect(function()
	local entries = catalogRoot():FindFirstChild("Entries")
	local snapshot = {}
	for _, entry in if entries then entries:GetChildren() else {} do
		local scale = entry:GetAttribute("Scale")
		local offset = entry:GetAttribute("Offset")
		snapshot[entry.Name] = {
			assetId = entry:GetAttribute("AssetId"),
			assetType = entry:GetAttribute("AssetType"),
			scale = if typeof(scale) == "Vector3" then { scale.X, scale.Y, scale.Z } else { 1, 1, 1 },
			offset = if typeof(offset) == "CFrame"
				then { offset:GetComponents() }
				else { CFrame.identity:GetComponents() },
			enabled = entry:GetAttribute("Enabled") ~= false,
		}
	end
	catalogBox.Text = HttpService:JSONEncode(snapshot)
	plugin:SetSetting("ResourceVisualCatalogSnapshot", catalogBox.Text)
	report("Catalog exported below and backed up in plugin settings.")
end)

importButton.MouseButton1Click:Connect(function()
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(catalogBox.Text)
	end)
	if not ok or type(decoded) ~= "table" then
		report("Catalog JSON is invalid.", "error")
		return
	end
	local entries = catalogRoot():FindFirstChild("Entries") :: Folder
	for variant, data in decoded do
		if type(variant) == "string" and type(data) == "table" then
			local entry = entries:FindFirstChild(variant) or Instance.new("Configuration")
			entry.Name = variant
			entry:SetAttribute("AssetId", data.assetId)
			entry:SetAttribute("AssetType", data.assetType or "Mesh")
			entry:SetAttribute("Enabled", data.enabled ~= false)
			if type(data.scale) == "table" and #data.scale == 3 then
				entry:SetAttribute("Scale", Vector3.new(data.scale[1], data.scale[2], data.scale[3]))
			end
			if type(data.offset) == "table" and #data.offset == 12 then
				entry:SetAttribute("Offset", CFrame.new(table.unpack(data.offset)))
			end
			entry.Parent = entries
		end
	end
	ChangeHistoryService:SetWaypoint("Imported resource visual catalog")
	report("Catalog imported. Validate assets before applying them.")
end)

toolbarButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not widget.Enabled then
		clearPreview()
	end
end)

plugin.Unloading:Connect(clearPreview)

Selection.SelectionChanged:Connect(function()
	local roots = selectedRoots()
	if #roots == 1 then
		local root = roots[1]
		archetypeBox.Text = root:GetAttribute("ResourceArchetype") or archetypeBox.Text
		variantBox.Text = root:GetAttribute("VisualVariant") or variantBox.Text
		assetBox.Text = root:GetAttribute("VisualAssetId") or assetBox.Text
		typeBox.Text = root:GetAttribute("VisualAssetType") or typeBox.Text
	end
end)

local savedSnapshot = plugin:GetSetting("ResourceVisualCatalogSnapshot")
if type(savedSnapshot) == "string" then
	catalogBox.Text = savedSnapshot
end
