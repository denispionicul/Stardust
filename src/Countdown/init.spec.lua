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
                expect(Fired).to.equal(true)
            end)

            afterAll(function()
                Class:Destroy()
            end)
        end)

        describe("Countdown.Simple test", function()
            it("Should resolve itself", function()
                local Solved = false
                local Ran = 0

                Countdown.Simple(2, function()
                    Ran += 1
                end):andThen(function()
                    Solved = true
                end)

                task.wait(3)

                expect(Solved).to.equal(true)
                expect(Ran).to.equal(2)
            end)

            it("Should be cancellable", function()
                local Ran = 0

                local Promise = Countdown.Simple(10, function(Count: number)
                    Ran += 1
                end)

                task.wait(5)

                Promise:cancel()

                task.wait(2)

                expect(Ran).to.equal(4)
            end)
        end)
    end