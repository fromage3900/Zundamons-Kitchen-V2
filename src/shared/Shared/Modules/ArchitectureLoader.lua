--!strict
-- ArchitectureLoader: resolves architecture asset configs and provides helper access.

local ArchitectureVariants = require(script.Parent.Config.ArchitectureVariants)
local ArchitecturePipeline = require(script.Parent.Config.ArchitecturePipeline)

local ArchitectureLoader = {}

function ArchitectureLoader.getVariantMesh(category: string, entryName: string, variantId: string): string
	local cat = ArchitectureVariants[category]
	if not cat then
		return ""
	end
	local entry = cat[entryName]
	if not entry or not entry.meshes then
		return ""
	end
	return entry.meshes[variantId] or ""
end

function ArchitectureLoader.getPipelineEntry(category: string, entryName: string)
	local cat = ArchitecturePipeline[category]
	if not cat then
		return nil
	end
	return cat[entryName]
end

function ArchitectureLoader.getPipelineVariants(category: string, entryName: string)
	local entry = ArchitectureLoader.getPipelineEntry(category, entryName)
	if not entry then
		return {}
	end
	return entry.variants or {}
end

return ArchitectureLoader
