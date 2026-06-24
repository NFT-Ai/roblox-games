import os
import json

with open("/Users/mario/Desktop/TEO/Roblox/NEW/src/scripts/Ragdoll.lua", "r") as f:
    content = f.read()

def escape_luau(s):
    return "[=[" + s + "]=]"

luau_code = f"""
local ss = game:GetService("ServerScriptService")
local mods = ss:FindFirstChild("Modules")
if mods then
    local ragdoll = mods:FindFirstChild("Ragdoll")
    if ragdoll then ragdoll.Source = {escape_luau(content)} end
end
return "Injected Ragdoll!"
"""

with open("/Users/mario/Desktop/TEO/Roblox/NEW/payload_ragdoll.lua", "w") as f:
    f.write(luau_code)
