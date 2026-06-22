import sys
import json
import urllib.request

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

client_script = read_file('/Users/mario/.gemini/antigravity/scratch/roblox-games/src/StarterGui/MapEditor.client.lua')
server_script = read_file('/Users/mario/.gemini/antigravity/scratch/roblox-games/src/ServerScriptService/SetupLevel2D.server.lua')
map_data = read_file('/Users/mario/.gemini/antigravity/scratch/roblox-games/src/ServerScriptService/MapData.lua')
preloader = read_file('/Users/mario/.gemini/antigravity/scratch/roblox-games/src/ReplicatedFirst/ImagePreloader.client.lua')
side_camera = read_file('/Users/mario/.gemini/antigravity/scratch/roblox-games/src/StarterPlayerScripts/SideCamera.client.lua')
movement = read_file('/Users/mario/.gemini/antigravity/scratch/roblox-games/src/StarterCharacterScripts/Movement2D.client.lua')

luau_code = """
local StarterGui = game:GetService("StarterGui")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Wyczyść stare instancje, aby zapobiec dublowaniu
if StarterGui:FindFirstChild("MapEditor") then StarterGui.MapEditor:Destroy() end
if ServerScriptService:FindFirstChild("SetupLevel2D") then ServerScriptService.SetupLevel2D:Destroy() end
if ServerScriptService:FindFirstChild("MapData") then ServerScriptService.MapData:Destroy() end
if ReplicatedFirst:FindFirstChild("ImagePreloader") then ReplicatedFirst.ImagePreloader:Destroy() end
if StarterPlayer.StarterPlayerScripts:FindFirstChild("SideCamera") then StarterPlayer.StarterPlayerScripts.SideCamera:Destroy() end
if StarterPlayer.StarterCharacterScripts:FindFirstChild("Movement2D") then StarterPlayer.StarterCharacterScripts.Movement2D:Destroy() end

local function createScript(parent, className, name, source)
    local s = Instance.new(className)
    s.Name = name
    s.Source = source
    s.Parent = parent
    return s
end

createScript(StarterGui, "LocalScript", "MapEditor", [====[""" + client_script + """]====])
createScript(ServerScriptService, "Script", "SetupLevel2D", [====[""" + server_script + """]====])
createScript(ServerScriptService, "ModuleScript", "MapData", [====[""" + map_data + """]====])
createScript(ReplicatedFirst, "LocalScript", "ImagePreloader", [====[""" + preloader + """]====])
createScript(StarterPlayer.StarterPlayerScripts, "LocalScript", "SideCamera", [====[""" + side_camera + """]====])
createScript(StarterPlayer.StarterCharacterScripts, "LocalScript", "Movement2D", [====[""" + movement + """]====])

return "All scripts successfully injected directly to Studio!"
"""

with open('payload.lua', 'w') as f:
    f.write(luau_code)
