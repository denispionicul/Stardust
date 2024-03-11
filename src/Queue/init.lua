--!strict
-- Version 1.3.0

local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)

-- Types
type Promise = typeof(Promise.new(function() end))

type QueueFunc = { ((...unknown) -> ...unknown) | unknown }

type QueueProperties = {
	_Queue: { QueuePrompt },
	_Task: thread?,
	_FuncRan: Signal.Signal<QueuePrompt, { unknown }>,

	Emptied: Signal.Signal<nil>,
	Returned: Signal.Signal<...unknown>,
	Switched: Signal.Signal<nil>
}

type QueueModule = {
	__index: QueueModule,
	new: () -> Queue,
	Add: <T...>(self: Queue, func: (T...) -> ...any, T...) -> QueuePrompt,
	PromiseAdd: <T...>(self: Queue, func: (T...) -> any, T...) -> Promise,
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

--[=[
	@prop Switched RBXScriptSignal
	@within Queue
	@since v1.3.0

	Fires whenever the queue moves onto the next function.

	```lua
	QueueClass.Switched:Connect(function()
		print("Queue moved onto the next function.")
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
		self._Task = task.defer(function()
			repeat
				self.Switched:Fire()

				local QueueArray = self._Queue[1]
				local Return = { QueueArray:_Run() }

				if #Return ~= 0 then
					self.Returned:Fire(table.unpack(Return))
				end

				self._FuncRan:Fire(QueueArray, Return)

				table.remove(self._Queue, 1)
			until #self._Queue == 0

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

return Queue
