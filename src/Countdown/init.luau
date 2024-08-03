local Timer = require(script.Parent.Timer)
local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)
local Promise = require(script.Parent.Promise)

type Timer = typeof(Timer.new(1))

type Module = {
	__index: Module,
	new: (Interval: number, StartingCount: number) -> Countdown,
	Simple: (StartCount: number, CheckFunction: (Count: number) -> boolean, Interval: number?, IncrementNumber: number?, StartsNow: boolean?) -> any,
	Start: (self: Countdown) -> (),
	StartNow: (self: Countdown) -> (),
	Stop: (self: Countdown) -> (),
	IsRunning: (self: Countdown) -> boolean,
	Destroy: (self: Countdown) -> ()
}

type Properties = {
	_Trove: Trove.Trove,
	Timer: Timer,
	Count: number,
	MaxCount: number,
	Increment: number,

	OnFinish: Signal.Signal<nil>,
	Tick: Signal.Signal<number>,
	Started: Signal.Signal<nil>,
	Stopped: Signal.Signal<nil>
}

export type Countdown = typeof(setmetatable({} :: Properties, {} :: Module))

--[=[
	@interface Countdown
	@within Countdown
	.Timer Timer -- the [Timer](https://sleitnick.github.io/RbxUtil/api/Timer) object, should be used for modifying things such as the Interval, TimeFunction, UpdateSignal and AllowDrift.
	.Count number -- The current number the countdown is at
	.MaxCount number -- The maximum the count can reach
	.Increment number -- The amount that the count decreases every tick
	
	.OnFinish Signal -- Fires whenever the count reaches 0
	.Tick Signal<number> -- Same as the [Timer.Tick](https://sleitnick.github.io/RbxUtil/api/Timer/#Tick) property, but with the guarantee that it will fire after the count updates, it also returns the current count as a parameter.
	.Started Signal -- Fires whenever the :Start() or :StartNow() method is called.
	.Stopped Signal -- Fires whenever :Stop() is called (or the countdown finished).
]=]

--[=[
	@class Countdown

	Countdown is a useful class for managing, well, countdown. It uses [Rbxutil's Timer](https://sleitnick.github.io/RbxUtil/api/Timer) internally.
]=]
local Countdown: Module = {} :: Module
Countdown.__index = Countdown

--[=[
	Creates a simple timer that returns a promise. Every single interval (default of 1 second), the check function is ran.
	The check function will have as a parameter a Count, indicating the current count of the timer. The check function
	should return a boolean, indicating if it will keep running. A DecrementNumber can be provided (defaults to 1) which
	says how much the timer should decrease the count everytime the CheckFunction is ran.
	If StartNow is true, the check function will run immediately.
	The returned promise resolves once the timer reaches 0 and it can be canceled.
]=]
function Countdown.Simple(StartCount: number, CheckFunction: (Count: number) -> boolean, Interval: number?, DecrementNumber: number?, StartsNow: boolean?): any
	DecrementNumber = DecrementNumber or 1
	Interval = Interval or 1
	local TimerConnection: RBXScriptConnection
	local ResolveFunc

	local ReturningPromise = Promise.new(function(Resolve, Reject, onCancel)
		ResolveFunc = Resolve
		onCancel(function()
			TimerConnection:Disconnect()
		end)
	end)

	TimerConnection = Timer.Simple(Interval :: number, function()
		StartCount -= DecrementNumber :: number
		if CheckFunction(StartCount) == false then
			ReturningPromise:cancel()
			return
		end

		if StartCount <= 0 then
			ResolveFunc()
			TimerConnection:Disconnect()
			return
		end
	end, StartsNow)

	return ReturningPromise
end

--[=[
	Creates a new countdown object.
]=]
function Countdown.new(Interval: number, StartingCount: number): Countdown
	local self = setmetatable({}, Countdown)

	self._Trove = Trove.new()

	self.Timer = self._Trove:Construct(Timer, Interval) :: Timer
	self.Timer.Interval = Interval
	self.Count = StartingCount
	self.MaxCount = math.huge
	self.Increment = 1

	self.OnFinish = self._Trove:Construct(Signal)
	self.Tick = self._Trove:Construct(Signal)
	self.Started = self._Trove:Construct(Signal)
	self.Stopped = self._Trove:Construct(Signal)

	self._Trove:Connect(self.Timer.Tick, function()  
		self.Count = math.clamp(self.Count - self.Increment, 0, self.MaxCount)

		self.Tick:Fire(self.Count)

		if self.Count == 0 then
			self.OnFinish:Fire()
			self:Stop()
		end
	end)

	return self
end

function Countdown:IsRunning()
	return self.Timer:IsRunning()
end

--[=[
	Stops the countdown 
]=]
function Countdown:Stop()
	if self:IsRunning() then
		self.Stopped:Fire()
	end
	self.Timer:Stop()
end

--[=[
	Starts the countdown and fires the .Tick signal immediately. 
]=]
function Countdown:StartNow()
	if not self:IsRunning() then
		self.Started:Fire()
	end
	self.Timer:StartNow()
end

--[=[
	Starts the countdown. 
]=]
function Countdown:Start()
	if not self:IsRunning() then
		self.Started:Fire()
	end
	self.Timer:Start()
end

--[=[
	Destroys the countdown instance.
]=]
function Countdown:Destroy()
	self._Trove:Destroy()
end


return Countdown
