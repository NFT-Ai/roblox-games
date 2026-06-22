
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

createScript(StarterGui, "LocalScript", "MapEditor", [====[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "MapEditorGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local COLS = 20
local ROWS = 10
local CELL_SIZE = 30

-- Główny kontener
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, COLS * CELL_SIZE + 20, 0, ROWS * CELL_SIZE + 100)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Text = "Mario Maker - Edytor Map"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

-- Paleta narzędzi
local tools = {
    {name = "Ziemia", type = "Ground", color = Color3.fromRGB(50, 200, 50)},
    {name = "Ogień", type = "Fire", color = Color3.fromRGB(255, 50, 50)},
    {name = "Moneta", type = "Coin", color = Color3.fromRGB(255, 215, 0)},
    {name = "Spawn", type = "Spawn", color = Color3.fromRGB(50, 50, 255)},
    {name = "Gumka", type = "Empty", color = Color3.fromRGB(200, 200, 200)}
}

local currentTool = tools[1]

local toolbar = Instance.new("Frame")
toolbar.Size = UDim2.new(1, 0, 0, 40)
toolbar.Position = UDim2.new(0, 0, 0, 30)
toolbar.BackgroundTransparency = 1
toolbar.Parent = mainFrame

local toolLayout = Instance.new("UIListLayout")
toolLayout.FillDirection = Enum.FillDirection.Horizontal
toolLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toolLayout.Padding = UDim.new(0, 5)
toolLayout.Parent = toolbar

for _, t in ipairs(tools) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 30)
    btn.BackgroundColor3 = t.color
    btn.Text = t.name
    btn.TextColor3 = (t.type == "Coin" or t.type == "Empty") and Color3.new(0,0,0) or Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Parent = toolbar
    
    btn.MouseButton1Click:Connect(function()
        currentTool = t
    end)
end

-- Siatka
local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(0, COLS * CELL_SIZE, 0, ROWS * CELL_SIZE)
gridFrame.Position = UDim2.new(0.5, 0, 0, 80)
gridFrame.AnchorPoint = Vector2.new(0.5, 0)
gridFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
gridFrame.Parent = mainFrame

local cells = {}
local gridData = {}

for y = 1, ROWS do
    gridData[y] = {}
    for x = 1, COLS do
        gridData[y][x] = "Empty"
        
        local cell = Instance.new("TextButton")
        cell.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
        cell.Position = UDim2.new(0, (x-1)*CELL_SIZE, 0, (y-1)*CELL_SIZE)
        cell.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        cell.Text = ""
        cell.BorderSizePixel = 1
        cell.BorderColor3 = Color3.fromRGB(100, 100, 100)
        cell.Parent = gridFrame
        
        local function paint()
            gridData[y][x] = currentTool.type
            cell.BackgroundColor3 = currentTool.color
        end
        
        cell.MouseButton1Down:Connect(paint)
        cell.MouseEnter:Connect(function()
            -- Pozwala na malowanie przeciąganiem, jeśli mamy wciśnięty przycisk
            -- (w uproszczeniu Robloxowym używamy UserInputService, ale tu dla testu zrobimy prosty hover)
        end)
    end
end

-- Przycisk testowania
local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(1, -20, 0, 30)
playBtn.Position = UDim2.new(0, 10, 1, -40)
playBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
playBtn.Text = "ZAGRAJ W TĘ MAPĘ"
playBtn.TextColor3 = Color3.new(1,1,1)
playBtn.Font = Enum.Font.GothamBold
playBtn.TextSize = 14
playBtn.Parent = mainFrame

playBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
    -- Wysyłamy dane na serwer, by wygenerował mapę
    local GenerateMapEvent = ReplicatedStorage:FindFirstChild("GenerateMapEvent")
    if GenerateMapEvent then
        GenerateMapEvent:FireServer(gridData)
    end
end)

-- Przycisk Pokaż/Ukryj Edytor
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 150, 0, 30)
toggleBtn.Position = UDim2.new(1, -160, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.Text = "Edytor Map"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = gui

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

mainFrame.Visible = false
]====])
createScript(ServerScriptService, "Script", "SetupLevel2D", [====[local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utworzenie RemoteEvent do odbierania map od graczy
local GenerateMapEvent = ReplicatedStorage:FindFirstChild("GenerateMapEvent")
if not GenerateMapEvent then
    GenerateMapEvent = Instance.new("RemoteEvent")
    GenerateMapEvent.Name = "GenerateMapEvent"
    GenerateMapEvent.Parent = ReplicatedStorage
end

-- 1. Poprawa oświetlenia
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then atmosphere:Destroy() end
Lighting.FogEnd = 1000000
Lighting.FogStart = 1000000
Lighting.Ambient = Color3.fromRGB(200, 200, 200)
Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
Lighting.GlobalShadows = false

-- Funkcja budująca mapę na podstawie podanej siatki (Grid)
local function buildMap(gridData)
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

    local TILE_SIZE = 4
    local START_X = -50
    local START_Y = 20

    local function createBlock(x, y, color, material, name)
        local block = Instance.new("Part")
        block.Name = name or "Block"
        block.Size = Vector3.new(TILE_SIZE, TILE_SIZE, TILE_SIZE)
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
        
        local script = Instance.new("Script")
        script.Source = [[
            local coin = script.Parent
            local TweenService = game:GetService("TweenService")
            game:GetService("RunService").Heartbeat:Connect(function(dt)
                coin.CFrame = coin.CFrame * CFrame.Angles(dt * 3, 0, 0)
            end)
            local db = false
            coin.Touched:Connect(function(hit)
                if db then return end
                if hit.Parent:FindFirstChildOfClass("Humanoid") then
                    db = true
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

    local spawnCreated = false

    for y, row in ipairs(gridData) do
        for x, tileType in ipairs(row) do
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
                spawnCreated = true
            end
        end
    end
    
    -- Jeśli nikt nie postawił spawnu, zróbmy domyślny
    if not spawnCreated then
        createSpawn(0, 0)
    end
end

-- Nasłuchiwanie na mapy od graczy
GenerateMapEvent.OnServerEvent:Connect(function(player, gridData)
    print("Otrzymano nową mapę od", player.Name)
    buildMap(gridData)
    
    -- Teleportacja gracza na nowy spawn
    local spawnLoc = Workspace.Level2D:FindFirstChild("SpawnLocation")
    if spawnLoc and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
    end
end)

-- Załadowanie domyślnej mapy po uruchomieniu serwera
local success, MapData = pcall(function() return require(ServerScriptService:WaitForChild("MapData")) end)
if success and MapData and MapData.Grid then
    buildMap(MapData.Grid)
end
]====])
createScript(ServerScriptService, "ModuleScript", "MapData", [====[local MapData = {}
MapData.Width = 20
MapData.Height = 10
MapData.Grid = {
    {"Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Coin", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Coin", "Coin", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Ground", "Ground", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Ground", "Ground", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Empty", "Spawn", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty", "Empty"},
    {"Ground", "Ground", "Ground", "Ground", "Ground", "Fire", "Fire", "Fire", "Fire", "Fire", "Ground", "Ground", "Ground", "Ground", "Ground", "Ground", "Ground", "Ground", "Ground", "Ground"},
}

return MapData]====])
createScript(ReplicatedFirst, "LocalScript", "ImagePreloader", [====[local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999

local playerGui = player:WaitForChild("PlayerGui", 5)
if playerGui then
    gui.Parent = playerGui
end

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.Parent = gui

local text = Instance.new("TextLabel")
text.Size = UDim2.new(1, 0, 1, 0)
text.Position = UDim2.new(0, 0, -0.05, 0)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.new(1, 1, 1)
text.TextSize = 30
text.Font = Enum.Font.GothamBold
text.Text = "Ładowanie pikselowego świata..."
text.Parent = bg

local debugText = Instance.new("TextLabel")
debugText.Size = UDim2.new(1, 0, 0, 50)
debugText.Position = UDim2.new(0, 0, 0.55, 0)
debugText.BackgroundTransparency = 1
debugText.TextColor3 = Color3.new(0.3, 1, 0.3)
debugText.TextSize = 18
debugText.Font = Enum.Font.Code
debugText.Text = "Debug: Start"
debugText.Parent = bg

local dummyImage = Instance.new("ImageLabel")
dummyImage.Image = "rbxassetid://75254160150613"
dummyImage.Size = UDim2.new(0, 1, 0, 1)
dummyImage.Position = UDim2.new(2, 0, 2, 0)
dummyImage.BackgroundTransparency = 1
dummyImage.Parent = bg

debugText.Text = "Debug: PreloadAsync start..."
local t0 = tick()
ContentProvider:PreloadAsync({dummyImage})
debugText.Text = "Debug: PreloadAsync zakończone w " .. string.format("%.2f", tick() - t0) .. "s"

local waitTime = 0
local maxWait = 6

while not dummyImage.IsLoaded and waitTime < maxWait do
    task.wait(0.1)
    waitTime = waitTime + 0.1
    debugText.Text = "Debug: Czekam na dummyImage.IsLoaded... " .. string.format("%.1f", waitTime) .. "s"
end

if dummyImage.IsLoaded then
    debugText.Text = "Debug: Obraz załadowany! IsLoaded = true. Uruchamiam grę..."
else
    debugText.Text = "Debug: Przekroczono limit czasu. Wymuszam uruchomienie..."
end

task.wait(1.5)

local TweenService = game:GetService("TweenService")
local fadeInfo = TweenInfo.new(0.5)
TweenService:Create(text, fadeInfo, {TextTransparency = 1}):Play()
TweenService:Create(debugText, fadeInfo, {TextTransparency = 1}):Play()
local fade = TweenService:Create(bg, fadeInfo, {BackgroundTransparency = 1})
fade:Play()
fade.Completed:Wait()

gui:Destroy()
]====])
createScript(StarterPlayer.StarterPlayerScripts, "LocalScript", "SideCamera", [====[local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FOV = 5
local CAMERA_DEPTH = 300
local CAMERA_HEIGHT = 4

local function updateCamera()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local targetPosition = Vector3.new(rootPart.Position.X, rootPart.Position.Y + CAMERA_HEIGHT, CAMERA_DEPTH)
        
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(targetPosition, targetPosition - Vector3.new(0, 0, 1))
        camera.FieldOfView = FOV
    end
end

RunService.RenderStepped:Connect(updateCamera)
]====])
createScript(StarterPlayer.StarterCharacterScripts, "LocalScript", "Movement2D", [====[local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local newPos = Vector3.new(hrp.Position.X, hrp.Position.Y, 0)
        local currentRot = hrp.CFrame - hrp.CFrame.Position
        hrp.CFrame = CFrame.new(newPos) * currentRot
        
        -- Also force velocity Z to 0 so physics doesn't push us out
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, 0)
    end
end)
]====])

return "All scripts successfully injected directly to Studio!"
