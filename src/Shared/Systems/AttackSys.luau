local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local InputCom = require(ReplicatedStorage.Components.InputCom)
local link = require(ReplicatedStorage.Components.link)
local AttackUtils = require(ReplicatedStorage.Modules.AttackUtils)
local Cooldowns = require(ReplicatedStorage.Modules.Cooldowns)
local Logger = require(ReplicatedStorage.Modules.Logger)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

local InputQuery = world
:query(jecs.pair(InputCom.Pressing, jecs.w))
:without(AttackCom.Blocking, AttackCom.InAttack, AttackCom.Stunned):with(link.View):cached()

if RunService:IsServer() then
    ReplicatedStorage.Remotes.Hitbox.OnServerEvent:Connect(AttackUtils.ReplicatedHitbox)
    ReplicatedStorage.Remotes.Windup.OnServerEvent:Connect(AttackUtils.ReplicatedWindup)
end

return {function()
    for e: jecs.Entity in InputQuery do
        for id in world:targets(e, InputCom.Pressing) do
            local Move = world:get(id, jecs.Name)
            if Cooldowns.IsOnCooldown(e, Move) then continue end
            local Map = AttackUtils.GetMap(e, Move)
            if not Map then Logger.warn("Missing map!"); continue end
            Map.Attack(e)
        end
    end
end, -1, "postsim"}