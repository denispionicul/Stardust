--!strict
-- Version 1.0.0

type Cases = { [any]: () -> () }

--[=[
	@class Switch

	Switches that work like java.

	```lua
	local Switch = require(Path.to.Switch)
	local default = Switch.default

	local Value = Random.new():NextInteger(1, 10)

	Switch(Value) {
		[1] = function()
			print("value is 1")
		end,
		[10] = function()
			print("value is 10")
		end,
		[default] = function()
			print("value is not 1 or 10")
		end
	}
	```
]=]
local Switch = {}

-- Misc
Switch.default = newproxy(false)

local function Check(val: any, cases: Cases)
	local valtable = cases[val]

	if valtable then
		local valtype = type(valtable)

		if valtype == "function" then
			cases[val]()
		else
			Check(valtable, cases)
		end
	elseif cases[Switch.default] then
		cases[Switch.default]()
	end
end

setmetatable(Switch, {
	__call = function(_: any, val: any): (cases: Cases) -> ()
		return function(cases: Cases)
			Check(val, cases)
		end
	end
})

return Switch
