local RunService = game:GetService("RunService")
local character = script.Parent
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Target Z coordinate (center of our 2D lane)
local TARGET_Z = 0

local function lockAxis()
	local currentPos = rootPart.Position
	if math.abs(currentPos.Z - TARGET_Z) > 0.01 then
		rootPart.CFrame = CFrame.new(currentPos.X, currentPos.Y, TARGET_Z) * (rootPart.CFrame - rootPart.CFrame.Position)
	end
end

RunService.Heartbeat:Connect(lockAxis)
