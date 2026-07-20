local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthbarCom = require(ReplicatedStorage.Components.HealthbarCom)
local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local link = require(ReplicatedStorage.Components.link)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local world: jecs.World = WorldProvider.Get("Main")

local Indexer = require(ReplicatedStorage.Modules.Indexer)
local LivingIndex = Indexer.new(LivingCom.LivingGuid)

local HealthbarSetQuery = world
:query(link.View, LivingCom.Health, LivingCom.MaxHealth)
:without(HealthbarCom.Healthbar):cached()

local HealthbarRemoveQuery = world
:query(HealthbarCom.Healthbar)
:without(LivingCom.Health):cached()

local function UpdateHealthbar(e:jecs.Entity, Healthbar:BillboardGui, Health:number, MaxHealth:number)
    local IsDead = world:has(e, LivingCom.IsDead)
    if not IsDead then
        Healthbar.hp.Text = `{jUtil.Abr(Health)}/{jUtil.Abr(MaxHealth)}`
        Healthbar.fill.Size = UDim2.fromScale(math.clamp(Health/MaxHealth, 0, 1), 1)
        return
    else
        Healthbar.hp.Text = "Dead"
        Healthbar.fill.Size = UDim2.fromScale(0, 1)
        return
    end
end

local function HealthbarFn(e)
    local Healthbar: BillboardGui?, Health:number?,  MaxHealth: number? = world:get(e, HealthbarCom.Healthbar, LivingCom.Health, LivingCom.MaxHealth)
    if not Healthbar or not MaxHealth or not Health then return end
    UpdateHealthbar(e, Healthbar, Health, MaxHealth)
end

local function RemoveHealthbar(e, Healthbar)
    if not Healthbar then Healthbar = world:get(e, HealthbarCom.Healthbar) end
    if Healthbar then
        Healthbar:Destroy()
    end
    world:remove(e, HealthbarCom.Healthbar)
end

world:changed(LivingCom.Health, HealthbarFn)
world:added(LivingCom.IsDead, HealthbarFn)
world:removed(LivingCom.IsDead, function(e) RemoveHealthbar(e) end)
world:added(LivingCom.LivingGuid, function(e: jecs.Entity, _, guid)
    for _, View:Instance in workspace.entities:GetChildren() do
        if View:GetAttribute("LivingGuid") == guid then
            world:set(e, link.View, View)
            LivingIndex:Set(e, guid)
            break
        end
    end
end)

return {function()
    for e: jecs.Entity, View: Model, Health: number, MaxHealth: number in HealthbarSetQuery do
        local Healthbar = ReplicatedStorage.Assets.Healthbar:Clone()
        Healthbar.Enabled = true
        Healthbar.Parent = View.PrimaryPart
        UpdateHealthbar(e, Healthbar, Health, MaxHealth)
        world:set(e, HealthbarCom.Healthbar, Healthbar)
    end
    for e: jecs.Entity, Healthbar: BillboardGui in HealthbarRemoveQuery do
        RemoveHealthbar(e, Healthbar)
    end
end, -1, "postsim"}