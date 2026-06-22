local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")

local MapData = require(ServerScriptService:WaitForChild("MapData"))

-- 1. Poprawa oświetlenia
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then atmosphere:Destroy() end
Lighting.FogEnd = 1000000
Lighting.FogStart = 1000000
Lighting.Ambient = Color3.fromRGB(200, 200, 200)
Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
Lighting.GlobalShadows = false

-- 2. Tworzenie folderu poziomu
local folder = Workspace:FindFirstChild("Level2D")
if folder then
    folder:Destroy()
end
folder = Instance.new("Folder")
folder.Name = "Level2D"
folder.Parent = Workspace

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


-- 3. Generowanie mapy na podstawie MapData
local TILE_SIZE = 4
-- Przesunięcie mapy, by startowała od wygodnego punktu w świecie
local START_X = -50
local START_Y = 20

local function createBlock(x, y, color, material, name)
    local block = Instance.new("Part")
    block.Name = name or "Block"
    block.Size = Vector3.new(TILE_SIZE, TILE_SIZE, TILE_SIZE)
    -- Oś Y idzie w dół na bitmapie, więc odejmujemy Y
    block.Position = Vector3.new(START_X + (x * TILE_SIZE), START_Y - (y * TILE_SIZE), 0)
    block.Anchored = true
    block.Color = color
    block.Material = material
    block.Parent = folder
    return block
end

local function createCoin(x, y)
    local coin = Instance.new("Part")
    coin.Name = "Coin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Orientation = Vector3.new(0, 0, 90)
    coin.Size = Vector3.new(0.5, TILE_SIZE * 0.7, TILE_SIZE * 0.7)
    coin.Position = Vector3.new(START_X + (x * TILE_SIZE), START_Y - (y * TILE_SIZE), 0)
    coin.Anchored = true
    coin.CanCollide = false
    coin.Color = Color3.fromRGB(255, 215, 0)
    coin.Material = Enum.Material.Neon
    coin.Parent = folder
    
    -- Skrypt kręcenia i zbierania
    local script = Instance.new("Script")
    script.Source = [[
        local coin = script.Parent
        local TweenService = game:GetService("TweenService")
        
        -- Obracanie
        game:GetService("RunService").Heartbeat:Connect(function(dt)
            coin.CFrame = coin.CFrame * CFrame.Angles(dt * 3, 0, 0)
        end)
        
        -- Zbieranie
        local db = false
        coin.Touched:Connect(function(hit)
            if db then return end
            local character = hit.Parent
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                db = true
                -- Efekt zebrania
                local tween = TweenService:Create(coin, TweenInfo.new(0.3), {Size = Vector3.new(0,0,0), Transparency = 1})
                tween:Play()
                tween.Completed:Wait()
                coin:Destroy()
            end
        end)
    ]]
    script.Parent = coin
end

local function createFire(x, y)
    local fireBlock = createBlock(x, y, Color3.fromRGB(255, 50, 50), Enum.Material.Neon, "Fire")
    local fireParticles = Instance.new("Fire")
    fireParticles.Size = 4
    fireParticles.Parent = fireBlock
    
    local script = Instance.new("Script")
    script.Source = [[
        local fire = script.Parent
        local db = false
        fire.Touched:Connect(function(hit)
            if db then return end
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                db = true
                humanoid:TakeDamage(100)
                task.wait(1)
                db = false
            end
        end)
    ]]
    script.Parent = fireBlock
end

local function createSpawn(x, y)
    local spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Name = "SpawnLocation"
    spawnLoc.Size = Vector3.new(TILE_SIZE, 1, TILE_SIZE)
    spawnLoc.Position = Vector3.new(START_X + (x * TILE_SIZE), (START_Y - (y * TILE_SIZE)) - (TILE_SIZE/2) + 0.5, 0)
    spawnLoc.Anchored = true
    spawnLoc.Transparency = 1
    spawnLoc.CanCollide = false
    spawnLoc.Parent = folder
end

-- Pętla generująca
for y, row in ipairs(MapData.Grid) do
    for x, tileType in ipairs(row) do
        -- Indeksy w Lua zaczynają się od 1, więc przesuwamy
        local realX = x - 1
        local realY = y - 1
        
        if tileType == "Ground" then
            createBlock(realX, realY, Color3.fromRGB(50, 200, 50), Enum.Material.Grass, "Ground")
        elseif tileType == "Fire" then
            createFire(realX, realY)
        elseif tileType == "Coin" then
            createCoin(realX, realY)
        elseif tileType == "Spawn" then
            createSpawn(realX, realY)
        end
    end
end
