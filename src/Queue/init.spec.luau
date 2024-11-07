local Queue = require(script.Parent)

return function()
	local Runs = 0

	local function Test()
		Runs += 1
		task.wait(5)
	end

	describe("queue test", function()
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
			Class:Add(function() end)

			Class:Stop()
			expect(#Class.Queue).to.equal(0)
		end)

		it("should have a returned value", function()
			expect(Returned).to.equal(1)
		end)

		it("should run with args and return", function()
			local Returned = false

			Class.Returned:Once(function()
				Returned = true
			end)

			expect(function()
				Class:Add(task.wait, 0)
			end).never.to.throw()

			task.wait(1)

			expect(Returned).never.to.equal(nil)
		end)

		afterAll(function()
			Class:Destroy()
		end)
	end)

	describe("queue prompt test", function()
		local Class = Queue.new()

		it("should timeout", function()
			local Fired = false

			Class:Add(task.wait, 1)
			Class:Add(function()
				Fired = true
			end):Timeout(0.5)

			task.wait(2)

			expect(Fired).to.equal(false)
		end)

		it("should disconnect", function()
			local Fired = false

			Class:Add(task.wait, 5)
			Class:Add(function()
				Fired = true
			end):Destroy()

			Class.Emptied:Wait()

			expect(Fired).to.equal(false)
		end)

		it("should respect priorities", function()
			local Val = 0
			
			Class:Stop()
			Class:Add(task.wait, 5)
			Class:Add(function() 
				Val = 1
			end)
			Class:Add(function() 
				Val = 2
			end):SetPriority(2)

			Class.Emptied:Wait()

			expect(Val).to.equal(1)
		end)

		afterAll(function()
			Class:Destroy()
		end)
	end)

	describe("Promise queue test", function()
		local Class = Queue.new()

		it("should solve", function()
			local solved = false

			Class:PromiseAdd(function()
				return true
			end)
				:andThen(function(bool)
					solved = bool
				end)

            task.wait(1)

			expect(solved).to.equal(true)
		end)

		it("should cancel", function()
			local Fired = false

			Class:Add(task.wait, 1)
			local Promise = Class:PromiseAdd(function()
				Fired = true
			end)

			Promise:cancel()

			task.wait(2)

			expect(Fired).to.equal(false)
		end)

		afterAll(function()
			Class:Destroy()
		end)
	end)
end
