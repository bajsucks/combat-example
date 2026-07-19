local Fac = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageCom = require(ReplicatedStorage.Components.DamageCom)
local Logger = require(ReplicatedStorage.Modules.Logger)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local mirrorTCP = WorldProvider.GetMirror("Main", "TCP")

type Config = {
    source: jecs.Entity?,
    damage: number,
    target: jecs.Entity
}

function Fac.new(config: Config)
    local e = world:entity()
    if not config.damage or not config.target then Logger.warn("BAHH") end
    if config.source then
        world:set(e, DamageCom.source, config.source)
    end
    world:set(e, DamageCom.damage, config.damage)
    world:set(e, DamageCom.target, config.target)
    world:set(e, mirrorTCP.Networked)
    return e
end

return Fac
