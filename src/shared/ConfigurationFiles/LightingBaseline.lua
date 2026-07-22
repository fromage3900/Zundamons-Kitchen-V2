local LightingBaseline = {}

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

function LightingBaseline.snapshot()
	local data = {
		lighting = {},
		atmosphere = {},
		sky = {},
		workspace = {},
		effects = {},
	}

	local props = {
		"Ambient", "Brightness", "ColorShift_Top", "ColorShift_Bottom",
		"EnvironmentDiffuseScale", "EnvironmentSpecularScale",
		"ExposureCompensation", "FogColor", "FogEnd", "FogStart",
		"GlobalShadows", "ShadowSoftness", "ClockTime", "GeographicLatitude",
		"OutdoorAmbient",
	}
	for _, p in ipairs(props) do
		data.lighting[p] = Lighting[p]
	end

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") then
			local a = data.atmosphere
			a.Color = child.Color
			a.Decay = child.Decay
			a.Density = child.Density
			a.Glare = child.Glare
			a.Haze = child.Haze
			a.Offset = child.Offset
		elseif child:IsA("Sky") then
			local s = data.sky
			for _, p in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp",
				"SunAngularSize","MoonAngularSize","StarCount","CelestialBodiesShown",
				"SunTextureId","MoonTextureId"}) do
				s[p] = child[p]
			end
		elseif child:IsA("BloomEffect") or child:IsA("SunRaysEffect")
			or child:IsA("ColorCorrectionEffect") or child:IsA("BlurEffect")
			or child:IsA("DepthOfFieldEffect") then
			local eid = child.ClassName .. "_" .. child.Name
			data.effects[eid] = {}
			for _, p in ipairs(child:GetProperties()) do
				local ok, val = pcall(function() return child[p.Name] end)
				if ok then
					data.effects[eid][p.Name] = val
				end
			end
		end
	end

	data.workspace.GlobalWind = Workspace.GlobalWind

	return data
end

function LightingBaseline.restore(data)
	if not data then return end

	for p, v in pairs(data.lighting) do
		pcall(function() Lighting[p] = v end)
	end

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") and data.atmosphere then
			for p, v in pairs(data.atmosphere) do
				pcall(function() child[p] = v end)
			end
		elseif child:IsA("Sky") and data.sky then
			for p, v in pairs(data.sky) do
				pcall(function() child[p] = v end)
			end
		elseif data.effects then
			local eid = child.ClassName .. "_" .. child.Name
			if data.effects[eid] then
				for p, v in pairs(data.effects[eid]) do
					pcall(function() child[p] = v end)
				end
			end
		end
	end

	pcall(function() Workspace.GlobalWind = data.workspace.GlobalWind end)
end

return LightingBaseline
