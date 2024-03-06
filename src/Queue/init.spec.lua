local Queue = require(script.Parent)

return function()
    local Runs = 0

    local function Test()
        Runs += 1
	    task.wait(5)
    end

    describe("test", function()
        local Class = Queue.new()
        local Fired = false

        Class.Emptied:Connect(function()
            Fired = true
        end)

        for i = 1, 5 do
            Class:Add(Test)
        end

        Class.Emptied:Wait()

        it("should fire the queued functions", function()
            expect(Runs).to.equal(5)
        end)

        it("should be empty", function()
            expect(Fired).to.equal(true)
        end)

        it("should stop", function()
            Class:Add(function()  end)

            Class:Stop()
            expect(#Class._Queue).to.equal(0)
        end)

        afterAll(function()
            Class:Destroy()
        end)
    end)
end