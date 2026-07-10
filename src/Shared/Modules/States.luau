local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Modules.Logger)
local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

local module = {}
type Tag = jecs.Id
type Group = { Tag }
type Entity = jecs.Entity

module.Relations = {
	oneOf = 1,
	prerequisite = 2,
}
type Relation = keyof<typeof(module.Relations)>

module.OnAdd = {}
module.OnRemove = {}

type HookFunc = (e: Entity) -> ()

local function Hook(tag: Tag, hook: typeof(jecs.OnAdd) | typeof(jecs.OnRemove), t: { HookFunc })
	world:set(tag, hook, function(e: Entity)
		for _, f in t do
			f(e)
		end
	end)
end

local function OnAdd(tag: Tag, f: HookFunc)
	local t = module.OnAdd[tag] or {}
	if not module.OnAdd[tag] then
		module.OnAdd[tag] = t
		Hook(tag, jecs.OnAdd, t)
	end
	table.insert(t, f)
end

local function OnRemove(tag: Tag, f: HookFunc)
	local t = module.OnRemove[tag] or {}
	if not module.OnRemove[tag] then
		module.OnRemove[tag] = t
		Hook(tag, jecs.OnRemove, t)
	end
	table.insert(t, f)
end

local function hasAny(e, g: Group): boolean
	for _, tag in g do
		if world:has(e, tag) then
			return true
		end
	end
	return false
end

local function removeGroup(e, g: Group)
	for _, tag in g do
		world:remove(e, tag)
	end
end

-- whenever a tag in g1 is added the entire g2 set is cleared
local function oneOf(g1: Group, g2: Group)
	for _, tag in g1 do
		OnAdd(tag, function(e)
			removeGroup(e, g2)
		end)
	end

	for _, tag in g2 do
		OnAdd(tag, function(e)
			removeGroup(e, g1)
		end)
	end
end

-- g1 tags require at least one g2 tag to remain
local function prerequisite(g1: Group, g2: Group)
	for _, tag in g1 do
		OnAdd(tag, function(e)
			if not hasAny(e, g2) then
				Logger.warn(`Removed {tostring(tag)} from {tostring(e)} because prerequisite is missing`)
				world:remove(e, tag)
			end
		end)
	end

	-- if the last g2 tag is removed, clear all g1 tags
	for _, tag in g2 do
		OnRemove(tag, function(e)
			if not hasAny(e, g2) then
				removeGroup(e, g1)
			end
		end)
	end
end

--[[
    Relate tags of g1 to tags of g2 according to Relation type.

    Behaviour by relation:
      - oneOf: whenever a tag in g1 is added the entire g2 set is cleared (and vice‑versa)
      - prerequisite: tags from g1 may only exist when at least one tag of g2 is present;
      attempted additions without a prerequisite are removed. If all tags from g2 disappear, g1 will also be cleared
]]
function module.Relate(g1: Group, g2: Group, Relation: Relation)

	if Logger.isDebug() then -- group validation
		-- is empty
		if #g1 == 0 or #g2 == 0 then
			error("States.Relate requires two non-empty groups", 2)
		end

		-- is duplicate
		local seen = {}
		for _, tag in g1 do
			if seen[tag] then
				error(`tag {tostring(tag)} in g1 appears more than once!`)
			end
			seen[tag] = true
		end
		for _, tag in g2 do
			if seen[tag] then
				error(`tag {tostring(tag)} in g2 appears more than once!`)
			end
			seen[tag] = true
		end
	end

	if Relation == module.Relations.oneOf then
		oneOf(g1, g2)
		return
	elseif Relation == module.Relations.prerequisite then
		prerequisite(g1, g2)
		return
	end

	error(`Invalid relation: {tostring(Relation)}`, 2)
end

return module
