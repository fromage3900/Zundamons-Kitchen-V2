-- Client-side Rojo sync banner (check Output when you press Play).

local RS = game:GetService("ReplicatedStorage")
local SyncConfig = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("SyncConfig"))

print("[ROJO SYNC OK] Client — " .. SyncConfig.label)
print("[ROJO SYNC OK] Expect [LegacyOverlayCleanup] and [DisclaimerGate] below")
