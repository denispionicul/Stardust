--!strict
-- Version 1.4.0

local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)

-- Types
type Promise = typeof(Promise.new(function() end))

type QueueFunc = { ((...unknown) -> ...unknown) | unknown }

type QueueProperties = {
	Queue: { QueuePrompt },
	_Task: thread?,
	_FuncRan: Signal.Signal<QueuePrompt, { unknown }>,
	_DifferentPriorities: number,

	Emptied: Signal.Signal<()>,
	Returned: Signal.Signal<...unknown>,
	Switched: Signal.Signal<QueuePrompt>
}

type QueueModule = {
	__index: QueueModule,
	new: () -> Queue,
	_GetHighestPriorityPrompt: (self: Queue) -> (QueuePrompt, number),
	Add: <T...>(self: Queue, func: (T...) -> ...any, T...) -> QueuePrompt,
	PromiseAdd: <T...>(self: Queue, func: (T...) -> any, T...) -> Promise,
	Destroy: (self: Queue) -> (),
	Stop: (self: Queue) -> ()
}

export type Queue = typeof(setmetatable({} :: QueueProperties, {} :: QueueModule))

type QueuePromptProperties = {
	Func: QueueFunc,
	Queue: Queue,
	Priority: number,
	Running: boolean,
}

type QueuePromptModule = {
	__index: QueuePromptModule,
	new: (Queue: Queue, QueueFunc: QueueFunc) -> QueuePrompt,
	Timeout: (self: QueuePrompt, time: number) -> QueuePrompt,
	SetPriority: (self: QueuePrompt, Value: number) -> QueuePrompt,
	_Run: (self: QueuePrompt) -> ...unknown,
	Destroy: (self: QueuePrompt) -> ()
}

export type QueuePrompt = typeof(setmetatable({} :: QueuePromptProperties, {} :: QueuePromptModule))

--[=[
	@class QueuePrompt
	@since v1.2.0

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

--[=[
	@within QueuePrompt
	Sets the queue priority. When a queue goes to the next prompt, it'll pick the one with the highest Priority.
]=]
function QueuePrompt:SetPriority(Value: number)
	if Value == self.Priority then
		return self
	end

	self.Priority = Value

	if Value ~= 1 then
		self.Queue._DifferentPriorities += 1
	else
		self.Queue._DifferentPriorities -= 1
	end

	return self
end

function QueuePrompt:_Run(): ...unknown
	self.Running = true

	if self.Priority ~= 1 then
		self.Queue._DifferentPriorities -= 1
	end

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

--[=[
	@prop Running boolean
	@within QueuePrompt
	@since v1.4.0
	
	A boolean representing if the current function is running
]=]

--[=[
	@prop Priority number
	@within QueuePrompt
	@since v1.4.0
	@readonly
	
	The queue's priority.
]=]
function QueuePrompt.new(Queue: Queue, QueueFunc: QueueFunc): QueuePrompt
	local self = setmetatable({}, QueuePrompt)

	self.Func = QueueFunc
	self.Queue = Queue
	self.Priority = 1
	self.Running = false

	return self
end

--[=[
	@within QueuePrompt
	Disconnects the function immediately
]=]
function QueuePrompt:Destroy()
	local Index = table.find(self.Queue.Queue, self)

	if self.Priority ~= 1 and not self.Running then
		self.Queue._DifferentPriorities -= 1
	end

	if Index then
		table.remove(self.Queue.Queue, Index)
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
	@prop Queue { QueuePrompt }
	@within Queue
	@since v1.4.0

	A table of the current prompts that are in queue
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

--[=[
	@prop Switched RBXScriptSignal
	@within Queue
	@since v1.3.0

	Fires whenever the queue moves onto the next function.
	Gives the queue prompt as the parameter

	```lua
	QueueClass.Switched:Connect(function(Prompt)
		print("Queue moved onto the next function.", Prompt.Priority)
	end)
	```
]=]
local Queue: QueueModule = {} :: QueueModule
Queue.__index = Queue

function Queue:_GetHighestPriorityPrompt(): (QueuePrompt, number)
	if self._DifferentPriorities == 0 then
		return self.Queue[1], 1
	end

	local BestQueue, Priority, Index = nil, 0, 1

	for QueueIndex, Prompt in self.Queue do
		if Prompt.Priority > Priority then
			BestQueue = Prompt
			Priority = Prompt.Priority
			Index = QueueIndex
		end
	end

	return BestQueue :: QueuePrompt, Index
end

--[=[
	@within Queue
	Adds a function to the queue.
]=]
function Queue:Add<T...>(func: (T...) -> ...any, ...: any): QueuePrompt
	local QueuePromptInstance = QueuePrompt.new(self, { func, ... }) 

	table.insert(self.Queue, QueuePromptInstance)

	if self._Task == nil or coroutine.status(self._Task) == "dead" then
		self._Task = task.defer(function()
			repeat
				local QueueArray, Index = self:_GetHighestPriorityPrompt()
				self.Switched:Fire(QueueArray)
				local Return = { QueueArray:_Run() }

				if #Return ~= 0 then
					self.Returned:Fire(table.unpack(Return))
				end

				self._FuncRan:Fire(QueueArray, Return)

				if self.Queue[Index] ~= QueueArray then
					Index = table.find(self.Queue, QueueArray) :: number
				end

				if Index then
					table.remove(self.Queue, Index)
				end
			until #self.Queue == 0

			self.Emptied:Fire()
		end)
	end

	return QueuePromptInstance
end

--[=[
	@within Queue
	Adds a function to the queue, but instead of returning a QueuePrompt it returns a Promise.
	The promise resolves with whatever the function returned once the function has ran inside the queue.
	If the promise is canceled, it will remove itself from the queue.
]=]
function Queue:PromiseAdd<T...>(func: (T...) -> ...any, ...: any): Promise
	local Args = { ... }

	local Connection
	local Promise = Promise.new(function(resolve, reject, onCancel)
		local QueuePromptInstance = self:Add(func, table.unpack(Args))

		Connection = self._FuncRan:Connect(function(GivenQueuePrompt, Return)  
			if GivenQueuePrompt == QueuePromptInstance then
				Connection:Disconnect()
				resolve(table.unpack(Return))
			end
		end)

		onCancel(function()
			QueuePromptInstance:Destroy()
			Connection:Disconnect()
		end)
	end)

	return Promise
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

	table.clear(self.Queue)
end

--[=[
	@within Queue

	Returns a new queue.
]=]
function Queue.new(): Queue
	local self = setmetatable({}, Queue)

	self.Queue = {}
	self._Task = nil
	self._DifferentPriorities = 0
	self._FuncRan = Signal.new()

	self.Emptied = Signal.new()
	self.Returned = Signal.new()
	self.Switched = Signal.new()

	return self
end

--[=[
	@within Queue

	Destroys the queue.
]=]
function Queue:Destroy()
	self:Stop()
	self._FuncRan:Destroy()
	self.Switched:Destroy()
	self.Returned:Destroy()
	self.Emptied:Destroy()
end

return {
	new = Queue.new,
}
