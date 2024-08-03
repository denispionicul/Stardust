"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[355],{6790:e=>{e.exports=JSON.parse('{"functions":[{"name":"Simple","desc":"Adds a cooldown to a function. It returns a copy of the function that always returns a boolean first, which is true\\nif the function ran or false if the function didn\'t run because of the cooldown.","params":[{"name":"Time","desc":"","lua_type":"number"},{"name":"Function","desc":"","lua_type":"(T...) -> (R...)"}],"returns":[{"desc":"","lua_type":"(T...) -> (boolean, R...)\\r\\n"}],"function_type":"static","source":{"line":153,"path":"src/Cooldown/init.luau"}},{"name":"new","desc":"Returns a new Cooldown.","params":[{"name":"Time","desc":"The time property, for more info check the \\"Time\\" property.","lua_type":"number"},{"name":"AutoReset","desc":"Sets the AutoReset value to the boolean provided, please refer to [Cooldown.AutoReset]","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"Cooldown\\r\\n"}],"function_type":"static","errors":[{"lua_type":"\\"No Time\\"","desc":"Happens when no Time property is provided."}],"source":{"line":174,"path":"src/Cooldown/init.luau"}},{"name":"Reset","desc":"Resets the debounce. Just like calling a sucessful :Run() with AutoReset set to true\\nIf a delay is provided, the debounce will be delayed by the provided number. A delay will only last once.\\nAn example would be:\\n```lua\\nlocal Cooldown = require(Path.Cooldown)\\n\\nlocal Debounce: Cooldown = Cooldown.new(2)\\nDebounce.AutoReset = false\\n\\nDebounce:Run(function()\\n\\tprint(\\"This will run\\")  -- prints\\nend)\\n\\nDebounce:Reset(1) -- We reset it and delay it by 1\\n\\nDebounce.OnReady:Wait() -- We wait 3 seconds instead of 2, because we delay it by 1.\\n-- You can think of delaying as adding time + delay which would be 2 + 1 in our case\\n-- Delaying will not change the time.\\n\\nDebounce:Run(function()\\n\\tprint(\\"This will run\\")  -- will print because the :Run will be ready.\\nend)\\n```","params":[{"name":"Delay","desc":"The amount of delay to add to the Time","lua_type":"number?"}],"returns":[{"desc":"The cooldown time + delay.","lua_type":"number"}],"function_type":"method","source":{"line":227,"path":"src/Cooldown/init.luau"}},{"name":"Activate","desc":"Makes the cooldown ready again.","params":[],"returns":[],"function_type":"method","source":{"line":252,"path":"src/Cooldown/init.luau"}},{"name":"Run","desc":"Runs the given callback function if the passed time is higher than the Time property.\\nIf AutoReset is true, it will call :Reset() after a successful run.","params":[{"name":"Callback","desc":"","lua_type":"(Args...) -> ()"},{"name":"...","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"method","yields":true,"source":{"line":263,"path":"src/Cooldown/init.luau"}},{"name":"RunIf","desc":"If the given Predicate (The First parameter) is true or returns true, it will call :Run() on itself.\\n\\nAn example would be:\\n```lua\\nlocal Cooldown = require(Path.Cooldown)\\n\\nlocal Debounce = Cooldown.new(5)\\nDebounce.AutoReset = false\\n\\nDebounce:RunIf(true, function()\\n\\tprint(\\"This will run\\")  -- prints\\nend)\\n\\nDebounce:RunIf(false, function()\\n\\tprint(\\"This will not run\\")  -- does not print because the first parameter (Predicate) is false.\\nend)\\n```","params":[{"name":"Predicate","desc":"","lua_type":"boolean | () -> boolean"},{"name":"Callback","desc":"","lua_type":"(Args...) -> ()"},{"name":"...","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"method","yields":true,"source":{"line":301,"path":"src/Cooldown/init.luau"}},{"name":"RunOrElse","desc":"if the :Run() will not be successful, it will instead call callback2. This won\'t reset the debounce.\\n\\nAn example would be:\\n```lua\\nlocal Cooldown = require(Path.Cooldown)\\n\\nlocal Debounce = Cooldown.new(5)\\n\\nDebounce:RunOrElse(function()\\n\\tprint(\\"This will run\\")  -- prints\\nend, function()\\n\\tprint(\\"This will not print\\") -- doesn\'t print because the :Run() will be successful.\\nend)\\n\\nDebounce:RunOrElse(function()\\n\\tprint(\\"This will not run\\")  -- does not print because the debounce hasn\'t finished waiting.\\nend, function()\\n\\tprint(\\"This will run\\") -- will print because the :Run() failed.\\nend)\\n```","params":[{"name":"Callback","desc":"","lua_type":"() -> ()"},{"name":"Callback2","desc":"","lua_type":"() -> ()"}],"returns":[],"function_type":"method","yields":true,"source":{"line":341,"path":"src/Cooldown/init.luau"}},{"name":"Wrap","desc":"Wraps a cooldown class to a function (similar to [Cooldown.Simple]). It returns a Cooldown class that when called,\\nit will call Cooldown:Run() on the given function. When calling the cooldown class, the first return will always be\\na boolean before the returns. If the function succesfully runs, the boolean will be true.","params":[{"name":"Function","desc":"","lua_type":"(T...) -> R..."}],"returns":[{"desc":"","lua_type":"WrapFuncReturn<T..., R...>\\r\\n"}],"function_type":"method","source":{"line":354,"path":"src/Cooldown/init.luau"}},{"name":"IsReady","desc":"Returns a boolean indicating if the Cooldown is ready to :Run().","params":[],"returns":[{"desc":"","lua_type":"boolean\\t\\r\\n"}],"function_type":"method","source":{"line":373,"path":"src/Cooldown/init.luau"}},{"name":"GetPassed","desc":"Returns a boolean indicating the passed time since the last :Run().","params":[{"name":"Clamped","desc":"If this is true, it will use math.clamp to make sure the value returned is min 0 and max the time.","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"number\\r\\n"}],"function_type":"method","source":{"line":381,"path":"src/Cooldown/init.luau"}},{"name":"GetAlpha","desc":"Returns the time before the :Run() is ready in a value between 0-1.","params":[{"name":"Reversed","desc":"If true, will return alpha as 0 if fully ready to :Run() instead of 1.","lua_type":"boolean"}],"returns":[{"desc":"","lua_type":"number\\r\\n"}],"function_type":"method","source":{"line":390,"path":"src/Cooldown/init.luau"}},{"name":"Destroy","desc":"Destroys the Cooldown.","params":[],"returns":[],"function_type":"method","source":{"line":398,"path":"src/Cooldown/init.luau"}}],"properties":[{"name":"Time","desc":"The time property signifies how much time is needed to wait before using :Run()\\n\\nAn example would be:\\n```lua\\nlocal Cooldown = require(Path.Cooldown)\\n\\nlocal Debounce = Cooldown.new(5) -- The first parameter is the Time\\n-- Can be changed with Debounce.Time = 5\\n\\nDebounce:Run(function()\\n\\tprint(\\"This will run\\")  -- prints\\nend)\\n\\nDebounce:Run(function()\\n\\tprint(\\"This won\'t run\\")  -- won\'t print because the debounce hasn\'t finished waiting 5 seconds\\nend)\\n```\\n\\n:::note\\n\\tCalling :Run() when the debounce isn\'t ready won\'t yield.\\n:::","lua_type":"number","source":{"line":115,"path":"src/Cooldown/init.luau"}},{"name":"AutoReset","desc":"When AutoReset is on, the debounce will reset after a successful Run() call.\\n\\nAn example would be:\\n```lua\\nlocal Cooldown = require(Path.Cooldown)\\n\\nlocal Debounce = Cooldown.new(5)\\nDebounce.AutoReset = false\\n\\n-- Keep in mind you can also set the AutoReset by the second parameter in the constructor: Cooldown.new(5, false)\\n\\nDebounce:Run(function()\\n\\tprint(\\"This will run\\")  -- prints\\nend)\\n\\nDebounce:Run(function()\\n\\tprint(\\"This will still run\\")  -- still prints because AutoReset is false and the debounce did not reset\\nend)\\n\\nDebounce:Reset() -- Reset the debounce\\n```","lua_type":"boolean","source":{"line":141,"path":"src/Cooldown/init.luau"}}],"types":[{"name":"Cooldown","desc":"","fields":[{"name":"Time","lua_type":"number","desc":"The time of the debounce"},{"name":"LastActivation","lua_type":"number","desc":"The last time the debounce reset"},{"name":"AutoReset","lua_type":"boolean","desc":"Whether or not the debounce should reset after running."},{"name":"OnReady","lua_type":"RBXScriptSignal | Signal","desc":"Fires whenever the Cooldown can be be fired."},{"name":"OnSuccess","lua_type":"RBXScriptSignal | Signal","desc":"Fires whenever a :Run() was successful."},{"name":"OnFail","lua_type":"RBXScriptSignal | Signal","desc":"Fires whenever a :Run() fails."}],"source":{"line":89,"path":"src/Cooldown/init.luau"}}],"name":"Cooldown","desc":"Cooldown is a module that helps with creating debounces and, as the name implies, cooldowns.\\nBasic Usage:\\n```lua\\nlocal Cooldown = require(Path.Cooldown)\\n\\nlocal DebounceTime = 5\\nlocal Debounce = Cooldown.new(DebounceTime)\\n\\nDebounce:Run(function()\\n\\tprint(\\"Ran!\\")\\nend)\\n\\nDebounce:Run(function()\\n\\tprint(\\"Ran Again!\\")\\nend)\\n\\n-- Output:\\n-- Ran!\\n```","source":{"line":32,"path":"src/Cooldown/init.luau"}}')}}]);