local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local link = require(ReplicatedStorage.Components.link)
local DamageFac = require(ReplicatedStorage.Factories.DamageFac)
local AttackUtils = require(ReplicatedStorage.Modules.AttackUtils)
local IndexerUtils = require(ReplicatedStorage.Modules.IndexerUtils)
local Logger = require(ReplicatedStorage.Modules.Logger)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local jecs = require(ReplicatedStorage.Packages.jecs)
local AttackSys = require(ReplicatedStorage.Systems.AttackSys)
local world = WorldProvider.Get("Main")

local module = {}

module.Hitboxes = {
    {
        Damage = 5,
        Size = Vector3.one*3,
        Offset = Vector3.zAxis*-3.5
    }
}

type state = AttackSys.state
--[[
    visual - client does windup and hitbox, (if hit remotes to server) then does endlag according to hit or not
    replicated - when receiving remote from client, sanity checks it and does damage, then replicates vfx to all other people
    real - visual + replicated happening in the same place
]]

local function hitbox(source: jecs.Entity, View: Model, n: number, Replicated: boolean?)
    if Replicated then return {} end
    local params = module.Hitboxes[n]
    local cf: CFrame = View:GetPivot() * CFrame.new(params.Offset)
    local hb = AttackUtils.Box(View, cf, module.Hitboxes[n])
    local p = hb:GetParts()
    local hits = {}
    for _, v in p do
        if v == View then continue end
        local e = IndexerUtils.LivingByView(v)
        if not e then continue end
        local guid = View:GetAttribute("LivingGuid")
        if not guid then continue end
        print("DAMAGE", View.Name)
        DamageFac.new({source = source, damage = params.Damage})
        table.insert(hits, guid)
    end
    if RunService:IsClient() then
        ReplicatedStorage.Remotes.Hitbox:FireServer("m1", n, hits)
    end
    hb:Destroy()
    return p
end

function module.Attack(source: jecs.Entity, Replicated:boolean)
    print("Attack began")
    world:add(source, AttackCom.InAttack)
    local View = world:get(source, link.View)
    local j = Janitor.new()
    if RunService:IsClient() then
        ReplicatedStorage.Remotes.Windup:FireServer("m1")
    end
    local thread = task.spawn(function()
        task.wait(0.05)
        hitbox(source, View, 1, Replicated)
        task.wait(0.05)
        print("Attack ended")
        if RunService:IsServer() then
            world:remove(source, AttackCom.InAttack)
        end
        j:Destroy()
    end)
    AttackUtils.ConnectInterrupt(j, thread)
end

return module