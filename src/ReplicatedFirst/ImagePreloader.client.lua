local ContentProvider = game:GetService("ContentProvider")
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
