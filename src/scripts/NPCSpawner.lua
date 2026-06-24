--!strict
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
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
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
