
local ss = game:GetService("ServerScriptService")
local mods = ss:FindFirstChild("Modules")
if mods then
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
			
		elseif desc:IsA("AnimationConstraint") then
			desc.Enabled = false
			local marker = Instance.new("BoolValue")
			marker.Name = "RagdollWasDisabled"
			marker.Value = true
			marker.Parent = desc
			
		elseif desc:IsA("BallSocketConstraint") and desc.Name:match("BallSocket$") then
			local baseName = desc.Name:gsub("BallSocket$", "")
			local limit = JOINT_LIMITS[baseName] or DEFAULT_LIMIT
			
			local mem = Instance.new("Configuration")
			mem.Name = "RagdollOriginalLimits"
			mem:SetAttribute("LimitsEnabled", desc.LimitsEnabled)
			mem:SetAttribute("UpperAngle", desc.UpperAngle)
			mem:SetAttribute("TwistLimitsEnabled", desc.TwistLimitsEnabled)
			mem:SetAttribute("TwistLowerAngle", desc.TwistLowerAngle)
			mem:SetAttribute("TwistUpperAngle", desc.TwistUpperAngle)
			mem.Parent = desc

			desc.LimitsEnabled = true
			desc.UpperAngle = limit.cone
			desc.TwistLimitsEnabled = true
			desc.TwistLowerAngle = limit.twistLower
			desc.TwistUpperAngle = limit.twistUpper
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
		elseif desc:IsA("AnimationConstraint") then
			local marker = desc:FindFirstChild("RagdollWasDisabled")
			if marker then
				desc.Enabled = true
				marker:Destroy()
			end
		elseif desc:IsA("BallSocketConstraint") and desc.Name:match("BallSocket$") then
			local mem = desc:FindFirstChild("RagdollOriginalLimits")
			if mem then
				desc.LimitsEnabled = mem:GetAttribute("LimitsEnabled")
				desc.UpperAngle = mem:GetAttribute("UpperAngle")
				desc.TwistLimitsEnabled = mem:GetAttribute("TwistLimitsEnabled")
				desc.TwistLowerAngle = mem:GetAttribute("TwistLowerAngle")
				desc.TwistUpperAngle = mem:GetAttribute("TwistUpperAngle")
				mem:Destroy()
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
end
return "Injected Ragdoll!"
