--!strict
-- One-time Studio migration helper. Dry-run by default; runtime systems never
-- depend on these legacy object names.

local CollectionService = game:GetService("CollectionService")

local Migration = {}

local legacy: { [string]: { archetype: string, variant: string } } = {
	Loop_AppleTree_1 = { archetype = "AppleTree", variant = "Variant1" },
	Loop_AppleTree_2 = { archetype = "AppleTree", variant = "Variant2" },
	Loop_Rock_1 = { archetype = "Rock", variant = "Rock_Common" },
	Loop_Rock_2 = { archetype = "Rock", variant = "Rock_Rare" },
	Loop_GoldRock_1 = { archetype = "GoldRock", variant = "GoldOre_Default" },
	Loop_Wheat_1 = { archetype = "Wheat", variant = "Wheat_01" },
	Loop_Wheat_2 = { archetype = "Wheat", variant = "Wheat_02" },
	Loop_Wheat_3 = { archetype = "Wheat", variant = "Wheat_03" },
}

function Migration.run(applyChanges: boolean?): { string }
	local report = {}
	for _, instance in workspace:GetDescendants() do
		local definition = legacy[instance.Name]
		if definition and instance:IsA("BasePart") then
			table.insert(
				report,
				string.format("%s -> %s/%s", instance:GetFullName(), definition.archetype, definition.variant)
			)
			if applyChanges == true then
				instance:SetAttribute("ResourceArchetype", definition.archetype)
				instance:SetAttribute("VisualVariant", definition.variant)
				instance:SetAttribute("VisualAssetType", "Fallback")
				instance:SetAttribute("UseFallbackOnFailure", true)
				CollectionService:AddTag(instance, "ResourceNode")
			end
		end
	end
	table.sort(report)
	print(
		string.format(
			"[MigrateResourceVisuals] %s %d node(s)",
			if applyChanges then "migrated" else "would migrate",
			#report
		)
	)
	for _, line in report do
		print("  " .. line)
	end
	return report
end

return Migration
