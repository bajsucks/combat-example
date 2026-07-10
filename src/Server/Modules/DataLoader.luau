local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataCom = require(ReplicatedStorage.Components.DataCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local Logger = require(ReplicatedStorage.Modules.Logger)
local DefaultData = require(ServerStorage.Constants.DefaultData)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

local module = {}

--[[
    Create a basic number data component out of table data
]]
local function AddNumber(e: jecs.Entity, i: string, v: number)
	local id = DataCom[i]
	if not id then
		Logger.warn("oi boy data component", i, "failed!")
		return
	end
	world:set(e, id, v)
	Logger.warn(`Added a number data entity; {i}:{v}`)
end
local function ParseNumber(e: jecs.Entity, id: jecs.Entity)
	if not world:has(e, id) then
		return
	end
	return world:get(e, id)
end
--[[
    Create a basic tag component out of table data
]]
local function AddTag(e: jecs.Entity, i: string, v: boolean?)
	if not v then
		return
	end
	local id = DataCom[i]
	if not id then
		Logger.warn("oi boy tag", i, "failed!")
		return
	end
	world:add(e, id)
	Logger.warn(`Added a tag data entity; {i}:{v}`)
end
local function ParseTag(e: jecs.Entity, id: jecs.Entity)
	return world:has(e, id)
end
--[[
    Puts all the savedata information into an entity
]]
function module.Hydrate(e: jecs.Entity, Data: typeof(DefaultData))
	for i, v in Data do -- Set up basic number data
		local t = typeof(v)
		if not v then
			continue
		end -- also skips tags that are false, intended behavior
		if t == "number" then
			AddNumber(e, i, v)
			continue
		end
		if t == "boolean" then
			AddTag(e, i, v)
			continue
		end
	end
end
--[[
    Takes all of the savedata information stored in an entity and converts it into a table
]]
function module.Dehydrate(e: jecs.Entity): typeof(DefaultData)
	Logger.print(`Dehydrating`)
	local result = {}
	world:remove(e, PlayerCom.IsLoaded)

	for i, v in DefaultData do
		local id = DataCom[i]
		if not id then
			Logger.warn(`oi boy saving {i} failed!`)
			continue
		end

		local t = typeof(v)

		if t == "number" then
			result[i] = ParseNumber(e, id)
		elseif t == "boolean" then
			result[i] = ParseTag(e, id) or false
		else
			Logger.warn(`Unexpected type of saving data entry! {t} ; {i}`)
		end
	end
	world:remove(e, PlayerCom.Hydrated)

	return result :: typeof(DefaultData)
end

return module
