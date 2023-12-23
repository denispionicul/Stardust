--!strict
-- Version 1.0.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)

-- Types
type Properties = {
    _Queue: { typeof(setmetatable({} :: any, Promise)) },
    Emptied: Signal.Signal<>
}

type Module = {
    __index: Module,
    new: () -> Queue,
    Add: (self: Queue, func: () -> ()) -> (),
    Destroy: (self: Queue) -> (),
    Stop: (self: Queue) -> ()
}

export type Queue = typeof(setmetatable({} :: Properties, {} :: Module))

--[=[
	@class Queue

	Queues are a collection of functions that run in order.

	Basic Usage:
	```lua
	local Queue = require(Path.to.Queue)

	local QueueClass = Queue.new()

    QueueClass:Add(function()
        task.wait(5)
        print("function 1 finished!")
    end)

    QueueClass:Add(function()
        task.wait(10)
        print("function 2 finished!")
    end)

    -- function 1 will run, then the 2nd one
	```
]=]

--[=[
	@prop Emptied RBXScriptSignal
    @within Queue

    Fires whenever the queue runs out of functions.

    ```lua
	QueueClass.Emptied:Connect(function()
        print("Queue emptied!")
    end)
	```
]=]

local Queue: Module = {} :: Module
Queue.__index = Queue

--[=[
	Adds a function to the queue.
]=]
function Queue:Add(func: () -> ())
    local PromiseQueue = self._Queue[#self._Queue] or Promise.resolve()

    local Handler = PromiseQueue:andThenCall(func)

    table.insert(self._Queue, Handler)

    Handler:andThen(function()
        table.remove(self._Queue, table.find(self._Queue, Handler))
        if self._Queue[#self._Queue]:getStatus() == "Resolved" then
            self.Emptied:Fire()
        end
    end)
end

--[=[
	Clears all current functions in the queue and empties it.
    The emptied event won't fire in here.
]=]
function Queue:Stop()
    for _, Promise in self._Queue do
        Promise:cancel()
    end

    table.clear(self._Queue)
end

function Queue.new(): Queue
    local self = setmetatable({}, Queue)

    self._Queue = {}

    self.Emptied = Signal.new()

    return self
end

function Queue:Destroy()
    self.Emptied:Destroy()
    self:Stop()
end

return Queue
