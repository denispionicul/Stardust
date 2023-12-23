local Switch = require(script.Parent)
local default = Switch.default

return function()
    describe("test", function()
        it("should grab the correct function", function()
            local foo = nil

            Switch("bar") {
                ["ber"] = function()
                    foo = "ber"
                end,
                ["bar"] = function()
                    foo = "bar"
                end
            }

            expect(foo).to.equal("bar")
        end)

        it("should result to default when no value is found", function()
            local foo = nil

            Switch("none") {
                [default] = function()
                    foo = "bar"
                end
            }

            expect(foo).to.equal("bar")
        end)
    end)
end