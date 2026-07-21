return {
	name = "Scale",
	apply = function(instance, params)
		local scale = params.scale or 1.5
		local origSize = instance:GetAttribute("_mod_origSize") or instance.Size
		instance:SetAttribute("_mod_origSize", origSize)
		instance.Size = origSize * scale
	end,
	revert = function(instance)
		local origSize = instance:GetAttribute("_mod_origSize")
		if origSize then instance.Size = origSize end
	end,
}
