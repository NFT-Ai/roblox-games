local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BackgroundGui"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = -10 -- Send to back
screenGui.Parent = playerGui

local background = Instance.new("ImageLabel")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
-- Using a known sky asset for fallback, but keep your image logic
background.Image = "rbxassetid://133374828355606" -- Poprawny format ID
background.ScaleType = Enum.ScaleType.Crop -- Crop lepiej pasuje do tła bitmapowego
background.BackgroundTransparency = 1 -- Przeźroczyste tło kontenera
background.ZIndex = -10
background.Parent = screenGui

-- Parallax
RunService.RenderStepped:Connect(function()
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPos = character.HumanoidRootPart.Position
		-- Przesunięcie tekstury tła zamiast całego obrazka
		background.ImageRectSize = Vector2.new(1000, 1000) -- Rozmiar wycinka
		background.ImageRectOffset = Vector2.new(rootPos.X * 5, 0) -- Prędkość paralaksy
	end
end)
