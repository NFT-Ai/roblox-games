local RunService = game:GetService("RunService")
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
