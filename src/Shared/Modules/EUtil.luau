--[[
    Utilities to work with ECS systems
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local module = {}

--[[
    A shortcut to add a new item to a queue component.
    All it does it table.insert(), but improved
    @param e Entity to get the component from
    @param component The queue component (value must be a table or it will be converted into one!)
    @param ToAdd value(s) to add. Supports either a table format {v1, v2, v3} or a single value
]]
function module.AddToQueue(e: jecs.Entity, component: jecs.Entity, ToAdd: { any } | any)
	local c = world:get(e, component)

	if type(c) ~= "table" then
		c = {}
		world:set(e, component, c)
	end

	if typeof(ToAdd) ~= "table" then
		table.insert(c, ToAdd)
		return
	end

	for _, v in ToAdd do
		table.insert(c, v)
	end
end

--[[
    This will not resolve merge conflicts!
    This will only work well with shallow copies
]]
function module.Merge(A: { any }, B: { any })
	local C = table.clone(A)
	for i, v in B do
		C[i] = v
	end
	return C :: typeof(A) | typeof(B)
end

--[[
    Yield until the component appears on an entity
]]
function module.WaitForComponent(entity: jecs.Entity, id: jecs.Id)
	if world:has(entity, id) then
		return
	end

	local ready = false
	local unbind

	unbind = world:added(id, function(e)
		if e == entity then
			ready = true
			unbind()
		end
	end)

	repeat
		task.wait()
	until ready
end

function module.CountRelations(e: jecs.Entity, relation: jecs.Id)
	local n = 0
	for _ in world:targets(e, relation) do
		n += 1
	end
	return n
end

return module
