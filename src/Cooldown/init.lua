--!strict
--Version 2.0.1

--Dependencies
local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)
local WaitFor = require(script.Parent.WaitFor)

--[=[
	@class Cooldown

	Countdown is a Debounce utility which helps with cooldowns.
	Basic Usage:
	```lua
	local Cooldown = require(Path.Cooldown)

	local DebounceTime = 5
	local Debounce = Cooldown.new(DebounceTime)

	Debounce:Run(function()
		print("Ran!")
	end)

	Debounce:Run(function()
		print("Ran Again!")
	end)

	-- Output:
	-- Ran!
	```
]=]

type Module = {
	__index: Module,
	new: (Time: number, AutoReset: boolean?) -> Cooldown,
	Reset: (self: Cooldown, Delay: number?) -> number,
	Run: <Args...>(self: Cooldown, Callback: (Args...) -> (), Args...) -> boolean,
	RunIf: <Args...>(self: Cooldown, Predicate: boolean | () -> boolean, Callback: (Args...) -> (), Args...) -> boolean,
	RunOrElse: (self: Cooldown, Callback: () -> (), Callback2: () -> ()) -> (),
	IsReady: (self: Cooldown) -> boolean,
	GetPassed: (self: Cooldown, Clamped: boolean?) -> number,
	GetAlpha: (self: Cooldown, Reversed: boolean?) -> number,
	Destroy: (self: Cooldown) -> (),

	__tostring: (self: Cooldown) -> "Cooldown",
	__call: <Args...>(self: Cooldown, Callback: (Args...) -> (), Args...) -> boolean,
}

type Properties = {
	_Trove: typeof(Trove.new()),
	_Connections: { [string]: any },

	Time: number,
	LastActivation: number,
	AutoReset: boolean,

	OnReady: Signal.Signal<nil>,
	OnSuccess: Signal.Signal<nil>,
	OnFail: Signal.Signal<nil>,
}

local Cooldown: Module = {} :: Module
Cooldown.__index = Cooldown

export type Cooldown = typeof(setmetatable({} :: Properties, {} :: Module))

--[=[
	@interface Cooldown
	@within Cooldown
	.Time number -- The time of the debounce
	.LastActivation number -- The last time the debounce reset
	.AutoReset boolean -- Whether or not the debounce should reset after running.

	.OnReady RBXScriptSignal | Signal -- Fires whenever the Cooldown can be be fired.
	.OnSuccess RBXScriptSignal | Signal -- Fires whenever a :Run() was successful.
	.OnFail RBXScriptSignal | Signal -- Fires whenever a :Run() fails.
]=]

--[=[
	@prop Time number
	@within Cooldown
	The time property signifies how much time is needed to wait before using :Run()

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5) -- The first parameter is the Time
	-- Can be changed with Debounce.Time = 5

	Debounce:Run(function()
		print("This will run")  -- prints
	end)

	Debounce:Run(function()
		print("This won't run")  -- won't print because the debounce hasn't finished waiting 5 seconds
	end)
	```

	:::note
		Calling :Run() when the debounce isn't ready won't yield.
	:::
]=]

--[=[
	@prop AutoReset boolean
	@within Cooldown
	When AutoReset is on, the debounce will reset after a successful Run() call.

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5)
	Debounce.AutoReset = false

	-- Keep in mind you can also set the AutoReset by the second parameter in the constructor: Cooldown.new(5, false)

	Debounce:Run(function()
		print("This will run")  -- prints
	end)

	Debounce:Run(function()
		print("This will still run")  -- still prints because AutoReset is false and the debounce did not reset
	end)

	Debounce:Reset() -- Reset the debounce
	```
]=]

-- Metamethods
function Cooldown.__tostring(_: Cooldown): "Cooldown"
	return "Cooldown"
end

Cooldown.__call = Cooldown.Run

-- Constructor and Methods
--[=[
	Returns a new Cooldown.

	@param Time number -- The time property, for more info check the "Time" property.
	@param AutoReset boolean? -- Sets the AutoReset value to the boolean provided, please refer to [Cooldown.AutoReset]
	@error "No Time" -- Happens when no Time property is provided.
]=]
function Cooldown.new(Time: number, AutoReset: boolean?): Cooldown
	assert(type(Time) == "number", "You must provide a number for the Time")

	local self = setmetatable({}, Cooldown)

	--Non Usable
	self._Trove = Trove.new()
	self._Connections = {
		OnReadyHandler = nil,
	}

	-- Usable
	self.Time = Time
	self.LastActivation = 0
	self.AutoReset = AutoReset or true

	self.OnReady = self._Trove:Construct(Signal)
	self.OnSuccess = self._Trove:Construct(Signal)
	self.OnFail = self._Trove:Construct(Signal)

	return self
end

--[=[
	@method Reset
	@within Cooldown
	Resets the debounce. Just like calling a sucessful :Run() with AutoReset set to true
	If a delay is provided, the debounce will be delayed by the provided number. A delay will only last once.
	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce: Cooldown = Cooldown.new(2)
	Debounce.AutoReset = false

	Debounce:Run(function()
		print("This will run")  -- prints
	end)

	Debounce:Reset(1) -- We reset it and delay it by 1

	Debounce.OnReady:Wait() -- We wait 3 seconds instead of 2, because we delay it by 1.
	-- You can think of delaying as adding time + delay which would be 2 + 1 in our case
	-- Delaying will not change the time.

	Debounce:Run(function()
		print("This will run")  -- will print because the :Run will be ready.
	end)
	```

	@param Delay number? -- The amount of delay to add to the Time
	@return number -- The cooldown time + delay.
]=]
function Cooldown.Reset(self: Cooldown, Delay: number?): number
	local DelayNumber = Delay or 0

	self.LastActivation = os.clock() + DelayNumber

	task.defer(function()
		if self._Connections.OnReadyHandler then
			self._Connections.OnReadyHandler:cancel()
		end

		self._Connections.OnReadyHandler = self._Trove:AddPromise(WaitFor.Custom(function()
			return self:IsReady() or nil
		end)):andThen(function()
			self.OnReady:Fire()
		end)
	end)

	return self.Time + DelayNumber
end

--[=[
	Runs the given callback function if the passed time is higher than the Time property.
	If AutoReset is true, it will call :Reset() after a successful run.

	@yields
]=]
function Cooldown:Run<Args...>(Callback: (Args...) -> (), ...: any): boolean
	assert(type(Callback) == "function", "Callback needs to be a function.")

	if self:IsReady() then
		if self.AutoReset then
			self:Reset()
		end
		self.OnSuccess:Fire()
		Callback(...)

		return true
	end

	self.OnFail:Fire()
	return false
end

--[=[
	If the given Predicate (The First parameter) is true or returns true, it will call :Run() on itself.

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5)
	Debounce.AutoReset = false

	Debounce:RunIf(true, function()
		print("This will run")  -- prints
	end)

	Debounce:RunIf(false, function()
		print("This will not run")  -- does not print because the first parameter (Predicate) is false.
	end)
	```

	@yields
]=]
function Cooldown:RunIf<Args...>(Predicate: boolean | () -> boolean, Callback: (Args...) -> (), ...: any): boolean
	local PredicateType = type(Predicate)
	assert(
		PredicateType == "boolean" or PredicateType == "function",
		"Please provide a boolean or function as the predicate."
	)

	local Output = if PredicateType == "function" then (Predicate :: () -> boolean)() else Predicate

	if Output then
		return self:Run(Callback, ...)
	end

	return false
end

--[=[
	if the :Run() will not be successful, it will instead call callback2. This won't reset the debounce.

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5)

	Debounce:RunOrElse(function()
		print("This will run")  -- prints
	end, function()
		print("This will not print") -- doesn't print because the :Run() will be successful.
	end)

	Debounce:RunOrElse(function()
		print("This will not run")  -- does not print because the debounce hasn't finished waiting.
	end, function()
		print("This will run") -- will print because the :Run() failed.
	end)
	```

	@yields
]=]
function Cooldown:RunOrElse(Callback: () -> (), Callback2: () -> ())
	assert(type(Callback2) == "function", "Callback2 needs to be a function.")

	if not self:Run(Callback) then
		Callback2()
	end
end

--[=[
	Returns a boolean indicating if the Cooldown is ready to :Run().
]=]
function Cooldown:IsReady(): boolean
	return self:GetPassed() >= self.Time
end

--[=[
	@param Clamped boolean -- If this is true, it will use math.clamp to make sure the value returned is min 0 and max the time.
	Returns a boolean indicating the passed time since the last :Run().
]=]
function Cooldown:GetPassed(Clamped: boolean?): number
	local Passed = os.clock() - self.LastActivation
	return if Clamped == true then math.clamp(Passed, 0, self.Time) else Passed
end

--[=[
	@param Reversed boolean -- If true, will return alpha as 0 if fully ready to :Run() instead of 1.
	Returns the time before the :Run() is ready in a value between 0-1.
]=]
function Cooldown:GetAlpha(Reversed: boolean?): number
	local Passed = if Reversed then self.Time / self:GetPassed() else self:GetPassed() / self.Time
	return math.clamp(Passed, 0, 1)
end

--[=[
	Destroys the Cooldown.
]=]
function Cooldown:Destroy()
	self._Trove:Destroy()
end

return Cooldown