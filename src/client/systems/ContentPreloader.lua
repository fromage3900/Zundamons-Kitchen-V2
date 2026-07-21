local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

-- Infinity Nikki Lens: Lazy Loading
-- We do NOT load everything at startup. We only load what the player is about to see.
local ContentPreloader = {}

-- Preload critical core UI instantly
function ContentPreloader.PreloadCore()
	return Promise.new(function(resolve, reject)
		local coreAssets = {
			-- Example: Loading Screen Background, Core Icons
		}
		
		ContentProvider:PreloadAsync(coreAssets)
		resolve()
	end)
end

-- Lazy load massive datasets (e.g. 500+ clothing textures) only when opening the wardrobe
function ContentPreloader.LazyLoadCategory(categoryFolder)
	return Promise.new(function(resolve, reject)
		print("Lazy loading category:", categoryFolder.Name)
		
		-- In a real scenario, this would yield until the specific folder's assets are loaded
		ContentProvider:PreloadAsync(categoryFolder:GetDescendants())
		resolve()
	end)
end

return ContentPreloader
