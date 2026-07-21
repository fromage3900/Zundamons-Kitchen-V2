-- [[LocalScript] CreateLoot (ref: RBXD51D572F5F124B6E9C169FE1BC2E8E5D)]]
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local RF = RS:WaitForChild("RemoteFunctions")
local remoteEvent = RE:WaitForChild("MakeLootEvent")
local giveloot = RF:WaitForChild("GiveLoot")
local removeCode = RE:WaitForChild("RemoveCode")
local loot = RS:WaitForChild("Loot")
local lootCommons = RS:WaitForChild("LootCommons")
local lootBB = lootCommons:WaitForChild("LootBB")
local GW = game:GetService("Workspace")
local LocalSounds = GW:WaitForChild("LocalSounds")
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

function CreateNotification(Title, Text, ObjType, image)
	local myicon = nil
	if not image or image == "" then
		myicon = icons[ObjType] or ""
	else
		myicon = image
	end
	StarterGui:SetCore("SendNotification", {Title = Title, Text = Text, Icon = myicon, Duration = 5})
end

function destroy(item, code)
	if item then
		removeCode:FireServer(code, item.Name, true)
		item:Destroy()
	end
end

function tweenPoint(part)
	-- Add a trail to two attachments
	local a0 = Instance.new("Attachment", part)
	a0.Position = Vector3.new(1, 0, 0)
	local a1 = Instance.new("Attachment", part)
	a1.Position = Vector3.new(-1, 0, 0)
	local trail = Instance.new("Trail", part)
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.35

	local startPos = part.Position
	local x_add = math.random(-10, 10)
	local y_add = math.random(-10, 10)
	local endPos = startPos + Vector3.new(x_add, 0, y_add)
	local arcHeight = 5
	local travelTime = 0.25
	local xzGoal = {Position = Vector3.new(endPos.X, startPos.Y, endPos.Z)}
	local xzTweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
	local xzTween = TweenService:Create(part, xzTweenInfo, xzGoal)
	xzTween:Play()
	local midY = startPos.Y + arcHeight

	local upTween = TweenService:Create(part, TweenInfo.new(travelTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = Vector3.new(startPos.X + (x_add / 2), midY, startPos.Z + (y_add / 2))
	})

	local downTween = TweenService:Create(part, TweenInfo.new(travelTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Position = Vector3.new(endPos.X, endPos.Y, endPos.Z)
	})

	upTween:Play()
	upTween.Completed:Connect(function()
		downTween:Play()
		downTween.Completed:Connect(function()
			part:SetAttribute("TweenEnd", true)
		end)
	end)
end

function makeLootLocal(myloot, position, generatedCode, quality)
	--print(myloot, position, generatedCode, quality)
	local objloot = loot:WaitForChild(myloot)
	local obj = objloot:Clone()
	obj.Position = position
	obj.Anchored = true
	obj.CanCollide = false
	obj.Transparency = 0
	obj.Parent = lootfolder or workspace

	-- Store quality on crafted food items for serving
	if quality and quality ~= "" then
		obj:SetAttribute("Quality", quality)
		obj:SetAttribute("Recipe", myloot)
	end

	tweenPoint(obj)
	local lootBBClone = lootBB:Clone()
	lootBBClone.LootFrame.LootLabel.Text = myloot
	lootBBClone.Parent = obj

	obj.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local player = game.Players.LocalPlayer
			if player.Character == character and not obj:GetAttribute("isTouched") and obj:GetAttribute("TweenEnd") then
				obj:SetAttribute("isTouched", true)
				local given = giveloot:InvokeServer(myloot, generatedCode)
				if given then
					local mysound = obj:GetAttribute("Sound")
					if mysound then
						local sound = LocalSounds:WaitForChild(mysound)
						sound:Play()
					end
					local myType = obj:GetAttribute("Type") or obj:GetAttribute("SubType")
					local image = nil
					local texture = obj:FindFirstChild("Texture")
					if texture then
						image = texture.Value
					end
					CreateNotification(myType .. " Collected", "Picked up " .. myType .. ": " .. obj.Name, myType, image)
					destroy(obj, generatedCode)
				else
					local sound = LocalSounds:WaitForChild("Fail")
					sound:Play()
					obj:SetAttribute("isTouched", false)
				end
			end
		end
	end)
	task.wait(60)
	destroy(obj, generatedCode)
end

remoteEvent.OnClientEvent:Connect(makeLootLocal)