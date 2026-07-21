return {
	name = "Color",
	apply = function(instance, params)
		if not instance:IsA("BasePart") then return end
		local origColor = instance:GetAttribute("_mod_origColor")
		if not origColor then
			instance:SetAttribute("_mod_origColor", { instance.Color.R, instance.Color.G, instance.Color.B })
		end
		instance.Color = params.color or Color3.fromRGB(255, 200, 100)
		if params.transparency then
			instance.Transparency = params.transparency
		end
	end,
	revert = function(instance)
		if not instance:IsA("BasePart") then return end
		local origColor = instance:GetAttribute("_mod_origColor")
		if origColor then
			instance.Color = Color3.fromRGB(origColor[1] * 255, origColor[2] * 255, origColor[3] * 255)
		end
		instance.Transparency = 0
	end,
}
