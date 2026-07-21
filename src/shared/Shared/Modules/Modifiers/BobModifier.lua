return {
	name = "Bob",
	apply = function(instance, params)
		instance:SetAttribute("_mod_bobPhase", params.phase or 0)
		instance:SetAttribute("_mod_bobHeight", params.height or 0.5)
		instance:SetAttribute("_mod_bobSpeed", params.speed or 1.2)
		instance:SetAttribute("_mod_bobOrigPos", instance.Position)
	end,
	update = function(instance, params, dt)
		local height = instance:GetAttribute("_mod_bobHeight") or 0.5
		local speed = instance:GetAttribute("_mod_bobSpeed") or 1.2
		local phase = (instance:GetAttribute("_mod_bobPhase") or 0) + dt * speed
		instance:SetAttribute("_mod_bobPhase", phase)
		local origPos = instance:GetAttribute("_mod_bobOrigPos") or instance.Position
		local yOffset = math.sin(phase * math.pi * 2) * height
		instance.Position = Vector3.new(origPos.X, origPos.Y + yOffset, origPos.Z)
	end,
	revert = function(instance)
		local origPos = instance:GetAttribute("_mod_bobOrigPos")
		if origPos then instance.Position = origPos end
	end,
}
