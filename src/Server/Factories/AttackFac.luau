local Fac = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local mirrorTCP = WorldProvider.GetMirror("Main", "TCP")

type Config = {

}

function Fac.new(e: jecs.Entity?, config: Config?)
    config = config or {}
    e = e or world:entity()
    world:set(e, AttackCom.Fighter, "Regular")

    world:set(e, mirrorTCP.Networked)
    return e
end

--[[
    Removes living components from an entity.
    Note that `mirrorTCP.Networked` component will stay on the entity.
]]
function Fac.Destroy(e: jecs.Entity)
    world:remove(e, AttackCom.Fighter)
end

return Fac
