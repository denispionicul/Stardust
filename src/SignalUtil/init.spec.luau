local SignalUtil = require(script.Parent)

return function()
    describe("test", function()
        it("Should connect limited", function()
            local Signal = Instance.new("BindableEvent")

            local Connection = SignalUtil.ConnectLimited(Signal.Event, function()
                -- nothing
            end, 3)

            for i = 1, 3 do
                Signal:Fire()
            end

            Signal:Destroy()
            expect(Connection.Connected).to.equal(false)
        end)

        it("Should connect until", function()
            local Signal = Instance.new("BindableEvent")

            local Connection = SignalUtil.ConnectUntil(Signal.Event, function()
                -- nothing
            end, 1)

            task.wait(2)

            Signal:Destroy()
            expect(Connection.Connected).to.equal(false)
        end)

        it("Should connect strict", function()
            local Signal = Instance.new("BindableEvent")

            local Connection = SignalUtil.ConnectStrict(Signal.Event, function()
                return true
            end)

            Signal:Fire()

            Signal:Destroy()
            expect(Connection.Connected).to.equal(false)
        end)

        it("should filter an event", function()
            local Signal = Instance.new("BindableEvent")
            local Fired = false

            local ClonedSignal = SignalUtil.FilterSignal(Signal, function(ShouldFire: boolean)  
                return ShouldFire
            end) :: BindableEvent
            ClonedSignal.Event:Connect(function()
                Fired = true
            end)

            Signal:Fire(false)

            expect(Fired).to.equal(false)

            Signal:Fire(true)

            expect(Fired).to.equal(true)

            ClonedSignal:Destroy()
            Signal:Destroy()
        end)
    end)
end