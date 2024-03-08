--!strict
-- Version 1.2.0

local Signal = require(script.Parent.Signal)

-- Types
type QueueFunc = { ((...unknown) -> ...unknown) | unknown }

type QueueProperties = {
	_Queue: { QueuePrompt },
	_Task: thread?,

	Emptied: Signal.Signal,
	Returned: Signal.Signal<...unknown>
}

type QueueModule = {
	__index: QueueModule,
	new: () -> Queue,
	Add: <T...>(self: Queue, func: (T...) -> ...any, T...) -> QueuePrompt,
	Destroy: (self: Queue) -> (),
	Stop: (self: Queue) -> ()
}

export type Queue = typeof(setmetatable({} :: QueueProperties, {} :: QueueModule))

type QueuePromptProperties = {
	Func: QueueFunc,
	Queue: Queue
}

type QueuePromptModule = {
	__index: QueuePromptModule,
	new: (Queue: Queue, QueueFunc: QueueFunc) -> QueuePrompt,
	Timeout: (self: QueuePrompt, time: number) -> QueuePrompt,
	_Run: (self: QueuePrompt) -> ...unknown,
	Destroy: (self: QueuePrompt) -> ()
}

export type QueuePrompt = typeof(setmetatable({} :: QueuePromptProperties, {} :: QueuePromptModule))

--[=[
	@class QueuePrompt

	This is what's returned from the Queue:Add() method. It can be used to add timeouts to the added function
	or cancel it.

	Basic Usage:
	```lua
	local Queue = require(Path.to.Queue)

	local QueueClass = Queue.new()

	QueueClass:Add(task.wait, 5)

	local Prompt = QueueClass:Add(function()
		print("Ran")
	end):Timeout(1)

	-- "Ran" never gets printed because while the first function yields for 5 seconds,
	-- the second gets removed after 1 second

	-- it can also be manually disconnected with :Destroy()

	task.wait(0.5)

	Prompt:Destroy()
	```
]=]
local QueuePrompt: QueuePromptModule = {} :: QueuePromptModule
QueuePrompt.__index = QueuePrompt

function QueuePrompt:_Run(): ...unknown
	return (self.Func[1] :: () -> ...unknown)(table.unpack(self.Func, 2))
end

--[=[
	@within QueuePrompt

	Disconnects the function after a given amount of time	
]=]
function QueuePrompt:Timeout(time: number): QueuePrompt
	task.delay(time, function()
		self:Destroy()
	end)

	return self
end

function QueuePrompt.new(Queue: Queue, QueueFunc: QueueFunc): QueuePrompt
	local self = setmetatable({}, QueuePrompt)

	self.Func = QueueFunc
	self.Queue = Queue

	return self
end

--[=[
	@within QueuePrompt
	Disconnects the function immediately
]=]
function QueuePrompt:Destroy()
	local Index = table.find(self.Queue._Queue, self)

	if Index then
		table.remove(self.Queue._Queue, Index)
	end
end

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

--[=[
	@prop Returned RBXScriptSignal
	@within Queue
	@since v1.1.0

	Fires whenever a function in the queue returns a value.

	```lua
	QueueClass.Returned:Connect(function(...)
		print("Queue returned a value" )
		print(...)
	end)
	```
]=]

local Queue: QueueModule = {} :: QueueModule
Queue.__index = Queue

--[=[
	@within Queue
	Adds a function to the queue.
]=]
function Queue:Add<T...>(func: (T...) -> ...any, ...: any): QueuePrompt
	local QueuePromptInstance = QueuePrompt.new(self, { func, ... }) 

	table.insert(self._Queue, QueuePromptInstance)

	if self._Task == nil or coroutine.status(self._Task) == "dead" then
		self._Task = task.spawn(function()
			repeat
				local QueueArray = self._Queue[1]
				local Return = { QueueArray:_Run() }

				if #Return ~= 0 then
					self.Returned:Fire(table.unpack(Return))
				end

				table.remove(self._Queue, 1)
			until #self._Queue == 0

			self.Emptied:Fire()
		end)
	end

	return QueuePromptInstance
end

--[=[
	@within Queue

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
	@within Queue

	Returns a new queue.
]=]
function Queue.new(): Queue
	local self = setmetatable({}, Queue)

	self._Queue = {}
	self._Task = nil

	self.Emptied = Signal.new()
	self.Returned = Signal.new()

	return self
end

--[=[
	@within Queue

	Destroys the queue.
]=]
function Queue:Destroy()
	self:Stop()
	self.Returned:Destroy()
	self.Emptied:Destroy()
end

return Queue
