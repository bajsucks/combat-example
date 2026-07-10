--[[
    Usage:
    world:set(e, jecs.pair(link.Static, Component), "path/to/property") - will copy this component value onto the view instance's property ONCE
    world:set(e, jecs.pair(link.Physic, Component), "path/to/property") - will copy view instance's property onto the component every frame
    world:set(e, jecs.pair(link.Kinematic, Component), "path/to/property") - will copy this component value onto the view instance's property every frame
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local link = require(ReplicatedStorage.Components.link)
local Logger = require(ReplicatedStorage.Modules.Logger)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

local pair, Wildcard = jecs.pair, jecs.Wildcard

-- resolves a path string into instance and property
local function resolvePath(root: Instance, path: string): (boolean, link.ChildCache?)
	local segments = string.split(path, "/")
	local property = table.remove(segments, #segments)

	local current: any = root
	for _, name in segments do
		current = current:FindFirstChild(name)
		if not current then
			return false, {}
		end
	end

	return true, { current, property }
end

local LinkList = { link.Kinematic, link.Physic, link.Static }
local ResolverQueries = {}
for i, rel in LinkList do
	ResolverQueries[i] = world:query(link.View):with(pair(rel, Wildcard)):cached()
end
local toCache = {
	link.KinematicCache,
	link.PhysicCache,
}

-- helper to apply values with change detection
local function applyToInstance(i: Instance, p: string, v: any)
	if i[p] ~= v then
		i[p] = v
	end
end

-- resolves all paths that needs resolving and caches the result
local function Resolver()
	for i, rel in LinkList do

		for e, root in ResolverQueries[i] do
			if not root then
				continue
			end
			local com = world:target(e, rel)

			while com do
				local path = world:get(e, pair(rel, com))
				local function stop()
					world:remove(e, pair(rel, com))
					com = world:target(e, rel)
				end

				if not path then
					stop()
					continue
				end
				local success, cache = resolvePath(root, path)
				local inst, prop = cache[1], cache[2]

				if not success or not jUtil.HasProperty(inst, prop) then
					stop()
					Logger.warn(`Failed to resolve path {path} for entity {e}`)
					continue
				end
				local fullCache: link.ChildCache = { inst, prop, com }

				-- cache PivotOffset
				if prop == "CFrame" and inst:IsA("PVInstance") then
					local primary = if inst:IsA("Model") then inst.PrimaryPart else inst
					if primary then
						table.insert(fullCache, inst:GetPivot():Inverse() * primary.CFrame)
					end
				end

				-- resolve link.Static right now at this exact moment since it only runs once
				if rel == link.Static then
					local v = world:get(e, com)
					if v ~= nil then
						if prop == "CFrame" then
							inst:PivotTo(v)
						else
							applyToInstance(inst, prop, v)
						end
					end
				else
					Logger.print("Applied cache to", com, "aka", prop) -- prints all properties correctly
					world:set(e, pair(toCache[i], com), fullCache)
				end
				stop()
			end
		end
	end
end

local KinematicQuery = world:query(pair(link.KinematicCache, Wildcard)):cached()
local parts, cframes = {}, {}

-- synchronizes view instances to the value of linked components
local function HandleKinematic(e, cache: link.ChildCache)
	local inst: Instance, prop: string, targetCom, pivotOffset = cache[1], cache[2], cache[3], cache[4]
	--print(inst, prop, targetCom) -- only prints red, CFrame, 14
	if not inst.Parent then
		world:remove(e, pair(link.KinematicCache, targetCom))
		return
	end
	if jecs.is_tag(world, targetCom) then
		local has = world:has(e, targetCom)
		if has then
			applyToInstance(inst, prop, true)
		else
			applyToInstance(inst, prop, false)
		end
		return
	end
	local v = world:get(e, targetCom)
	if prop == "CFrame" then
		local primary = if inst:IsA("Model") then inst.PrimaryPart else inst
		if primary and pivotOffset then
			table.insert(parts, primary)
			table.insert(cframes, v * pivotOffset)
		else
			inst:PivotTo(v)
		end
	else
		applyToInstance(inst, prop, v)
	end
end
local function Kinematic()
	-- for e in KinematicQuery do
	--     local com = world:target(e, link.KinematicCache)
	--     local nth = 0
	--     while com do
	--         nth += 1
	--         local cache = world:get(e, pair(link.KinematicCache, com))
	--         print(e, cache[2], cache)
	--         com = world:target(e, link.KinematicCache, nth)
	--     end
	-- end
	for e in KinematicQuery do
		local com = world:target(e, link.KinematicCache)
		local nth = 0
		while com do
			nth += 1
			local cache = world:get(e, pair(link.KinematicCache, com))
			if not cache then
				Logger.warn("Kinematic cache broke? Kinematic cache broke.")
				break
			end
			HandleKinematic(e, cache)
			com = world:target(e, link.KinematicCache, nth)
		end
	end

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(parts)
		table.clear(cframes)
	end
end

local PhysicQuery = world:query(pair(link.PhysicCache, Wildcard)):cached()

-- synchronizes linked components to the value of the view instance
local function HandlePhysic(e, cache)
	local inst, prop, targetCom = cache[1], cache[2], cache[3]
	if not inst.Parent then
		world:remove(e, pair(link.PhysicCache, targetCom))
		return
	end

	local v = if prop == "CFrame" then inst:GetPivot() else inst[prop]

	if world:get(e, targetCom) ~= v then
		world:set(e, targetCom, v)
	end
end
local function Physic()
	for e in PhysicQuery do
		local com = world:target(e, link.PhysicCache)
		local nth = 0
		while com do
			nth += 1
			local cache = world:get(e, pair(link.PhysicCache, com))
			if not cache then
				Logger.warn("Physic cache broke? Physic cache broke.")
				break
			end
			HandlePhysic(e, cache)
			com = world:target(e, link.PhysicCache, nth)
		end
	end
end

return function()
	Resolver()
	Kinematic()
	Physic()
end
