-- [[LocalScript] CreateLoot (ref: RBXD51D572F5F124B6E9C169FE1BC2E8E5D)]]
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local RF = RS:WaitForChild("RemoteFunctions")
local remoteEvent = RE:WaitForChild("MakeLootEvent")
local giveloot = RF:WaitForChild("GiveLoot")
local removeCode = RE:WaitForChild("RemoveCode")
local loot = RS:FindFirstChild("Loot") or RS:WaitForChild("Loot", 5)
local lootCommons = RS:FindFirstChild("LootCommons")
local lootBB = lootCommons and lootCommons:FindFirstChild("LootBB")
local GW = game:GetService("Workspace")
local LocalSounds = GW:FindFirstChild("LocalSounds")
local StarterGui = game:GetService("StarterGui")
local lootfolder = GW:FindFirstChild("LootFolder")
local TweenService = game:GetService("TweenService")

local icons = {
	Money = "rbxassetid://6679028840",
	Armor = "rbxassetid://6679189765",
	Weapon = "rbxassetid://6289027181",
	Life = "rbxassetid://6475510801",
	Potion = "rbxassetid://6679052417",
	Boost = "rbxassetid://6296361480",
	Key = "rbxassetid://6679078910",
	Material = "rbxassetid://6879525567",
	Consumable = "rbxassetid://7197382093",
	Explosive = "rbxassetid://7635304803"
}

local function CreateNotification(Title, Text, ObjType, image)
	local myicon = nil
	if not image or image == "" then
		myicon = icons[ObjType] or ""
	else
		myicon = image
	end
	StarterGui:SetCore("SendNotification", {Title = Title, Text = Text, Icon = myicon, Duration = 5})
end

local function destroy(item, code)
	if item then
		removeCode:FireServer(code, item.Name, true)
		item:Destroy()
	end
end

local function tweenPoint(targetPart, parentObj)
	if not targetPart then return end
	-- Add a trail to two attachments
	local a0 = Instance.new("Attachment", targetPart)
	a0.Position = Vector3.new(1, 0, 0)
	local a1 = Instance.new("Attachment", targetPart)
	a1.Position = Vector3.new(-1, 0, 0)
	local trail = Instance.new("Trail", targetPart)
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.35

	local startPos = targetPart.Position
	local x_add = math.random(-10, 10)
	local y_add = math.random(-10, 10)
	local endPos = startPos + Vector3.new(x_add, 0, y_add)
	local arcHeight = 5
	local travelTime = 0.25
	local xzGoal = {Position = Vector3.new(endPos.X, startPos.Y, endPos.Z)}
	local xzTweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
	local xzTween = TweenService:Create(targetPart, xzTweenInfo, xzGoal)
	xzTween:Play()
	local midY = startPos.Y + arcHeight

	local upTween = TweenService:Create(targetPart, TweenInfo.new(travelTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = Vector3.new(startPos.X + (x_add / 2), midY, startPos.Z + (y_add / 2))
	})

	local downTween = TweenService:Create(targetPart, TweenInfo.new(travelTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Position = Vector3.new(endPos.X, endPos.Y, endPos.Z)
	})

	upTween:Play()
	upTween.Completed:Connect(function()
		downTween:Play()
		downTween.Completed:Connect(function()
			targetPart:SetAttribute("TweenEnd", true)
			if parentObj then parentObj:SetAttribute("TweenEnd", true) end
		end)
	end)
end

local function makeLootLocal(myloot, position, generatedCode, quality)
	local objloot = loot and loot:FindFirstChild(myloot)
	local obj: Instance
	local mainPart: BasePart

	if objloot then
		obj = objloot:Clone()
	else
		-- Fallback colored Part for missing loot templates
		local part = Instance.new("Part")
		part.Name = myloot
		part.Size = Vector3.new(1.2, 1.2, 1.2)
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(130, 210, 140)
		obj = part
	end

	if obj:IsA("Model") then
		obj:PivotTo(CFrame.new(position))
		for _, desc in ipairs(obj:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end
		mainPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
		if not mainPart then
			mainPart = Instance.new("Part")
			mainPart.Name = "MainPart"
			mainPart.Size = Vector3.new(1, 1, 1)
			mainPart.Position = position
			mainPart.Transparency = 1
			mainPart.Anchored = true
			mainPart.CanCollide = false
			mainPart.Parent = obj
			obj.PrimaryPart = mainPart
		end
	else
		mainPart = obj :: BasePart
		mainPart.Position = position
		mainPart.Anchored = true
		mainPart.CanCollide = false
		mainPart.Transparency = 0
	end

	obj.Parent = lootfolder or workspace

	-- Store quality on crafted food items for serving
	if quality and quality ~= "" then
		obj:SetAttribute("Quality", quality)
		obj:SetAttribute("Recipe", myloot)
	end

	tweenPoint(mainPart, obj)

	if lootBB then
		local lootBBClone = lootBB:Clone()
		local lootLabel = lootBBClone:FindFirstChild("LootFrame") and lootBBClone.LootFrame:FindFirstChild("LootLabel")
		if lootLabel then lootLabel.Text = myloot end
		lootBBClone.Parent = mainPart
	end

	local function onTouch(hit)
		local character = hit.Parent
		if not character then return end
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local player = game.Players.LocalPlayer
			local isTouched = obj:GetAttribute("isTouched") or mainPart:GetAttribute("isTouched")
			local tweenEnd = obj:GetAttribute("TweenEnd") or mainPart:GetAttribute("TweenEnd")
			if player.Character == character and not isTouched and tweenEnd then
				obj:SetAttribute("isTouched", true)
				mainPart:SetAttribute("isTouched", true)
				local given = giveloot:InvokeServer(myloot, generatedCode)
				if given then
					local mysound = obj:GetAttribute("Sound") or mainPart:GetAttribute("Sound")
					if mysound and LocalSounds then
						local sound = LocalSounds:FindFirstChild(mysound)
						if sound then sound:Play() end
					end
					local myType = obj:GetAttribute("Type") or obj:GetAttribute("SubType") or "Material"
					local image = nil
					local texture = obj:FindFirstChild("Texture") or mainPart:FindFirstChild("Texture")
					if texture and texture:IsA("StringValue") then
						image = texture.Value
					end
					CreateNotification(myType .. " Collected", "Picked up " .. myType .. ": " .. obj.Name, myType, image)
					destroy(obj, generatedCode)
				else
					if LocalSounds then
						local sound = LocalSounds:FindFirstChild("Fail")
						if sound then sound:Play() end
					end
					obj:SetAttribute("isTouched", false)
					mainPart:SetAttribute("isTouched", false)
				end
			end
		end
	end

	if obj:IsA("Model") then
		for _, desc in ipairs(obj:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Touched:Connect(onTouch)
			end
		end
	else
		mainPart.Touched:Connect(onTouch)
	end

	task.wait(60)
	destroy(obj, generatedCode)
end

remoteEvent.OnClientEvent:Connect(makeLootLocal)
