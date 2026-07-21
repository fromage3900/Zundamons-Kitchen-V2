return {
	name = "Glow",
	apply = function(instance, params)
		if not instance:IsA("BasePart") then return end
		if instance:FindFirstChild("_modGlow") then return end
		local light = Instance.new("PointLight")
		light.Name = "_modGlow"
		light.Brightness = params.brightness or 1.5
		light.Range = params.range or 8
		light.Color = params.color or Color3.fromRGB(200, 230, 255)
		light.Parent = instance
		if params.sparkles then
			local pe = Instance.new("ParticleEmitter")
			pe.Name = "_modGlowPE"
			pe.Texture = "rbxassetid://241685484"
			pe.Rate = params.sparkleRate or 5
			pe.Lifetime = NumberRange.new(0.5, 1.5)
			pe.Speed = NumberRange.new(1, 3)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Parent = instance
		end
	end,
	revert = function(instance)
		local light = instance:FindFirstChild("_modGlow")
		if light then light:Destroy() end
		local pe = instance:FindFirstChild("_modGlowPE")
		if pe then pe:Destroy() end
	end,
}
