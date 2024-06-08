"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[98],{87303:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Returns a new Stater Object.","params":[{"name":"States","desc":"The Table that will have all the States","lua_type":"{[string]: State<T>}"},{"name":"Tick","desc":"Optional tick to be set.","lua_type":"number?"},{"name":"Return","desc":"Determines what to return in the first parameter of each state.","lua_type":"T?"}],"returns":[{"desc":"","lua_type":"Stater<T>\\r\\n"}],"function_type":"static","errors":[{"lua_type":"\\"No States\\"","desc":"Happens when no States are provided"}],"source":{"line":113,"path":"src/Stater/init.lua"}},{"name":"RemoveState","desc":"Removes a state inside the states table.","params":[{"name":"Name","desc":"The name of the removing state.","lua_type":"string"}],"returns":[],"function_type":"method","source":{"line":145,"path":"src/Stater/init.lua"}},{"name":"AddState","desc":"Adds a state inside the states table. If there is a Start after the State name inside the States, that will play.\\nIf there is a End after the State name inside the States, that will play after the state changes.","params":[{"name":"Name","desc":"The name that the state will go by.","lua_type":"string"},{"name":"State","desc":"The State function itself.","lua_type":"State<any>"}],"returns":[],"function_type":"method","errors":[{"lua_type":"\\"Existing State\\"","desc":"Happens when the name of the state is already inside the table."}],"source":{"line":167,"path":"src/Stater/init.lua"}},{"name":"GetCurrentState","desc":"Returns the current state the Stater is on indicated by a string. If none then nil.\\nThis is currently the same as self.State.","params":[],"returns":[{"desc":"","lua_type":"string?\\r\\n"}],"function_type":"method","source":{"line":182,"path":"src/Stater/init.lua"}},{"name":"IsWorking","desc":"Returns a boolean indicating if the State currently is on.","params":[],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"method","source":{"line":189,"path":"src/Stater/init.lua"}},{"name":"SetState","desc":"Returns a boolean indicating if the State currently is on.","params":[{"name":"State","desc":"The function name inside States represented by a string","lua_type":"string"}],"returns":[],"function_type":"method","errors":[{"lua_type":"\\"No State\\"","desc":"Happens when no State is provided."},{"lua_type":"\\"Invalid State\\"","desc":"Happens when the state provided doesn\'t exist."}],"source":{"line":200,"path":"src/Stater/init.lua"}},{"name":"Start","desc":"Begins the Stater.","params":[{"name":"StartingState","desc":"The function name inside States represented by a string, this state will be set at the start.","lua_type":"string"}],"returns":[],"function_type":"method","errors":[{"lua_type":"\\"No State\\"","desc":"Happens when no State is provided."}],"source":{"line":228,"path":"src/Stater/init.lua"}},{"name":"Stop","desc":"Stops the stater and its state.","params":[],"returns":[],"function_type":"method","source":{"line":266,"path":"src/Stater/init.lua"}},{"name":"Destroy","desc":"Gets rid of the Stater Object.","params":[],"returns":[],"function_type":"method","source":{"line":293,"path":"src/Stater/init.lua"}}],"properties":[],"types":[{"name":"State","desc":"","lua_type":"(Stater | any) -> boolean?","source":{"line":55,"path":"src/Stater/init.lua"}},{"name":"Stater","desc":"","fields":[{"name":"States","lua_type":"{[string]: State}","desc":"The Provided States Table, if theres a \\"Init\\" state then that function will execute each time the Stater Starts."},{"name":"Info","lua_type":"{any?}","desc":"A table that you can add anything in, this is more recommended than directly inserting variables inside the object."},{"name":"Tick","lua_type":"number?","desc":"The time it takes for the current state to be called again after a function is done. Default is 0"},{"name":"Return","lua_type":"any","desc":"This is the thing that returns as the first parameter of every single state. Default is the Stater object itself."},{"name":"State","lua_type":"State","desc":"The current state that the Stater is on."},{"name":"StateConfirmation","lua_type":"boolean","desc":"If this is enabled, the state MUST return a boolean indicating if the function ran properly."},{"name":"Changed","lua_type":"RBXScriptSignal","desc":"A signal that fires whenever the State changes. Returns Current State and Previous State"},{"name":"StatusChanged","lua_type":"RBXScriptSignal","desc":"Fired whenever the Stater starts or closes. Returns the current status as a boolean."},{"name":"StateRemoved","lua_type":"RBXScriptSignal","desc":"A signal that fires whenever a state is added via the Stater:AddState() method. Returns the State Name."},{"name":"StateAdded","lua_type":"RBXScriptSignal","desc":"A signal that fires whenever a state is removed via the Stater:RemoveState() method. Returns the State Name."}],"source":{"line":70,"path":"src/Stater/init.lua"}}],"name":"Stater","desc":"Stater is a finite state machine module with the purpose of easing the creation of ai and npcs in games,\\nStater was built with the intent of being used in module scripts.\\n\\n```lua\\n    local States = {}\\n\\n    function States.DoSomethingEnd(Data)\\n        -- this will fire when the machine switches from the \\"DoSomething\\" state \\n    end\\n\\n    function States.DoSomething(Data)\\n        -- do something with the data\\n    end\\n\\n    function States.DoSomethingStart(Data)\\n        -- this will fire when the machine switch to \\"DoSomething\\"\\n        Data.Stater:SetState(\\"SomethingDifferent\\")\\n    end\\n\\n    local Data = {\\n        Something = \\"Something\\",\\n    }\\n\\n    Data.Stater = Stater.new(States, 0, Data)\\n\\n    Data.Stater:Start(\\"DoSomething\\")\\n```","source":{"line":39,"path":"src/Stater/init.lua"}}')}}]);