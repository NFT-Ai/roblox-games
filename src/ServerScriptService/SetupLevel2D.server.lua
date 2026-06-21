local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- 1. Poprawa oświetlenia dla trybu 2D
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then atmosphere:Destroy() end
Lighting.FogEnd = 1000000
Lighting.FogStart = 1000000
Lighting.Ambient = Color3.fromRGB(200, 200, 200)
Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
Lighting.GlobalShadows = false

-- 2. Tworzenie poziomu, jeśli go nie ma
local folder = Workspace:FindFirstChild("Level2D")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "Level2D"
    folder.Parent = Workspace

    -- Nieskończona podłoga
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(100000, 5, 10)
    floor.Position = Vector3.new(0, -2.5, 0)
    floor.Anchored = true
    floor.Transparency = 1
    floor.Parent = folder

    -- Spawn
    local spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Name = "SpawnLocation"
    spawnLoc.Size = Vector3.new(5, 1, 5)
    spawnLoc.Position = Vector3.new(-50, 0.5, 0)
    spawnLoc.Anchored = true
    spawnLoc.Transparency = 1
    spawnLoc.CanCollide = false
    spawnLoc.Parent = folder

    -- Bloki testowe
    local function createBlock(x, y)
        local block = Instance.new("Part")
        block.Size = Vector3.new(4, 4, 4)
        block.Position = Vector3.new(x, y, 0)
        block.Anchored = true
        block.BrickColor = BrickColor.new("Brick yellow")
        block.Material = Enum.Material.Brick
        block.Parent = folder
    end
    createBlock(-20, 10)
    createBlock(-16, 10)
    createBlock(-12, 10)
    createBlock(-4, 18)
    createBlock(4, 10)
    createBlock(8, 10)

    -- Tło
    local bg = Instance.new("Part")
    bg.Name = "Background"
    bg.Size = Vector3.new(100000, 200, 5)
    bg.Position = Vector3.new(0, -28, -60)
    bg.Anchored = true
    bg.CanCollide = false
    bg.CastShadow = false
    bg.Parent = folder
    
    local textureFront = Instance.new("Texture")
    textureFront.Texture = "rbxassetid://75254160150613"
    textureFront.Face = Enum.NormalId.Front
    textureFront.StudsPerTileU = 80
    textureFront.StudsPerTileV = 40
    textureFront.Parent = bg

    local textureBack = Instance.new("Texture")
    textureBack.Texture = "rbxassetid://75254160150613"
    textureBack.Face = Enum.NormalId.Back
    textureBack.StudsPerTileU = 80
    textureBack.StudsPerTileV = 40
    textureBack.Parent = bg
end
