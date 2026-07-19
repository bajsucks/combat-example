local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DamageCom = require(ReplicatedStorage.Components.DamageCom)
local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local EUtil = require(ReplicatedStorage.Modules.EUtil)
local IndexerUtils = require(ReplicatedStorage.Modules.IndexerUtils)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

local DamageQuery = world
:query(DamageCom.damage, DamageCom.source, DamageCom.target)
:without(DamageCom.ReplicationAwait):cached()

local LocalDamageQuery = world
:query(DamageCom.damage, DamageCom.target)
:without(DamageCom.source, DamageCom.ReplicationAwait):cached()

local function PlayVfx(target: jecs.Entity, Damage: number)
    
end

return {function(dt: number)
    for eDmg: jecs.Entity, Damage: number, source: jecs.Entity, target: jecs.Entity in DamageQuery do
        if RunService:IsServer() then
            world:add(eDmg, DamageCom.ReplicationAwait)
            print(target, Damage)
            EUtil.AddToQueue(target, LivingCom.QDamage, Damage)
            task.delay(1, function()
                world:delete(eDmg)
            end)
            continue
        end
        if source ~= IndexerUtils.LocalPlayer() then
            task.defer(PlayVfx, target, Damage)
        end
        world:delete(eDmg)
    end
    if RunService:IsClient() then
        for eDmg: jecs.Entity, Damage: number, target: jecs.Entity in LocalDamageQuery do
            task.defer(PlayVfx, target, Damage)
            EUtil.AddToQueue(target, LivingCom.QDamage, Damage)
            world:delete(eDmg)
        end
    end
end, -1, "postsim"}