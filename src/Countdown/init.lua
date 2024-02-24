local Timer = require(script.Parent.Timer)
local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)

type Trove = typeof(Trove.new())
type Timer = typeof(Timer.new(1))

type Module = {
	__index: Module,
	new: (Interval: number, StartingCount: number) -> Countdown,
	Destroy: (self: Countdown) -> ()
}

type Properties = {
	_Trove: Trove,
	Timer: Timer,
	Count: number,
	MaxCount: number,
	Increment: number,

	OnFinish: Signal.Signal<nil>,
	Tick: Signal.Signal<number>
}

export type Countdown = typeof(setmetatable({} :: Properties, {} :: Module))

--[=[
	@interface Countdown
	@within Countdown
	.Timer Timer -- the [Timer](https://sleitnick.github.io/RbxUtil/api/Timer) object, should be used for starting the countdown and stopping it.
	.Count number -- The current number the countdown is at
	.MaxCount number -- The maximum the count can reach
	.Increment number -- The amount that the count decreases every tick
	
	.OnFinish Signal -- Fires whenever the count reaches 0
	.Tick Signal<number> -- Same as the [Timer.Tick](https://sleitnick.github.io/RbxUtil/api/Timer/#Tick) property, but with the guarantee that it will fire after the count updates, it also returns the current count as a parameter.
]=]

--[=[
	@class Countdown

	Countdown is a useful class for managing, well, countdown. It is a modified version or [Rbxutil's Timer](https://sleitnick.github.io/RbxUtil/api/Timer).
]=]
local Countdown: Module = {} :: Module
Countdown.__index = Countdown

--[=[
	Creates a new countdown object.
]=]
function Countdown.new(Interval: number, StartingCount: number): Countdown
	local self = setmetatable({}, Countdown)

	self._Trove = Trove.new() :: Trove

	self.Timer = self._Trove:Construct(Timer, Interval) :: Timer
	self.Timer.Interval = Interval
	self.Count = StartingCount
	self.MaxCount = math.huge
	self.Increment = 1

	self.OnFinish = self._Trove:Construct(Signal)
	self.Tick = self._Trove:Construct(Signal)

	self._Trove:Connect(self.Timer.Tick, function()  
		self.Count = math.clamp(self.Count - self.Increment, 0, self.MaxCount)

		self.Tick:Fire(self.Count)

		if self.Count == 0 then
			self.OnFinish:Fire()
			self.Timer:Stop()
		end
	end)

	return self
end

--[=[
	Destroys the countdown instance.
]=]
function Countdown:Destroy()
	self._Trove:Destroy()
	self = nil
end


return Countdown
