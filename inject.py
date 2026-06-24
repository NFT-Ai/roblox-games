import os
import json

base_dir = "/Users/mario/Desktop/TEO/Roblox/NEW/src/scripts"

def get_content(filename):
    with open(os.path.join(base_dir, filename), "r") as f:
        return f.read()

combat = get_content("CombatHandler.server.lua")
wallclick = get_content("WallClickClient.client.lua")
spawner = get_content("NPCSpawner.lua")
ragdoll = get_content("Ragdoll.lua")
animator = get_content("NPCAnimator.lua")

def escape_luau(s):
    # Escape using long string format [=[...]=] to avoid issues with standard [[...]]
    return "[=[" + s + "]=]"

luau_code = f"""
local ss = game:GetService("ServerScriptService")
local rs = game:GetService("StarterPlayer").StarterPlayerScripts

local combat = ss:FindFirstChild("CombatHandler")
if combat then combat.Source = {escape_luau(combat)} end

local client = rs:FindFirstChild("WallClickClient")
if client then client.Source = {escape_luau(wallclick)} end

local mods = ss:FindFirstChild("Modules")
if mods then
    local spawner = mods:FindFirstChild("NPCSpawner")
    if spawner then spawner.Source = {escape_luau(spawner)} end
    
    local ragdoll = mods:FindFirstChild("Ragdoll")
    if ragdoll then ragdoll.Source = {escape_luau(ragdoll)} end
    
    local animator = mods:FindFirstChild("NPCAnimator")
    if animator then animator.Source = {escape_luau(animator)} end
end

return "Injected"
"""

# We don't have direct MCP tool access in Python here, but I can print the payload
# and save it to a file, then use it.
with open("/Users/mario/Desktop/TEO/Roblox/NEW/payload.lua", "w") as f:
    f.write(luau_code)
