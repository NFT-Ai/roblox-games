local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VoxBreaker = require(ReplicatedStorage:WaitForChild("VoxBreaker"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local BULLET_RADIUS = 0.4
local BULLET_SPEED  = 150     
local BULLET_DENSITY = 5      
local BULLET_LIFE   = 4       

local MIN_VOXEL_SIZE = 1
local RESET_TIME     = -1
local BASE_HITBOX    = 0.85   
local MAX_HITBOX     = 4      
local ENERGY_REF     = 6000   
local CHUNK_PUSH     = 0.003  

local HitEvent = ReplicatedStorage:WaitForChild("HitEvent")

local function fireBullet()
    local char = player.Character
    if not char then return end

    local origin = camera.CFrame.Position
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then
        origin = tool.Handle.Position + (tool.Handle.CFrame.LookVector * 1)
    else
        local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        if arm then origin = arm.Position end
    end

    local dir = camera.CFrame.LookVector
    if mouse.Hit then
        dir = (mouse.Hit.Position - origin).Unit
    end

    local bullet = Instance.new("Part")
    bullet.Shape = Enum.PartType.Ball
    bullet.Size = Vector3.new(BULLET_RADIUS * 2, BULLET_RADIUS * 2, BULLET_RADIUS * 2)
    bullet.Color = Color3.fromRGB(255, 200, 0)
    bullet.Material = Enum.Material.Neon
    bullet.CanCollide = false
    bullet.CustomPhysicalProperties = PhysicalProperties.new(
        BULLET_DENSITY, 0.3, 0.5, 1, 1
    )
    bullet.CFrame = CFrame.new(origin + dir * 1.5)
    bullet.AssemblyLinearVelocity = dir * BULLET_SPEED
    bullet.Parent = workspace

    Debris:AddItem(bullet, BULLET_LIFE)

    local hitProcessed = false

    bullet.Touched:Connect(function(hit)
        if hitProcessed then return end
        
        local model = hit:FindFirstAncestorOfClass("Model")
        local npcFolder = workspace:FindFirstChild("NPCs") if model and npcFolder and model:IsDescendantOf(npcFolder) then
            hitProcessed = true
            local velocity = bullet.AssemblyLinearVelocity
            local direction = velocity.Magnitude > 0 and velocity.Unit or dir
            HitEvent:FireServer(hit, bullet.Position, direction)
            bullet:Destroy()
            return
        end
        
        if hit:GetAttribute("Destroyable") == true then
            hitProcessed = true
            local velocity = bullet.AssemblyLinearVelocity
            local speed = velocity.Magnitude
            local mass = bullet.AssemblyMass
            local kineticEnergy = 0.5 * mass * speed * speed
            local impactDir = velocity.Unit
            
            if speed == 0 then impactDir = dir kineticEnergy = 100 end

            local impactPos = bullet.Position
            bullet:Destroy()

            local energyFactor = math.clamp(kineticEnergy / ENERGY_REF, 0, 1)
            local hitboxSide = BASE_HITBOX + (MAX_HITBOX - BASE_HITBOX) * energyFactor
            local hitboxSize = Vector3.new(hitboxSide, hitboxSide, hitboxSide)

            local voxels = VoxBreaker:CreateHitbox(
                hitboxSize,
                CFrame.new(impactPos),
                Enum.PartType.Ball, 
                MIN_VOXEL_SIZE,
                RESET_TIME
            )

            for _, voxel in ipairs(voxels) do
                if voxel and voxel:IsA("BasePart") and voxel.Parent then
                    voxel.Anchored = false
                    voxel.CanCollide = true
                    local impulse = impactDir * kineticEnergy * CHUNK_PUSH
                    voxel:ApplyImpulse(impulse * voxel.AssemblyMass)
                    voxel.AssemblyAngularVelocity = Vector3.new(
                        math.random(-15, 15), math.random(-15, 15), math.random(-15, 15)
                    )
                    Debris:AddItem(voxel, 5)
                end
            end
        end
    end)
end

mouse.Button1Down:Connect(fireBullet)
