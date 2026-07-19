local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local link = require(ReplicatedStorage.Components.link)
local DamageFac = require(ReplicatedStorage.Factories.DamageFac)
local AttackUtils = require(ReplicatedStorage.Modules.AttackUtils)
local Cooldowns = require(ReplicatedStorage.Modules.Cooldowns)
local IndexerUtils = require(ReplicatedStorage.Modules.IndexerUtils)
local Logger = require(ReplicatedStorage.Modules.Logger)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local jecs = require(ReplicatedStorage.Packages.jecs)
local world = WorldProvider.Get("Main")

local module = {}

module.Hitboxes = {
    {
        Damage = 5,
        Size = Vector3.one*3,
        Offset = -Vector3.zAxis*3.5
    }
}

local function hitbox(source: jecs.Entity, View: Model, n: number, Replicated: boolean?)
    if Replicated then return {} end
    local params = module.Hitboxes[n]
    local cf: CFrame = View:GetPivot() * CFrame.new(params.Offset)
    local hb = AttackUtils.Box(View, cf, module.Hitboxes[n])
    local p = hb:GetParts()
    local hits = {}
    for _, v in p do
        if v == View then continue end
        local guid = v:GetAttribute("LivingGuid")
        if not guid then Logger.warn("No living GUID"); continue end
        Logger.print("actual found guid:", guid)
        local eTarget = IndexerUtils.LivingByGuid(guid)
        Logger.print(eTarget)
        Logger.print("CLIENT DAMAGE TO", v.Name)
        if RunService:IsClient() then
            DamageFac.new({damage = params.Damage, target = eTarget})
        else
            DamageFac.new({source = source, damage = params.Damage, target = eTarget})
        end
        table.insert(hits, guid)
    end
    if RunService:IsClient() then
        ReplicatedStorage.Remotes.Hitbox:FireServer("m1", n, hits)
    end
    hb:Destroy()
    return p
end

function module.Attack(source: jecs.Entity, Replicated:boolean)
    world:add(source, AttackCom.InAttack)
    local View, m1Combo = world:get(source, link.View, AttackCom.m1Combo)
    m1Combo = m1Combo or 1
    local function Cooldown()
        world:remove(source, AttackCom.m1Combo)
        Logger.print("Set cooldown")
        Cooldowns.SetCooldown(source, "m1")
    end
    if m1Combo == 4 then
        Cooldown()
    else
        m1Combo += 1
        world:set(source, AttackCom.m1Combo, m1Combo)
        task.delay(1, function()
            if world:get(source, AttackCom.m1Combo) == m1Combo then
                Cooldown()
            end
        end)
    end
    local j = Janitor.new()
    if RunService:IsClient() then
        ReplicatedStorage.Remotes.Windup:FireServer("m1")
    end
    local thread = task.spawn(function()
        task.wait(0.05)
        hitbox(source, View, 1, Replicated)
        task.wait(0.05)
        if RunService:IsServer() then
            world:remove(source, AttackCom.InAttack)
        end
        j:Destroy()
    end)
    AttackUtils.ConnectInterrupt(j, thread)
end

return module