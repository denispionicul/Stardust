
--[=[
	@class SignalUtil

    Useful functions for signals.
]=]
local SignalUtil = {}

--[=[
    Connects the event to the callback, automaticly disconnects after the event was fired an amount of times. 
]=]
function SignalUtil.ConnectLimited<T...>(Signal: RBXScriptSignal, Callback: (T...) -> (), Amount: number): RBXScriptConnection
    local Fired = 0
    local Connection: RBXScriptConnection

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
function SignalUtil.ConnectUntil<T...>(Signal: RBXScriptSignal, Callback: (T...) -> (), Time: number): RBXScriptConnection
    local Connection = Signal:Connect(Callback)

    task.delay(Time, function()
        Connection:Disconnect()
    end)

    return Connection
end

--[=[
    Connects the event to the callback, if the callback returns true, it will disconnect the event. 
]=]
function SignalUtil.ConnectStrict<T...>(Signal: RBXScriptSignal, Callback: (T...) -> boolean): RBXScriptConnection
    local Connection: RBXScriptConnection
    
    Connection = Signal:Connect(function(...)
        local Result = Callback(...)

        if Result == true then
            Connection:Disconnect()
        end
    end)

    return Connection
end

return SignalUtil
