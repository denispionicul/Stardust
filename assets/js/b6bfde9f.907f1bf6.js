"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[385],{77062:e=>{e.exports=JSON.parse('{"functions":[{"name":"Add","desc":"Adds a function to the queue.","params":[{"name":"func","desc":"","lua_type":"(T...) -> ...any"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":82,"path":"src/Queue/init.lua"}},{"name":"Stop","desc":"Clears all current functions in the queue and empties it.\\nThe emptied event won\'t fire in here.","params":[],"returns":[],"function_type":"method","source":{"line":109,"path":"src/Queue/init.lua"}},{"name":"new","desc":"Returns a new queue.","params":[],"returns":[{"desc":"","lua_type":"Queue\\r\\n"}],"function_type":"static","source":{"line":120,"path":"src/Queue/init.lua"}},{"name":"Destroy","desc":"Destroys the queue.","params":[],"returns":[],"function_type":"method","source":{"line":135,"path":"src/Queue/init.lua"}}],"properties":[{"name":"Emptied","desc":"Fires whenever the queue runs out of functions.\\n\\n```lua\\nQueueClass.Emptied:Connect(function()\\n\\tprint(\\"Queue emptied!\\")\\nend)\\n```","lua_type":"RBXScriptSignal","source":{"line":61,"path":"src/Queue/init.lua"}},{"name":"Returned","desc":"Fires whenever a function in the queue returns a value.\\n\\n```lua\\nQueueClass.Returned:Connect(function(...)\\n\\tprint(\\"Queue returned a value\\" )\\n\\tprint(...)\\nend)\\n```","lua_type":"RBXScriptSignal","source":{"line":75,"path":"src/Queue/init.lua"}}],"types":[],"name":"Queue","desc":"Queues are a collection of functions that run in order.\\n\\nBasic Usage:\\n```lua\\nlocal Queue = require(Path.to.Queue)\\n\\nlocal QueueClass = Queue.new()\\n\\nQueueClass:Add(function()\\n\\ttask.wait(5)\\n\\tprint(\\"function 1 finished!\\")\\nend)\\n\\nQueueClass:Add(function()\\n\\ttask.wait(10)\\n\\tprint(\\"function 2 finished!\\")\\nend)\\n\\n-- function 1 will run, then the 2nd one\\n```","source":{"line":48,"path":"src/Queue/init.lua"}}')}}]);