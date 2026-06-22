local Players = game:GetService("Players")
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
