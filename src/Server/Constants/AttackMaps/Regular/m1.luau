local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local link = require(ReplicatedStorage.Components.link)
local AttackUtils = require(ReplicatedStorage.Modules.AttackUtils)
local EUtil = require(ReplicatedStorage.Modules.EUtil)
local IndexerUtils = require(ReplicatedStorage.Modules.IndexerUtils)
local Logger = require(ReplicatedStorage.Modules.Logger)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local HitboxClass = require(ReplicatedStorage.Packages.HitboxClass)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local jecs = require(ReplicatedStorage.Packages.jecs)
local world = WorldProvider.Get("Main")
local var = {
    Damage = 10
}

return function(source:jecs.Entity)
    local j = Janitor.new()
    local AAT: {}?, View: Model = world:get(source, AttackCom.Threads, link.View)
    if not AAT then
        AAT = {}
        world:set(source, AttackCom.Threads, AAT)
    end
    local ThreadGUID = jUtil.GetGUID()
    local function Interrupt()
        j:Destroy()
        -- cancel stuff in attack
        world:remove(source, AttackCom.InAttack)
        
        AAT[ThreadGUID] = nil
        if jUtil.DictCount(AAT) == 0 then
            world:remove(source, AttackCom.Threads)
        end
    end
    
    AAT[ThreadGUID] = {task.defer(function()
        world:add(source, AttackCom.InAttack)
        local combo = world:get(source, AttackCom.m1Combo)
        if not combo then
            combo = {0, 0}
            world:set(source, AttackCom.m1Combo, combo)
        end
        combo[1] += 1
        if combo[1] >= 4 then
            -- apply cooldown
            world:remove(source, AttackCom.m1Combo)
        end
        
        Logger.print("Hitbox got registered")
        task.wait(0.1)
        local offset = Vector3.new(0, 0, -3.5)
        local hb = HitboxClass.new(
            AttackUtils.Params(View, offset, 3)
        )
        j:Add(hb, "Destroy")
        hb:SetVelocityPrediction(false)
        hb:WeldTo(View.PrimaryPart, CFrame.new(offset))
        j:Add(hb.HitSomeone:Connect(function(Views)
            for _, v in Views do
                if v == View then continue end
                local e = IndexerUtils.LivingByView(View)
                if not e then continue end
                EUtil.AddToQueue(e, LivingCom.QDamage, var.Damage)
            end
        end))
        hb:Start()
        task.wait(0.5)
        hb:Stop()
        hb:Destroy()
        world:remove(source, AttackCom.InAttack)
        Interrupt()
    end), Interrupt}
end