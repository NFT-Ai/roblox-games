--!strict
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
