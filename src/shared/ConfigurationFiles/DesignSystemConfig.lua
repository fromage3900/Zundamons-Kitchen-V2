-- DEPRECATED: Use UIConfig.lua instead. This file re-exports UIConfig for backward compatibility.
-- All design tokens should be accessed via UIConfig, not DesignSystemConfig.

local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

-- Create a proxy table that forwards all access to UIConfig
local DesignSystemConfig = setmetatable({}, {
    __index = function(self, key)
        warn("[DesignSystemConfig] Deprecated! Use UIConfig instead. Accessing: " .. key)
        return UIConfig[key]
    end,
    __newindex = function(self, key, value)
        warn("[DesignSystemConfig] Deprecated! Cannot modify. Use UIConfig instead. Setting: " .. key)
        -- Silently ignore writes to prevent errors
    end
})

return DesignSystemConfig
