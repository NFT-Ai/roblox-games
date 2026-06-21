local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Side view offset
local CAMERA_OFFSET = Vector3.new(0, 5, 40) 

camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70 -- Standard FOV to ensure visibility

local function updateCamera()
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		-- Position the camera at character's X, but fixed Z offset
		local cameraPosition = Vector3.new(rootPart.Position.X, rootPart.Position.Y + 5, 20) -- Przybliżenie kamery (było 40)
		local lookTarget = Vector3.new(rootPart.Position.X, rootPart.Position.Y + 5, 0)
		
		camera.CFrame = CFrame.lookAt(cameraPosition, lookTarget)
	end
end

RunService:BindToRenderStep("SideScrollingCamera", Enum.RenderPriority.Camera.Value + 1, updateCamera)
