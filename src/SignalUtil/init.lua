type ConnectionLike = {
	Disconnect: (self: ConnectionLike) -> ()
}

type SignalLike<T...> = {
	Connect: (self: SignalLike<T...>, (T...) -> (), ...unknown) -> ConnectionLike,
	Fire: (self: SignalLike<T...>, T...) -> ()
}

--[=[
	@class SignalUtil

	Useful functions for signals.
]=]
local SignalUtil = {}

--[=[
	Connects the event to the callback, automaticly disconnects after the event was fired an amount of times. 
]=]
function SignalUtil.ConnectLimited<T...>(Signal: SignalLike<T...>, Callback: (T...) -> (), Amount: number): ConnectionLike
	local Fired = 0
	local Connection: ConnectionLike

	Connection = Signal:Connect(function(...: T...)
		Fired += 1

		if Fired == Amount then
			Connection:Disconnect()
		end

		Callback(...)
	end)

	return Connection
end

--[=[
	Connects the event to the callback, automaticly disconnects after the Time amount of seconds is passed. 
]=]
function SignalUtil.ConnectUntil<T...>(Signal: SignalLike<T...>, Callback: (T...) -> (), Time: number): ConnectionLike
	local Connection = Signal:Connect(Callback)

	task.delay(Time, function()
		Connection:Disconnect()
	end)

	return Connection
end

--[=[
	Connects the event to the callback, if the callback returns true, it will disconnect the event. 
]=]
function SignalUtil.ConnectStrict<T...>(Signal: SignalLike<T...>, Callback: (T...) -> boolean): ConnectionLike
	local Connection: ConnectionLike
	
	Connection = Signal:Connect(function(...)
		local Result = Callback(...)

		if Result == true then
			Connection:Disconnect()
		end
	end)

	return Connection
end

--[=[
	Clones a signal and attaches a filter to it.
	When the original signal provided fires, the filter will be ran.
	If the filter returns true, then the copy is fired aswell, if not then it will be ignored.
]=]
function SignalUtil.FilterSignal<S, T...>(Signal: SignalLike<T...> | BindableEvent, Filter: (T...) -> boolean, SignalConstructor: (() -> S)?): S | BindableEvent
	local SignalClone = if SignalConstructor then SignalConstructor() else Instance.new("BindableEvent")
	local SignalEvent = if typeof(Signal) == "table" then Signal else (Signal :: BindableEvent).Event

	SignalEvent:Connect(function(...)
		if Filter(...) then
			SignalClone:Fire()
		end
	end)

	return SignalClone
end

return SignalUtil
