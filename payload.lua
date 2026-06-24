
local ss = game:GetService("ServerScriptService")
local rs = game:GetService("StarterPlayer").StarterPlayerScripts

local combat = ss:FindFirstChild("CombatHandler")
if combat then combat.Source = [=[--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Najpierw tworzymy autentyczny model R15 (to wymusi pobranie siatek z sieci)
if not ServerStorage:FindFirstChild("NPC_Template") then
    task.spawn(function()
        local success, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(156) -- Builderman (ładny darmowy avatar R15)
        end)
        
        if not success or not desc then
            desc = Instance.new("HumanoidDescription")
        end
        
        local tempNPC = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
        tempNPC.Name = "NPC_Template"
        if tempNPC:FindFirstChild("Animate") then tempNPC.Animate:Destroy() end
        tempNPC.Parent = ServerStorage
    end)
end

-- Ładowanie modułów
local NPCSpawner = require(ServerScriptService.Modules.NPCSpawner)
local Ragdoll = require(ServerScriptService.Modules.Ragdoll)

local HitEvent = ReplicatedStorage:WaitForChild("HitEvent")

local activeNPCs = {}
local PlayerFireCooldowns = {}
local FIRE_COOLDOWN = 0.05
local MAX_DISTANCE = 1000

task.spawn(function()
    for i = 1, 3 do
        local npc = NPCSpawner.Spawn(CFrame.new((i-2) * 5, 5, -10), nil)
        if npc then
            table.insert(activeNPCs, npc)
            task.spawn(function()
                while npc.humanoid and npc.humanoid.Health > 0 and not npc.model:GetAttribute("Ragdolled") do
                    local randomOffset = Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
                    local startPos = npc.root.Position
                    npc.humanoid:MoveTo(startPos + randomOffset)
                    task.wait(math.random(2, 4))
                end
            end)
        end
    end
end)

HitEvent.OnServerEvent:Connect(function(player, hitPart, hitPosition, dir)
    -- Anti-Cheat: Typy danych
	if typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart") then return end
	if typeof(hitPosition) ~= "Vector3" then return end
	if typeof(dir) ~= "Vector3" then return end

    -- Anti-Cheat: Cooldown
    local lastFire = PlayerFireCooldowns[player.UserId] or 0
    if tick() - lastFire < FIRE_COOLDOWN then return end
    PlayerFireCooldowns[player.UserId] = tick()

    -- Anti-Cheat: Weryfikacja gracza
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head") or character.PrimaryPart
    if not head then return end

    -- Anti-Cheat: Odległość
    local distance = (head.Position - hitPosition).Magnitude
    if distance > MAX_DISTANCE then return end

	local model = hitPart:FindFirstAncestorOfClass("Model")
	local npcFolder = workspace:FindFirstChild("NPCs")
	if not model or not npcFolder or not model:IsDescendantOf(npcFolder) then return end
	if model:GetAttribute("Ragdolled") then return end

    -- Anti-Cheat: Serwerowy Raycast (Line of Sight)
    local rayOrigin = head.Position
    local rayDir = (hitPosition - rayOrigin)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Ignorujemy postać strzelca oraz folder z botami (szukamy TYLKO twardych przeszkód jak mury)
    rayParams.FilterDescendantsInstances = {character, npcFolder}
    
    -- Castujemy trochę dalej, żeby uniknąć błędu marginesu precyzji zmiennoprzecinkowej
    local rayResult = workspace:Raycast(rayOrigin, rayDir.Unit * (distance + 1), rayParams)
    
    if rayResult and rayResult.Instance then
        -- Promień natrafił na coś, co nie jest graczem ani NPC!
        -- To oznacza, że klient twierdzi, że trafił, ale na drodze jest ściana (tzw. Silent Aim / Wallbang)
        warn("[Anti-Cheat] Zablokowano strzał przez przeszkodę od: " .. player.Name .. " w przeszkodę: " .. rayResult.Instance.Name)
        return
    end

    local hitNPC = nil
    for _, n in ipairs(activeNPCs) do
        if n.model == model then
            hitNPC = n
            break
        end
    end
    if not hitNPC then return end

    local direction = dir.Magnitude > 0 and dir.Unit or Vector3.new(0, 0, -1)

	NPCSpawner.SetOwnership(hitNPC.root, nil)
	Ragdoll.Enable(hitNPC.model)

	local PROJECTILE_MASS = 0.05
	local PROJECTILE_SPEED = 900
	local TRANSFER = 8
	local MAX_IMPULSE = 4000

	local momentum = PROJECTILE_MASS * PROJECTILE_SPEED * TRANSFER
	momentum = math.clamp(momentum, 0, MAX_IMPULSE)
	local impulse = direction * momentum

	hitPart:ApplyImpulseAtPosition(impulse * 0.7, hitPosition)
	
	local torso = hitNPC.model:FindFirstChild("UpperTorso") :: BasePart?
	if torso then
		torso:ApplyImpulse(impulse * 0.3)
	end

	task.delay(8, function()
		if hitNPC.model.Parent then
			hitNPC.model:Destroy()
		end
	end)
end)
]=] end

local client = rs:FindFirstChild("WallClickClient")
if client then client.Source = [=[local Players = game:GetService("Players")
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
        local npcFolder = workspace:FindFirstChild("NPCs") 
        if model and npcFolder and model:IsDescendantOf(npcFolder) then
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
]=] end

local mods = ss:FindFirstChild("Modules")
if mods then
    local spawner = mods:FindFirstChild("NPCSpawner")
    if spawner then spawner.Source = [=[--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local NPCSpawner = {}
NPCSpawner.__index = NPCSpawner

local TEMPLATE: Model = ServerStorage:WaitForChild("NPC_Template") :: Model
local NPC_FOLDER_NAME = "NPCs"
local NPC_COLLISION_GROUP = "NPCs"

pcall(function()
	PhysicsService:RegisterCollisionGroup(NPC_COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(NPC_COLLISION_GROUP, NPC_COLLISION_GROUP, false)
end)

local function getNPCFolder(): Folder
	local folder = workspace:FindFirstChild(NPC_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = NPC_FOLDER_NAME
		folder.Parent = workspace
	end
	return folder :: Folder
end

local NPCAnimator = require(script.Parent.NPCAnimator)

export type NPC = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	owner: Player?,
	animator: any,
}

function NPCSpawner.Spawn(spawnCFrame: CFrame, owner: Player?): NPC?
	local model = TEMPLATE:Clone()
	model.Name = "Bot"
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	
	if not humanoid or not root then
		model:Destroy()
		warn("[NPCSpawner] Template nie ma Humanoid lub HumanoidRootPart")
		return nil
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = NPC_COLLISION_GROUP
		end
	end

	model:PivotTo(spawnCFrame)
	model.Parent = getNPCFolder()

	NPCSpawner.SetOwnership(root, owner)

	local animController = NPCAnimator.new(model)

	local npc: NPC = {
		model = model,
		humanoid = humanoid,
		root = root,
		owner = owner,
		animator = animController,
	}
	return npc
end

function NPCSpawner.SetOwnership(root: BasePart, owner: Player?)
	local function trySet(part: BasePart)
		if part.Anchored then return end
		local ok, err = pcall(function()
			part:SetNetworkOwner(owner)
		end)
		if not ok then
			warn(("[NPCSpawner] SetNetworkOwner failed: %s"):format(tostring(err)))
		end
	end

	trySet(root)
	for _, desc in root:GetDescendants() do
		if desc:IsA("BasePart") then
			trySet(desc)
		end
	end
end

return NPCSpawner
]=] end
    
    local ragdoll = mods:FindFirstChild("Ragdoll")
    if ragdoll then ragdoll.Source = [=[--!strict
local Ragdoll = {}

type Limit = { cone: number, twistLower: number, twistUpper: number }

local JOINT_LIMITS: { [string]: Limit } = {
	Neck          = { cone = 45,  twistLower = -40, twistUpper = 40 },
	Waist         = { cone = 40,  twistLower = -30, twistUpper = 30 },
	LeftShoulder  = { cone = 100, twistLower = -90, twistUpper = 90 },
	RightShoulder = { cone = 100, twistLower = -90, twistUpper = 90 },
	LeftElbow     = { cone = 95,  twistLower = -10, twistUpper = 10 },
	RightElbow    = { cone = 95,  twistLower = -10, twistUpper = 10 },
	LeftWrist     = { cone = 30,  twistLower = -20, twistUpper = 20 },
	RightWrist    = { cone = 30,  twistLower = -20, twistUpper = 20 },
	LeftHip       = { cone = 85,  twistLower = -30, twistUpper = 30 },
	RightHip      = { cone = 85,  twistLower = -30, twistUpper = 30 },
	LeftKnee      = { cone = 95,  twistLower = -10, twistUpper = 10 },
	RightKnee     = { cone = 95,  twistLower = -10, twistUpper = 10 },
	LeftAnkle     = { cone = 45,  twistLower = -20, twistUpper = 20 },
	RightAnkle    = { cone = 45,  twistLower = -20, twistUpper = 20 },
}

local DEFAULT_LIMIT: Limit = { cone = 60, twistLower = -45, twistUpper = 45 }

local function ensureAttachments(motor: Motor6D): (Attachment, Attachment)
	local part0 = motor.Part0 :: BasePart
	local part1 = motor.Part1 :: BasePart

	local a0 = Instance.new("Attachment")
	a0.Name = "RagdollAtt0_" .. motor.Name
	a0.CFrame = motor.C0
	a0.Parent = part0

	local a1 = Instance.new("Attachment")
	a1.Name = "RagdollAtt1_" .. motor.Name
	a1.CFrame = motor.C1
	a1.Parent = part1

	return a0, a1
end

function Ragdoll.Enable(model: Model)
	if model:GetAttribute("Ragdolled") then return end
	model:SetAttribute("Ragdolled", true)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	end

	local createdConstraints: { Instance } = {}

	for _, desc in model:GetDescendants() do
		if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 then
			local motor = desc :: Motor6D

            local objVal = Instance.new("ObjectValue")
            objVal.Name = "OriginalPart1"
            objVal.Value = motor.Part1
            objVal.Parent = motor
            
			local a0, a1 = ensureAttachments(motor)
			
            motor.Part1 = nil

			local socket = Instance.new("BallSocketConstraint")
			socket.Name = "RagdollSocket_" .. motor.Name
			socket.Attachment0 = a0
			socket.Attachment1 = a1

			local limit = JOINT_LIMITS[motor.Name] or DEFAULT_LIMIT
			socket.LimitsEnabled = true
			socket.UpperAngle = limit.cone
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle = limit.twistLower
			socket.TwistUpperAngle = limit.twistUpper

			socket.Parent = motor.Part0
			
			table.insert(createdConstraints, socket)
			table.insert(createdConstraints, a0)
			table.insert(createdConstraints, a1)

			local noCol = Instance.new("NoCollisionConstraint")
			noCol.Name = "RagdollNoCol_" .. motor.Name
			noCol.Part0 = motor.Part0
			local targetPart = objVal.Value
			if targetPart and targetPart:IsA("BasePart") then
			    noCol.Part1 = targetPart
			end
			noCol.Parent = motor.Part0
			table.insert(createdConstraints, noCol)
		end
	end

	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then hrp.CanCollide = false end

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and desc ~= hrp then
			desc.CanCollide = true
		end
	end

	model:SetAttribute("_RagdollConstraintCount", #createdConstraints)
end

function Ragdoll.Disable(model: Model)
	if not model:GetAttribute("Ragdolled") then return end
	model:SetAttribute("Ragdolled", false)

	for _, desc in model:GetDescendants() do
		if desc:IsA("BallSocketConstraint") and desc.Name:match("^RagdollSocket_") then
			desc:Destroy()
		elseif desc:IsA("NoCollisionConstraint") and desc.Name:match("^RagdollNoCol_") then
			desc:Destroy()
		elseif desc:IsA("Attachment") and desc.Name:match("^RagdollAtt") then
			desc:Destroy()
		elseif desc:IsA("Motor6D") then
		    local objVal = desc:FindFirstChild("OriginalPart1") :: ObjectValue?
		    if objVal and objVal.Value then
			    desc.Part1 = objVal.Value :: BasePart
			    objVal:Destroy()
			end
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

return Ragdoll
]=] end
    
    local animator = mods:FindFirstChild("NPCAnimator")
    if animator then animator.Source = [=[--!strict
local NPCAnimator = {}
NPCAnimator.__index = NPCAnimator

local ANIM_IDS = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
	Run  = "rbxassetid://507767714",
}

local WALK_THRESHOLD = 0.5
local RUN_THRESHOLD = 14
local FADE_TIME = 0.2

export type Controller = {
	humanoid: Humanoid,
	animator: Animator,
	tracks: { [string]: AnimationTrack },
	current: string?,
	connections: { RBXScriptConnection },
	destroyed: boolean,
}

local function makeAnimation(name: string, id: string): Animation
	local anim = Instance.new("Animation")
	anim.Name = name
	anim.AnimationId = id
	return anim
end

function NPCAnimator.new(model: Model): Controller?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local self: Controller = setmetatable({
		humanoid = humanoid,
		animator = animator,
		tracks = {},
		current = nil,
		connections = {},
		destroyed = false,
	}, NPCAnimator) :: any

	for name, id in ANIM_IDS do
		if id ~= "rbxassetid://0" then
			local track = animator:LoadAnimation(makeAnimation(name, id))
			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = true
			self.tracks[name] = track
		end
	end

	table.insert(self.connections, humanoid.Running:Connect(function(speed: number)
		if self.destroyed then return end
		if model:GetAttribute("Ragdolled") then
			self:_stopAll()
			return
		end
		if speed < WALK_THRESHOLD then
			self:_playOnly("Idle")
		elseif speed < RUN_THRESHOLD then
			self:_playOnly("Walk")
		else
			self:_playOnly("Run")
		end
	end))

	table.insert(self.connections, model:GetAttributeChangedSignal("Ragdolled"):Connect(function()
		if self.destroyed then return end
		if model:GetAttribute("Ragdolled") then
			self:_stopAll()
		else
			self:_playOnly("Idle")
		end
	end))

	table.insert(self.connections, model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
	end))

	self:_playOnly("Idle")
	return self
end

function NPCAnimator._playOnly(self: Controller, name: string)
	if self.current == name then return end

	local target = self.tracks[name]
	if not target then return end

	for trackName, track in self.tracks do
		if trackName == name then
			if not track.IsPlaying then track:Play(FADE_TIME) end
		elseif track.IsPlaying then
			track:Stop(FADE_TIME)
		end
	end
	self.current = name
end

function NPCAnimator._stopAll(self: Controller)
	for _, track in self.tracks do
		if track.IsPlaying then track:Stop(FADE_TIME) end
	end
	self.current = nil
end

function NPCAnimator.Destroy(self: Controller)
	if self.destroyed then return end
	self.destroyed = true
	for _, conn in self.connections do conn:Disconnect() end
	table.clear(self.connections)
	self:_stopAll()
	for _, track in self.tracks do track:Destroy() end
	table.clear(self.tracks)
end

return NPCAnimator
]=] end
end

return "Injected"
