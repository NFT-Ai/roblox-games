local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CAMERA_DEPTH = 40
local CAMERA_HEIGHT = 8

local function updateCamera()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local targetPosition = Vector3.new(rootPart.Position.X, rootPart.Position.Y + CAMERA_HEIGHT, CAMERA_DEPTH)

        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(targetPosition, targetPosition - Vector3.new(0, 0, 1))
    end
end

RunService.RenderStepped:Connect(updateCamera)
