return function()
	local CooldownModule = require(script.Parent)
	local Cooldown: CooldownModule.Cooldown = CooldownModule.new(2)

	describe("Basic Debouce", function()
		it("Should result in true, cooldown is 0 at start", function()
			expect(Cooldown:Run(function() end)).to.equal(true)
		end)
		it("Should Result in false, cooldown has been exceeded", function()
			expect(Cooldown:Run(function() end)).to.equal(false)
		end)
		it("Should be resseting", function()
			expect(function()
				Cooldown:Reset()
			end).never.to.throw()
		end)
	end)

	describe("Metamethods", function()
		it("Should return a number", function()
			expect(Cooldown + 10).to.be.a("number")
		end)
	end)

	describe("Util Functions", function()
		it("Should run with an if statement, print true", function()
            local Succed = false
            task.wait(2.5)
            Cooldown:RunIf(true, function()
                Succed = true
            end)
			expect(Succed).to.equal(true)
        end)
		it("Should run the other function, cooldonw not ready", function()
			local Result = false
			Cooldown:RunOrElse(function() end, function()
				Result = true
			end)

			expect(Result).to.equal(true)
		end)
		it("Should result false when calling is ready.", function()
			expect(Cooldown:IsReady()).to.equal(false)
		end)
		it("Should result true when calling Is", function()
			expect(CooldownModule.Is(Cooldown)).to.equal(true)
		end)
		it("Should return the passed value", function()
			task.wait(2)
			local val = Cooldown:GetPassed()

			expect(val).to.be.near(Cooldown.Time, 3)
		end)
		it("Should return the alpha", function()
			Cooldown:Reset()
			Cooldown.OnReady:Wait()
			local val = Cooldown:GetAlpha()

			expect(val).to.be.near(0, 1)
		end)
	end)

	describe("Events", function()
		it("Should Fire the OnReady event", function()
            local Fired = false
			Cooldown:Reset()
            Cooldown.OnReady:Once(function()
                Fired = true
            end)
			Cooldown.OnReady:Wait()
            task.wait(0.5)
			expect(Fired).to.equal(true)
		end)
		it("Should Fire the OnSuccess event", function()
			local Fired = false

			Cooldown.OnSuccess:Once(function()
				Fired = true
			end)
			Cooldown:Run(function()

			end)
			expect(Fired).to.equal(true)
		end)
		it("Should Fire the OnFail event", function()
			local Fired = false

			Cooldown.OnFail:Once(function()
				Fired = true
			end)
			Cooldown:Run(function()

			end)
			expect(Fired).to.equal(true)
		end)
	end)
end