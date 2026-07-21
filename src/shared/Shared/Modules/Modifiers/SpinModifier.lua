return {
	name = "Spin",
	apply = function(instance, params)
		instance:SetAttribute("_mod_spinSpeed", params.speed or 30)
		instance:SetAttribute("_mod_spinAngle", 0)
		instance:SetAttribute("_mod_spinOrigCF", instance.CFrame)
	end,
	update = function(instance, params, dt)
		local speed = instance:GetAttribute("_mod_spinSpeed") or 30
		local angle = (instance:GetAttribute("_mod_spinAngle") or 0) + speed * dt
		instance:SetAttribute("_mod_spinAngle", angle)
		local origCF = instance:GetAttribute("_mod_spinOrigCF") or instance.CFrame
		instance.CFrame = origCF * CFrame.Angles(0, math.rad(angle), 0)
	end,
	revert = function(instance)
		local origCF = instance:GetAttribute("_mod_spinOrigCF")
		if origCF then instance.CFrame = origCF end
	end,
}
