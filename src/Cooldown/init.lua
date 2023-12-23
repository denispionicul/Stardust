--!nonstrict
--Version 1.4.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Dependencies
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)

--[=[
	@class Cooldown

	Countdown is a Debounce utility which is meant to make it easier to create Debounce easily, with minimal effort.
	Basic Usage:
	```lua
	local Cooldown = require(Path.Cooldown)

	local DebounceTime = 5
	local Debounce = Cooldown.new(DebounceTime)
	```
]=]
local Cooldown = {}
Cooldown.__index = Cooldown

export type Cooldown = {
	Time: number,
	LastActivation: number,
	AutoReset: boolean,

	OnReady: Signal.Signal,
	OnSuccess: Signal.Signal,
	OnFail: Signal.Signal,

	Reset: (self: Cooldown, Delay: number?) -> number,
	Run: (self: Cooldown, Callback: () -> nil) -> boolean,
	RunIf: (self: Cooldown, Predicate: boolean | () -> boolean, Callback: () -> nil) -> boolean,
	RunOrElse: (self: Cooldown, Callback: () -> nil, Callback2: () -> nil) -> nil,
	IsReady: (self: Cooldown) -> boolean,
	GetPassed: (self: Cooldown, Clamped: boolean?) -> number,
	GetAlpha: (self: Cooldown, Reversed: boolean?) -> number
}

--[=[
	@interface Cooldown
	@within Cooldown
	.Time number -- The time of the debounce
	.LastActivation number -- The last time the debounce reset
	.AutoReset boolean -- Whether or not the debounce should reset after running.

	.OnReady RBXScriptSignal -- Fires whenever the Cooldown can be be fired.
	.OnSuccess RBXScriptSignal -- Fires whenever a :Run() was successful.
	.OnFail RBXScriptSignal -- Fires whenever a :Run() fails.
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
function Cooldown.__tostring(_: Cooldown): string
	return "Cooldown"
end

function Cooldown.__unm(self: Cooldown): number
	return self:GetPassed(false) * -1
end

function Cooldown.__add(self: Cooldown, Value: number): number
	return self:GetPassed(false) + Value
end

function Cooldown.__sub(self: Cooldown, Value: number): number
	return self:GetPassed(false) - Value
end

function Cooldown.__mul(self: Cooldown, Value: number): number
	return self:GetPassed(false) * Value
end

function Cooldown.__div(self: Cooldown, Value: number): number
	return self:GetPassed(false) / Value
end

function Cooldown.__idiv(self: Cooldown, Value: number): number
	return math.floor(self:GetAlpha(false) / Value)
end

function Cooldown.__mod(self: Cooldown, Value: number): number
	return self:GetPassed(false) % Value
end

function Cooldown.__pow(self: Cooldown, Value: number): number
	return self:GetPassed(false) ^ Value
end

function Cooldown.__eq(self: Cooldown, Value: any): boolean
	return self:GetPassed(false) == Value
end

function Cooldown.__lt(self: Cooldown, Value: number): boolean
	return self:GetPassed(false) < Value
end

function Cooldown.__le(self: Cooldown, Value): boolean
	return self:GetPassed(false) <= Value
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
	@method Run
	@within Cooldown
	Runs the given callback function if the passed time is higher than the Time property.
	If AutoReset is true, it will call :Reset() after a successful run.

	@yields
	@param Callback () -> nil -- The function that will be called on a successful run. Will yield.
	@return boolean -- Returns a boolean indicating if the run was successful or not.
	@error "No Callback" -- Happens when no callback is provided.
]=]
function Cooldown.Run(self: Cooldown, Callback: () -> nil): boolean
	assert(type(Callback) == "function", "Callback needs to be a function.")

	if self:IsReady() then
		if self.AutoReset then
			self:Reset()
		end
		self.OnSuccess:Fire()
		Callback()

		return true
	end

	self.OnFail:Fire()
	return false
end

--[=[
	@method RunIf
	@within Cooldown
	If the given Predicate (The First parameter) is true or returns true, it will call :Run() on itself.

	@error "No Predicate" -- Happens when no Predicate, indicated by a boolean or boolean-returning function is provided.
	@error "No Callback" -- Happens when no callback is provided.

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
	@param Predicate boolean | () -> boolean -- The boolean or function that returns a boolean indicating if :Run() will be called.
	@param Callback () -> nil -- The function that will be called on a successful run. Will yield.
	@return boolean -- Returns a boolean indicating if the run was successful or not.
]=]
function Cooldown.RunIf(self: Cooldown, Predicate: boolean | () -> boolean, Callback: () -> nil): boolean
	local PredicateType = type(Predicate)
	assert(
		PredicateType == "boolean" or PredicateType == "function",
		"Please provide a boolean or function as the predicate."
	)

	local Output = if PredicateType == "function" then Predicate() else Predicate

	if Output then
		return self:Run(Callback)
	end

	return false
end

--[=[
	@method RunOrElse
	@within Cooldown
	if the :Run() will not be successful, it will instead call callback2. This won't reset the debounce.

	@error "No Callback" -- Happens when no Callback is provided.
	@error "No Callback2" -- Happens when no Callback2 is provided.

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
	@param Callback () -> nil -- The function that will be called on a successful run. Will yield.
	@param Callback2 () -> nil -- The function that will be called on a unsuccessful run. Will yield.
]=]
function Cooldown.RunOrElse(self: Cooldown, Callback: () -> nil, Callback2: () -> nil)
	assert(type(Callback2) == "function", "Callback2 needs to be a function.")

	if not self:Run(Callback) then
		Callback2()
	end
end

--[=[
	@method IsReady
	@within Cooldown
	Returns a boolean indicating if the Cooldown is ready to :Run().

	@return boolean -- Indicates if the :Run() will be successful.
]=]
function Cooldown.IsReady(self: Cooldown): boolean
	return self:GetPassed() >= self.Time
end

--[=[
	@method GetPassed
	@within Cooldown
	@param Clamped boolean -- If this is true, it will use math.clamp to make sure the value returned is min 0 and max the time.
	Returns a boolean indicating the passed time since the last :Run().

	@return number -- The passed time.
]=]
function Cooldown.GetPassed(self: Cooldown, Clamped: boolean?): number
	local Passed = os.clock() - self.LastActivation
	return if Clamped == true then math.clamp(Passed, 0, self.Time) else Passed
end

--[=[
	@method GetAlpha
	@within Cooldown
	@param Reversed boolean -- If true, will return alpha as 0 if fully ready to :Run() instead of 1.
	Returns the time before the :Run() is ready in a value between 0-1.

	@return number -- The passed time indicated by an alpha.
]=]
function Cooldown.GetAlpha(self: Cooldown, Reversed: boolean?): number
	local Passed = if Reversed then self.Time / self:GetPassed() else self:GetPassed() / self.Time
	return math.clamp(Passed, 0, 1)
end

--[=[
	Returns a boolean indicating if the given table is a Cooldown.
]=]
function Cooldown.Is(Object: any): boolean
	return getmetatable(Object) == Cooldown
end

--[=[
	@method Destroy
	@within Cooldown
	Destroys the Cooldown.
]=]
function Cooldown.Destroy(self: Cooldown)
	self._Trove:Destroy()
	table.clear(self)
	self = nil
end

return Cooldown