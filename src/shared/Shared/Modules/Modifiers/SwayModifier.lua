return {
	name = "Sway",
	apply = function(instance, params)
		instance:SetAttribute("_mod_swayStrength", params.strength or 0.3)
		instance:SetAttribute("_mod_swaySpeed", params.speed or 1.5)
		instance:SetAttribute("_mod_swayPhase", 0)
		instance:SetAttribute("_mod_swayOrigPos", instance.Position)
	end,
	update = function(instance, params, dt)
		local strength = instance:GetAttribute("_mod_swayStrength") or 0.3
		local speed = instance:GetAttribute("_mod_swaySpeed") or 1.5
		local phase = (instance:GetAttribute("_mod_swayPhase") or 0) + dt * speed
		instance:SetAttribute("_mod_swayPhase", phase)
		local origPos = instance:GetAttribute("_mod_swayOrigPos") or instance.Position
		local xOff = math.sin(phase * 2.1) * strength
		local zOff = math.cos(phase * 1.7) * strength
		instance.Position = Vector3.new(origPos.X + xOff, origPos.Y, origPos.Z + zOff)
	end,
	revert = function(instance)
		local origPos = instance:GetAttribute("_mod_swayOrigPos")
		if origPos then instance.Position = origPos end
	end,
}
