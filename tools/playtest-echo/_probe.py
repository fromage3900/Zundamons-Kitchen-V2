import json, mcp_call
code = '''
local RS = game:GetService("ReplicatedStorage")
local result = {}
result.tutAdvance = RS:FindFirstChild("TutorialAdvance") ~= nil
result.peaGuard = _G._PeaWheelVerified ~= nil
result.onboarding = game.Players.LocalPlayer:GetAttribute("OnboardingActive")
return result
'''
out = json.loads(mcp_call.call("execute_luau", {"code": code, "instance_id": "place:102953611950557", "role": "client-1"}))
print("client-1:", out["returnValue"])
