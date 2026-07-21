-- [[Script] Sprint on shift (ref: RBX728D18D572D84B6D850A53D009E8CB2A)]]
function onPlayerEntered(player)
	repeat wait () until player.Character ~= nil
	local s = script.SprintScript:clone()
	s.Parent = player.Character
	s.Disabled = false
	player.CharacterAdded:connect(function (char)
		local s = script.SprintScript:clone()
		s.Parent = char
		s.Disabled = false		
	end)
end

game.Players.PlayerAdded:connect(onPlayerEntered)

--Fozetts was here--