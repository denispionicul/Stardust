--!nocheck
--Version 1.2.0

-- Settings
local Debug = true -- ths does nothing at the moment

-- Services
local Debris = game:GetService("Debris")

-- Dependencies
local Signal = require(script.Parent:FindFirstChild("Signal") or script.Signal)
local Trove = require(script.Parent:FindFirstChild("Trove") or script.Trove)
local Option = require(script.Parent:FindFirstChild("Option") or script.Option)

--[=[
	@class Ploder

	Ploder is a module that is designed to make custom explosions easy to make.
	To get started, simply require the module and construct it.

	```lua
	local Ploder = require(Path.Ploder)

	local Explosion = Ploder.new()
	```

	On its own, the constructor and ploder for that matter functions exactly like the normal [Explosion](https://create.roblox.com/docs/reference/engine/classes/Explosion).
	We will get to the custom features later.
]=]
--[=[
	@class PloderBehavior

	The **PloderBehavior** is a list of configurations that can be set whenever calling the [Ploder.Explode] method.
]=]
local Ploder = {}
Ploder.__index = Ploder

-- Types

--[=[
	@prop BlastPressure number
	@within Ploder

	The **BlastPressure** tells the explosion the amount of force to apply on hit parts.

	:::note
	* The **BlastPressure** only applies if a part isn't anchored and not welded.
	* The **BlastPressure** only applies if the [Ploder.DestroyJointRadiusPercent] requirement is met.
	* The **BlastPressure** is the same as the [Explosion BlastPressure](https://create.roblox.com/docs/reference/engine/classes/Explosion#BlastPressure)
	:::
]=]
--[=[
	@prop BlastRadius number
	@within Ploder

	The **BlastRadius** tells the explosion the amount of range it will have.

	:::note
	* The **BlastRadius** is the same as the [Explosion BlastRadius](https://create.roblox.com/docs/reference/engine/classes/Explosion#BlastRadius)
	:::
]=]
--[=[
	@prop DestroyJointRadiusPercent number
	@within Ploder

	The **DestroyJointRadiusPercent** tells the explosion how close a part has to be to be affected by the pressure and get its joints destroyed.
	It should be a value between 0-1. 1 being 100% (it will always destroy no matter the range) and 0.5 being 50% (50% near the explosion or less).

	:::note
	* The **DestroyJointRadiusPercent** is the same as the [Explosion DestroyJointRadiusPercent](https://create.roblox.com/docs/reference/engine/classes/Explosion#DestroyJointRadiusPercent)
	:::
]=]
--[=[
	@prop ExplosionType Enum.ExplosionType
	@within Ploder

	The **ExplosionType** defines if the explosion will leave craters behind on terrain.

	:::note
	* The **ExplosionType** is the same as the [Explosion ExplosionType](https://create.roblox.com/docs/reference/engine/classes/Explosion#ExplosionType)
	:::
]=]
--[=[
	@prop Position Vector3
	@within Ploder

	The **Position** defines the center and origin of the explosion.

	:::note
	* The **Position** is the same as the [Explosion Position](https://create.roblox.com/docs/reference/engine/classes/Explosion#Position)
	:::
]=]
--[=[
	@prop TimeScale number
	@within Ploder

	The **TimeScale** defines the speed of the explosion particle (if not using any custom ones).
	This is a value from 0-1. 1 being full speed, 0.5 being half speed and 0 being frozen.

	:::note
	* The **TimeScale** is the same as the [Explosion TimeScale](https://create.roblox.com/docs/reference/engine/classes/Explosion#TimeScale)
	:::
]=]
--[=[
	@prop Visible boolean
	@within Ploder

	The **Visible** boolean defines if any sort of visual effect will occur on explosion.
	If false, no default explosion or custom explosion will be rendered.

	:::note
	* The **Visible** is the same as the [Explosion Visible](https://create.roblox.com/docs/reference/engine/classes/Explosion#Visible)
	:::
]=]
--[=[
	@prop Debug boolean
	@within Ploder

	The **Debug** value is a boolean that indicates whether the explosion will be visualized by a red circle.
	This is used for debugging and checking the radius of the explosion.
]=]
--[=[
	@prop Hit RBXScriptSignal | Signal<BasePart, number>
	@within Ploder

	The **Hit** event fires whenever a part is caught within the explosion's range.
	It returns the Part and Distance from center to part as parameters.

	:::note
	* The **Hit** is the same as the [Explosion Hit](https://create.roblox.com/docs/reference/engine/classes/Explosion#Hit)
	:::
]=]
--[=[
	@prop RayCastOnly boolean
	@within PloderBehavior

	If true, will cast a ray on the hit parts. If the part is succesfully hit, the effects of the explosion will apply.
]=]
--[=[
	@prop OverlapParam OverlapParams
	@within PloderBehavior

	Optional [OverlapParams](https://create.roblox.com/docs/reference/engine/datatypes/OverlapParams) to set for the explosion.
]=]
--[=[
	@prop RayCastParams RaycastParams
	@within PloderBehavior

	Optional [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams) to set for the RayCastOnly setting.
	This is not needed if [PloderBehavior.RayCastOnly] is set to false.
]=]
--[=[
	@prop Filter ((Hit: BasePart, Distance: number) -> boolean)
	@within PloderBehavior

	This function will be called (if it exists) and if it returns true, the hit part will be registered.
	If it returns false, it ill be ignored and skipped.
]=]
--[=[
	@prop HumanoidOnly boolean
	@within PloderBehavior

	If true, the explosion will only register HumanoidRootParts.
]=]
--[=[
	@prop BlastPressurePercent number
	@within PloderBehavior

	If this isn't nil, it will use the percentage (number of 0-1) of this value instead of [Ploder.DestroyJointRadiusPercent].
]=]
--[=[
	@prop AffectBlastPressureDistance boolean
	@within PloderBehavior

	If true, the [Ploder.BlastPressure] value will decrease and be lower the more distanced a hit part is.
]=]
--[=[
	@prop CustomExplosion Folder | { ParticleEmitter }
	@within PloderBehavior

	If a Folder or an array of ParticleEmitters is set, they will be visualised when the explosion occurs.
	The particles inside the folder/array will need to have an attribute called "Count" with the value being the amount of particles to emit on explosion.
	The paticles will need to have an attribute callde "EmitTime" which will disable the particle emitter after the set attribute value.
]=]
--[=[
	@prop AutoDestroy number
	@within PloderBehavior

	If not nil, the [Ploder] will destroy itself after exploding and waiting for the amount of time given.
]=]
--[=[
	@prop Tags {[string]: (Hit: BasePart, Distance: number) -> nil}
	@within PloderBehavior

	This is a dictionary that has a string for keys and a function as the value.
	Whenever ploder hits a part, it will check if it has a tag (with CollectionService) from inside this table.
	If it does, it will call the function associated with the tag inside the table, and will return the part and distance.
]=]

--[=[
	@interface Ploder
	@within Ploder

	.BlastPressure number -- [Ploder.BlastPressure]
	.BlastRadius number -- [Ploder.BlastRadius]
	.DestroyJointRadiusPercent number -- [Ploder.DestroyJointRadiusPercent]
	.ExplosionType Enum.ExplosionType -- [Ploder.ExplosionType]
	.Position Vector3 -- [Ploder.Position]
	.TimeScale number -- [Ploder.TimeScale]
	.Visible boolean -- [Ploder.Visible]
	.Debug boolean -- [Ploder.Debug]

	.Hit RBXScriptSignal | Signal<BasePart, number> -- [Ploder.Hit]

	This is what the constructor returns, a table that resembles the normal [Explosion](https://create.roblox.com/docs/reference/engine/classes/Explosion).
	Every single property here is modifiable and can be customised to your liking.
]=]
--[=[
	@interface PloderBehavior
	@within PloderBehavior

	.RayCastOnly boolean -- [PloderBehavior.RayCastOnly]
	.OverlapParam OverlapParams? -- [PloderBehavior.OverlapParam]
	.RayCastParams RaycastParams? -- [PloderBehavior.RayCastParams]
	.Filter ((Hit: BasePart, Distance: number) -> boolean)? -- [PloderBehavior.Filter]
	.HumanoidOnly boolean -- [PloderBehavior.HumanoidOnly]
	.BlastPressurePercent number? -- [PloderBehavior.BlastPressurePercent]
	.AffectBlastPressureDistance boolean -- [PloderBehavior.AffectBlastPressureDistance]
	.CustomExplosion (Folder | { ParticleEmitter })? -- [PloderBehavior.CustomExplosion]
	.AutoDestroy number? -- [PloderBehavior.AutoDestroy]
	.Tags {[string]: (Hit: BasePart, Distance: number) -> nil} -- [PloderBehavior.Tags]

	This is what the behavior looks like. Everything can be customised.
]=]

export type Ploder = {
	BlastPressure: number,
	BlastRadius: number,
	DestroyJointRadiusPercent: number,
	ExplosionType: Enum.ExplosionType,
	Position: Vector3,
	TimeScale: number,
	Visible: boolean,
	Debug: boolean,

	Hit: RBXScriptSignal | Signal.Signal<BasePart, number>,

	Explode: (self: Ploder, Behavior: PloderBehavior, Position: Vector3?) -> nil,
	CalculateDamage: (self: Ploder, Position: BasePart | Vector3, Damage: NumberRange) -> number,
	Destroy: (self: Ploder) -> nil
}

export type PloderBehavior = {
	RayCastOnly: boolean,
	OverlapParam: OverlapParams?,
	RayCastParams: RaycastParams?,
	Filter: ((Hit: BasePart, Distance: number) -> boolean)?,
	HumanoidOnly: boolean,
	BlastPressurePercent: number?,
	AffectBlastPressureDistance: boolean,
	CustomExplosion: (Folder | { ParticleEmitter })?,
	AutoDestroy: number?,
	Tags: {[string]: (Hit: BasePart, Distance: number) -> nil}
}

local function ApplyPressure(
	Hit: BasePart,
	Direction: Vector3,
	Percentage: number,
	self: Ploder,
	Behavior: PloderBehavior
)
	if not Hit.Anchored then
		local Blast = Direction
			* self.BlastPressure
			* if Behavior and Behavior.AffectBlastPressureDistance then Percentage else 1

		if Hit:GetNetworkOwner() and #Hit:GetJoints() == 0 then
			Hit:SetNetworkOwner(nil)

			Hit.Touched:Once(function()
				Hit:SetNetworkOwnershipAuto()
			end)
		end

		Hit:ApplyImpulse(Blast)
	end
end

local function GetLifetime(Particles: {ParticleEmitter}): number
	local Time = 0

	for _, Particle: ParticleEmitter in pairs(Particles) do
		local EmitTime = Particle:GetAttribute("EmitTime")
		local Lifetime = Particle.Lifetime.Max + (EmitTime or 0)

		if Lifetime > Time then
			Time = Lifetime
		end
	end

	return Time
end

--[=[
	Constructs and returns a new explosion.
]=]
function Ploder.new(): Ploder
	local self = setmetatable({}, Ploder)

	-- Non Usable
	self._Trove = Trove.new()

	-- Usable
	self.BlastPressure = 10
	self.BlastRadius = 10
	self.DestroyJointRadiusPercent = 0.5
	self.ExplosionType = Enum.ExplosionType.NoCraters
	self.Position = Vector3.zero
	self.TimeScale = 0.5
	self.Visible = true
	self.Debug = false

	self.Hit = self._Trove:Construct(Signal)

	return self
end

--[=[
	Returns a new [PloderBehavior].
]=]
function Ploder.newBehavior(): PloderBehavior
	return {
		RayCastOnly = false,
		OverlapParam = nil,
		RayCastParams = nil,
		Filter = nil,
		HumanoidOnly = false,
		BlastPressurePercent = nil,
		AffectBlastPressureDistance = false,
		CustomExplosion = nil,
		AutoDestroy = nil,
		Tags = {}
	}
end

--[=[
	@method Explode
	@within Ploder

	@param Behavior PloderBehavior? -- The Optional behavior configuration.

	Fires the explosion.

	:::note
	The explosion will not self-destroy (unless set in the behavior).
	:::
]=]
function Ploder.Explode(self: Ploder, Behavior: PloderBehavior?, Position: Vector3?)
	self.Position = Position or self.Position

	local CurrentPosition: Vector3 = self.Position
	local BlastPressurePercent: number? = Behavior and Behavior.BlastPressurePercent
	local CustomExplosion: ({ Particle: ParticleEmitter } | Folder)? = Behavior and Behavior.CustomExplosion
	local AutoDestroy: number? = Behavior and Behavior.AutoDestroy
	local Tags = Behavior and Behavior.Tags

	local Result: { Part: BasePart } =
		workspace:GetPartBoundsInRadius(CurrentPosition, self.BlastRadius, Behavior and Behavior.OverlapParam)

	for _, Hit: BasePart in pairs(Result) do
		local Magnitude: number = (CurrentPosition - Hit.Position).Magnitude
		local Direction: Vector3 = (Hit.Position - CurrentPosition).Unit
		local Percentage: number = 1 - (Magnitude / self.BlastRadius)

		if Behavior then
			if Behavior.RayCastOnly then
				local RayResult =
					Option.Wrap(workspace:Raycast(CurrentPosition, Direction * self.BlastRadius, Behavior.RayCastParams))

				if RayResult:IsNone() or not RayResult:Unwrap(RayResult).Instance or RayResult:Unwrap(RayResult).Instance ~= Hit then
					continue
				end
			end
			if Behavior.HumanoidOnly and Hit.Name ~= "HumanoidRootPart" then
				continue
			end
			if Behavior.Filter and not Behavior.Filter(Hit, Magnitude) then
				continue
			end
		end

		if Percentage <= self.DestroyJointRadiusPercent then
			for _, Joint: JointInstance in pairs(Hit:GetJoints()) do
				Joint:Destroy()
			end
			if not BlastPressurePercent then
				ApplyPressure(Hit, Direction, Percentage, self, Behavior)
			end
		end

		if BlastPressurePercent and Percentage <= Behavior.BlastPressurePercent then
			ApplyPressure(Hit, Direction, Percentage, self, Behavior)
		end

		if Tags then
			for _, Tag: string in Hit:GetTags() do
				local TagFunc = Tags[Tag]

				if TagFunc then
					task.defer(function()
						TagFunc(Hit, Magnitude)
					end)
				end
			end
		end

		self.Hit:Fire(Hit, Magnitude)
	end

	if self.Visible then
		if CustomExplosion then
			local Particles: { Particle: ParticleEmitter } = if typeof(Behavior.CustomExplosion) == "Instance"
				then Behavior.CustomExplosion:GetChildren()
				else Behavior.CustomExplosion
			local Attachment = self._Trove:Add(Instance.new("Attachment"))

			Attachment.Parent = workspace.Terrain
			Attachment.WorldPosition = CurrentPosition

			for _, Particle: ParticleEmitter in pairs(Particles) do
				local Clone = Particle:Clone()
				local Count = Clone:GetAttribute("Count")
				local EmitTime = Clone:GetAttribute("EmitTime")

				Clone.Parent = Attachment
				Clone.Enabled = true

				if Count then
					Clone:Emit(Count or 1)
				end
				if EmitTime then
					task.delay(EmitTime or 1, function()
						Clone.Enabled = false
					end)
				end
			end

			Debris:AddItem(Attachment, GetLifetime(Particles))
		else
			local Ex = Instance.new("Explosion")

			Ex.BlastRadius = 0
			Ex.Position = CurrentPosition
			Ex.TimeScale = self.TimeScale
			Ex.Parent = workspace
		end
	end

	if self.ExplosionType == Enum.ExplosionType.Craters then
		workspace.Terrain:FillBall(CurrentPosition, self.BlastRadius, Enum.Material.Air)
	end

	if AutoDestroy then
		task.delay(Behavior.AutoDestroy, function()
			self:Destroy()
		end)
	end

	if self.Debug then
		local Part = self._Trove:Add(Instance.new("Part"))
		Part.Anchored = true
		Part.CanCollide = false
		Part.Size = Vector3.new(self.BlastRadius, self.BlastRadius, self.BlastRadius) * 2
		Part.Shape = Enum.PartType.Ball
		Part.Transparency = 0.5
		Part.BrickColor = BrickColor.new("Really red")
		Part.Position = CurrentPosition
		Part.Parent = workspace

		Debris:AddItem(Part, 5)
	end
end

--[=[
	@method CalculateDamage
	@within Ploder

	@param Position BasePart | Vector3 -- The part or position to calculate from.
	@param Damage NumberRange -- The min and max damage.

	@return number -- The calculated damage represented by a number
	Calculates the damage based on the distance of the position.
]=]
function Ploder.CalculateDamage(self: Ploder, Position: BasePart | Vector3, Damage: NumberRange): number
	assert(typeof(Damage) == "NumberRange", "Damage must be a NumberRange")

	local TargetType: string = typeof(Position)
	assert(
		(TargetType == "Instance" and Position:IsA("BasePart")) or TargetType == "Vector3",
		"Please provide a BasePart or Vector3"
	)

	local Target: Vector3 = if TargetType == "Instance" then Position.Position else Position
	local Magnitude: number = (self.Position - Target).Magnitude
	local Percentage: number = 1 - (Magnitude / self.BlastRadius)

	return Percentage * (Damage.Max - Damage.Min) + Damage.Min
end

--[=[
	@method Destroy
	@within Ploder

	Destroys the ploder.
]=]
function Ploder.Destroy(self: Ploder)
	self._Trove:Destroy()
	self = nil
end

return Ploder