-- [[LocalScript] LocalTools (ref: RBX51B35FCBF01947F8BAB60016A1D5A51B)]]
local CollectionService = game:GetService("CollectionService")
local RS = game.ReplicatedStorage
local remotes = RS:WaitForChild("ToolRemotes")
local ConnectFunction = remotes:WaitForChild("ConnectFunction")


function addFunction()
	for _, tool in ipairs(CollectionService:GetTagged("Tool")) do
		local shoot 
		local used = 0
		local MyMouse = nil

		local function Activated()
			local finished = false
			if used == 0 then
				used = 1
				if MyMouse then
					finished = ConnectFunction:InvokeServer(tool.Name) 
				end
				used = 0
			end
			return finished
		end

		local function CallDeactivated()
			shoot = false
		end

		local function CallActivated()
			shoot = true
			while shoot do
				local resp = Activated()
				task.wait(0.25)
			end
		end

		local function OnEquipped(mouse)
			MyMouse = mouse
			MyMouse.Button1Down:Connect(CallActivated)
			MyMouse.Button1Up:Connect(CallDeactivated)
		end

		local function OnUnEquipped()
			shoot = false
		end

		tool.Equipped:connect(OnEquipped)
	end
end

addFunction()
