local Queue = require(script.Parent)

return function()
    local Runs = 0

    local function Test()
        Runs += 1
	    task.wait(5)
    end

    describe("test", function()
        local Class = Queue.new()

        local Returned = nil

        Class.Returned:Connect(function(thing)
            Returned = thing
        end)

        for i = 1, 5 do
            Class:Add(Test)
        end
        Class:Add(function()
            return 1
        end)

        Class.Emptied:Wait()

        it("should fire the queued functions", function()
            expect(Runs).to.equal(5)
        end)

        it("should be empty", function()
            expect(#Class._Queue).to.equal(0)
        end)

        it("should stop", function()
            Class:Add(function()  end)

            Class:Stop()
            expect(#Class._Queue).to.equal(0)
        end)

        it("should have a returned value", function()
            expect(Returned).to.equal(1)
        end)

        afterAll(function()
            Class:Destroy()
        end)
    end)
end