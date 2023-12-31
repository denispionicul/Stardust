--!nonstrict
-- Version 0.5.3

-- Dependencies
local Option = require(script.Parent:FindFirstChild("Option") or script.Option)
local Promise = require(script.Parent:FindFirstChild("Promise") or script.Promise)
local Signal = require(script.Parent:FindFirstChild("Signal") or script.Signal)
local Trove = require(script.Parent:FindFirstChild("Trove") or script.Trove)

--[=[
    @class Stater

    Stater is a finite state machine module with the purpose of easing the creation of ai and npcs in games,
    Stater was built with the intent of being used in module scripts.
]=]
local Stater = {}
Stater.__index = Stater

function Stater:__tostring()
    return "Stater"
end

function Stater:__eq(Val)
    return type(Val) == "table" and getmetatable(Val) == Stater and tostring(Val) == "Stater"
end

-- Types
--[=[
    @type State (Stater | any) -> boolean?
    @within Stater
]=]

--[=[
    @interface Stater
    @within Stater
    .States {[string]: State} -- The Provided States Table, if theres a "Init" state then that function will execute each time the Stater Starts.
    .Info {any?} -- A table that you can add anything in, this is more recommended than directly inserting variables inside the object.
    .Tick number? -- The time it takes for the current state to be called again after a function is done. Default is 0
    .Return any -- This is the thing that returns as the first parameter of every single state. Default is the Stater object itself.
    .State State -- The current state that the Stater is on.
    .StateConfirmation boolean -- If this is enabled, the state MUST return a boolean indicating if the function ran properly.
    .Changed RBXScriptSignal -- A signal that fires whenever the State changes. Returns Current State and Previous State
    .StatusChanged RBXScriptSignal -- Fired whenever the Stater starts or closes. Returns the current status as a boolean.
    .StateRemoved RBXScriptSignal -- A signal that fires whenever a state is added via the Stater:AddState() method. Returns the State Name.
    .StateAdded RBXScriptSignal -- A signal that fires whenever a state is removed via the Stater:RemoveState() method. Returns the State Name.
]=]

type State<T> = (self: T?) -> boolean?

export type Stater<T> = {
    States: {[string]: State<T>},
    Info: { any? },
    Tick: number?,
    Return: T,
    State: string,
    StateConfirmation: boolean,

    Changed: Signal.Signal<string, string>, -- ignore if this is underlined
    StatusChanged: Signal.Signal<boolean>, -- ignore if this is underlined
    StateRemoved: Signal.Signal<string>, -- ignore if this is underlined
    StateAdded: Signal.Signal<string>, -- ignore if this is underlined

    RemoveState: (self: Stater<T>, Name: string) -> nil,
    AddState: (self: Stater<T>, Name: string, State: State<T>) -> nil,
    GetCurrentState: (self: Stater<T>) -> string?,
    IsWorking: (self: Stater<T>) -> boolean,
    SetState: (self: Stater<T>, Name: string) -> nil,
    Start: (self: Stater<T>, StartingState: string) -> nil,
    Stop: (self: Stater<T>) -> nil,
    Destroy: (self: Stater<T>) -> nil
}

--[=[
    Returns a new Stater Object.

    @error "No States" -- Happens when no States are provided
    @param States -- The Table that will have all the States
    @param Tick -- Optional tick to be set.
    @param Return -- Determines what to return in the first parameter of each state.
]=]
function Stater.new<T>(States: {[string]: State<T>} | Instance, Tick: number?, Return: T?): Stater<T>
    assert(type(States) == "table", "Please provide a valid table with the states.")

    local self = setmetatable({}, Stater)

    -- Non Usable
    self._Trove = Trove.new()
    self._Connections = {
        Main = nil,
    }

    -- Usable
    self.States = States
    self.Info = {}
    self.Tick = Tick or 0
    self.State = nil
    self.StateConfirmation = false
    self.Return = Return or self

    self.Changed = self._Trove:Construct(Signal)
    self.StatusChanged = self._Trove:Construct(Signal)
    self.StateRemoved = self._Trove:Construct(Signal)
    self.StateAdded = self._Trove:Construct(Signal)

    return self
end

--[=[
    Removes a state inside the states table.

    @param Name -- The name of the removing state.
]=]
function Stater:RemoveState(Name: string)
    assert(type(Name) == "string", "The name must be a string.")

    local RemovingState = Option.Wrap(self.States[Name])

    RemovingState:Match({
        ["Some"] = function(Value)
            Value = nil
            self.States[Name] = nil
            self.StateRemoved:Fire(Name)
        end,
        ["None"] = function()
            warn("Given state " .. Name .. " does not exist.")
        end,
    })
end

--[=[
    Adds a state inside the states table. If there is a Start after the State name inside the States, that will play.
    If there is a End after the State name inside the States, that will play after the state changes.

    @param Name -- The name that the state will go by.
    @param State -- The State function itself.
    @error "Existing State" -- Happens when the name of the state is already inside the table.
]=]
function Stater:AddState(Name: string, State: State)
    assert(type(Name) == "string", "The name must be a string.")
    assert(type(State) == "function", "The State must be a function.")

    local AlreadyExists = Option.Wrap(self.States[Name])
    AlreadyExists:ExpectNone("There is already a State with that name, consider changing.")

    self.States[Name] = State
    self.StateAdded:Fire(Name)
end

--[=[
    Returns the current state the Stater is on indicated by a string. If none then nil.
    This is currently the same as self.State.
]=]
function Stater:GetCurrentState(): string?
    return self.State
end

--[=[
    Returns a boolean indicating if the State currently is on.
]=]
function Stater:IsWorking(): boolean
    return self._Connections.Main ~= nil
end

--[=[
    Returns a boolean indicating if the State currently is on.

    @param State -- The function name inside States represented by a string
    @error "No State" -- Happens when no State is provided.
    @error "Invalid State" -- Happens when the state provided doesn't exist.
]=]
function Stater:SetState(State: string)
    assert(type(State) == "string", "Please provide a state when setting.")

    local StateInStates = Option.Wrap(self.States[State])

    StateInStates:Match({
        ["Some"] = function(_)
            local StartOption = Option.Wrap(self.States[State .. "Start"])
            local EndOption = Option.Wrap(self.States[tostring(self.State) .. "End"])

            StartOption:UnwrapOr(function(_) end)(self.Return)
            EndOption:UnwrapOr(function(_) end)(self.Return)
            self.Changed:Fire(State, self.State)
            self.State = State
        end,
        ["None"] = function()
            error("No State with the given name.")
        end,
    })

    StateInStates = nil
end

--[=[
    Begins the Stater

    @param StartingState string -- The function name inside States represented by a string, this state will be set at the start.
    @error "No State" -- Happens when no State is provided.
    @error "Already Started" -- Happens when the Stater has already started.
]=]
function Stater:Start(StartingState: string)
    assert(type(StartingState) == "string", "Please provide a state when starting.")
    assert(self._Connections.Main == nil, "You cannot start twice.")

    if self.States["Init"] then
        self.States["Init"](self.Return)
    end

    self:SetState(StartingState)
    self.StatusChanged:Fire(true)

    self._Connections.Main = self._Trove
        :AddPromise(Promise.try(function()
            while true do
                task.wait(self.Tick)
                local StateOption = Option.Wrap(self.States[self.State])

                if StateOption:IsSome() then
                    local Result = Option.Wrap(StateOption:Unwrap()(self.Return))

                    if self.StateConfirmation and (Result:IsNone() or Result:Contains(false)) then
                        warn("State returned false or nil, stopping...")
                        self:Stop()
                    end

                    Result = nil
                else
                    warn("Current State is not set, Please consider setting a state.")
                end
                StateOption = nil
            end
        end))
        :catch(function()
            error("There was a problem starting, please try again.")
        end)
end

--[=[
    Stops the stater and its state.

    @error "Already Stopped" -- Happens when the Stater has already been stopped.
]=]
function Stater:Stop()
    assert(self._Connections.Main ~= nil, "You cannot stop twice.")

    local StopOption = Option.Wrap(self.States.End)
    local EndOption = Option.Wrap(self.States[tostring(self.State) .. "End"])

    self._Trove:Remove(self._Connections.Main)
    self._Connections.Main:cancel()
    self._Connections.Main = nil
    self.State = nil

    StopOption:UnwrapOr(function(_) end)(self.Return)
    EndOption:UnwrapOr(function(_) end)(self.Return)

    self.StatusChanged:Fire(false)
end

--[=[
    Gets rid of the Stater Object.
]=]
function Stater:Destroy()
    self._Trove:Destroy()
    table.clear(self)
    self = nil
end

return Stater