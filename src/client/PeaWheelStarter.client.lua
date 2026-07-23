-- [[LocalScript] PeaWheelStarter]]
-- Initializes the Pea Wheel radial menu. Must be a LocalScript (not ModuleScript)
-- so it runs as a top-level script in StarterPlayerScripts.
local PeaWheelController = require(script.Parent.Controllers.PeaWheelController)

-- The PeaWheelController builds its GUI lazily on first open/toggle.
-- We just need to require it so the module initializes and wires its InputBegan listener.
print("[PeaWheelStarter] PeaWheelController loaded — wheel ready on Tab/G key")