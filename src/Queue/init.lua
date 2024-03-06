--!strict
-- Version 1.0.2

local Signal = require(script.Parent.Signal)

-- Types
type Properties = {
	_Queue: { () -> () },
	_Task: thread?,
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
	table.insert(self._Queue, func)

	if self._Task == nil or coroutine.status(self._Task) == "dead" then
		self._Task = task.spawn(function()
			repeat
				self._Queue[1]()

				table.remove(self._Queue, 1)
			until #self._Queue == 0

			self.Emptied:Fire()
		end)
	end
end

--[=[
	Clears all current functions in the queue and empties it.
	The emptied event won't fire in here.
]=]
function Queue:Stop()
	if self._Task and coroutine.status(self._Task) == "running" then
		task.cancel(self._Task)
	end

	table.clear(self._Queue)
end

--[=[
	Returns a new queue.
]=]
function Queue.new(): Queue
	local self = setmetatable({}, Queue)

	self._Queue = {}
	self._Task = nil

	self.Emptied = Signal.new()

	return self
end

--[=[
	Destroys the queue.
]=]
function Queue:Destroy()
	self.Emptied:Destroy()
	self:Stop()
end

return Queue
