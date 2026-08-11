local Fac = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local link = require(ReplicatedStorage.Components.link)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local mirrorTCP = WorldProvider.GetMirror("Main", "TCP")
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local Logger = require(ReplicatedStorage.Modules.Logger)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local LivingIndex = Indexer.new(LivingCom.LivingGuid)

type Config = {
	MaxHealth: number?,
	View: Instance
}

--[[
    Creates a new living entity
]]
function Fac.new(e: jecs.Entity?, config: Config?)
	config = config or {}
	e = e or world:entity()
	local View = config.View
	if not View then
		Logger.warn("Tried to summon a living without a view!")
		return e
	end
	world:set(e, link.View, View)
	local MaxHealth = config.MaxHealth or 100
	world:set(e, LivingCom.Health, MaxHealth)
	world:set(e, LivingCom.MaxHealth, MaxHealth)
	world:set(e, LivingCom.QDamage, {})
	world:set(e, LivingCom.QHeal, {})
	View.Parent = workspace.entities
	local guid = jUtil.GetGUID()
	world:set(e, LivingCom.LivingGuid, guid)
	View:SetAttribute("LivingGuid", guid)
	LivingIndex:Set(e, guid)

	world:set(e, mirrorTCP.Networked)
	return e
end

--[[
    Removes living components from an entity.
    Note that `mirrorTCP.Networked` component will stay on the entity.
]]
function Fac.Destroy(e: jecs.Entity)
	LivingIndex:Set(e, nil)
	local View = world:get(e, link.View)
	View:SetAttribute("LivingGuid", nil)
	world:remove(e, LivingCom.Health)
	world:remove(e, LivingCom.MaxHealth)
	world:remove(e, LivingCom.IsDead)
	world:remove(e, LivingCom.QDamage)
	world:remove(e, LivingCom.QHeal)
end

return Fac
