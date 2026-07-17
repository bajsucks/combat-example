local Fac = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageCom = require(ReplicatedStorage.Components.DamageCom)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local mirrorTCP = WorldProvider.GetMirror("Main", "TCP")

type Config = {
    source: jecs.Entity,
    damage: number
}

function Fac.new(config: Config)
    local e = world:entity()
    world:set(e, DamageCom.source, config.source)
    world:set(e, DamageCom.damage, config.damage)
    world:set(e, mirrorTCP.Networked)
    return e
end

--[[
    Removes living components from an entity.
    Note that `mirrorTCP.Networked` component will stay on the entity.
]]
function Fac.Destroy(e: jecs.Entity)
    world:remove(e)
end

return Fac
