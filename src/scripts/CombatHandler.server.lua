--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Najpierw tworzymy autentyczny model R15 (to wymusi pobranie siatek z sieci)
if not ServerStorage:FindFirstChild("NPC_Template") then
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
