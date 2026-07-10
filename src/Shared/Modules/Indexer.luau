--[[
    Indexer to look up entities by their component values with O(1) time
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Waiter = require(ReplicatedStorage.Packages.jTools.Waiter).new()

local jecs = require(ReplicatedStorage.Packages.jecs)

local module = {}
local Indexer = {}
Indexer.__index = Indexer
local ListIndexers = {}
export type Indexer = {
	Id: jecs.Id,
	EntityCache: { [jecs.Entity]: string },
	Map: {
		[string]: {
			[jecs.Entity]: boolean,
		},
	},
	Set: (self: Indexer, e: jecs.Entity, v: any) -> (),
	Get: (self: Indexer, v: string) -> { jecs.Entity },
	Iter: (self: Indexer, v: any) -> typeof(pairs({} :: { jecs.Entity })),
	First: (self: Indexer, v: any) -> jecs.Entity?,
}

function module.GetWaiter()
	return Waiter
end

--[[
    Creates a new indexer.
]]
function module.new(Id: jecs.Id): Indexer
	if ListIndexers[Id] then
		return ListIndexers[Id]
	end
	local self = setmetatable({}, Indexer)
	self.Id = Id
	self.EntityCache = {}
	self.Map = {}
	ListIndexers[Id] = self
	return self
end
--[[
    Index an entity to a specified value
    Note that indexed entries will not be cleared automatically, you have to call :Set(e, nil) when you're done with the index.
    @param e Entity to index
    @param v Value to index the entity to. If nil, will de-index the entity.
]]
function Indexer.Set(self: Indexer, e: jecs.Entity, v: any)
	local Map = self.Map
	local eCache = self.EntityCache
	local CachedValue = eCache[e]
	if v and v == CachedValue then
		return
	end
	if CachedValue then -- the entry already exists and needs to be cleared first
		Map[CachedValue][e] = nil
		if next(Map[CachedValue]) == nil then
			Map[CachedValue] = nil
		end
	end
	if v then
		Map[v] = Map[v] or {}
		Map[v][e] = true
		eCache[e] = v
		Waiter:Resolve(v, e)
	else
		eCache[e] = nil
	end
end
--[[
    Returns all indexed entities with the specified value
    @param v Value to search

    @return List of all indexed entities with the searched value
]]
function Indexer.Get(self: Indexer, v: any): { jecs.Entity }
	local Map = self.Map[v]
	if not Map then
		return {}
	end
	local Result = {}
	local n = 0
	for i in self.Map[v] do
		n += 1
		Result[n] = i
	end
	return Result
end
--[[
    Iterator
]]
function Indexer.Iter(self: Indexer, v: any): typeof(pairs({} :: { jecs.Entity }))
	return pairs(self.Map[v] or {})
end
--[[
    Same as Indexer.Get()[1]
]]
function Indexer.First(self: Indexer, v: any): jecs.Entity<any>?
	local map = self.Map[v]
	return map and next(map) or nil
end

return module
