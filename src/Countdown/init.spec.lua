    local Countdown = require(script.Parent)

    return function()
        describe("generic countdown test", function()
            local Class = Countdown.new(1, 10)
            Class.Increment = 2
            local Fired = false

            Class.OnFinish:Once(function()
                Fired = true
            end)

            it("Should fire the OnFinished event", function()
                Class.Timer:Start()

                task.wait(6)

                expect(Class.Count).to.equal(0)
            end)

            afterAll(function()
                Class:Destroy()
            end)
        end)
    end