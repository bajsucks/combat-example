local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.Modules.Logger)
local Jabby = require(ReplicatedStorage.Packages.Jabby)
local t = require(ReplicatedStorage.Packages.jTools.t)
local jecs = require(ReplicatedStorage.Packages.jecs)
local mirror = require(ReplicatedStorage.Packages.mirror)

local module = {}
module.worlds = {}
module.mirrors = {}

local GetCheck = t.string
--[[
    Gets a world by it's string ID
]]
function module.Get(WorldIndex: string)
	assert(GetCheck(WorldIndex))
	if not module.worlds[WorldIndex] then
		module.worlds[WorldIndex] = jecs.world()
	end
	return module.worlds[WorldIndex]
end

local GetMirrorCheck = t.tuple(t.string, t.string)
--[[
    Gets a mirror for a world.
]]
function module.GetMirror(WorldIndex: string, MirrorIndex: string)
	assert(GetMirrorCheck(WorldIndex, MirrorIndex))
	local World = module.Get(WorldIndex)
	if not module.mirrors[MirrorIndex] then
		module.mirrors[MirrorIndex] = mirror.new(World)
	end
	return module.mirrors[MirrorIndex]
end

if Logger.isDebug() and RunService:IsClient() then
	Jabby.register({
		applet = Jabby.applets.world,
		name = "Main",
		configuration = {
			world = module.Get("Main"),
		},
	})
end

return module
