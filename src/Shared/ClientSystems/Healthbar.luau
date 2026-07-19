local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthbarCom = require(ReplicatedStorage.Components.HealthbarCom)
local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local link = require(ReplicatedStorage.Components.link)
local Logger = require(ReplicatedStorage.Modules.Logger)
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
    Logger.print(Health, MaxHealth)
    if not IsDead then
        Healthbar.hp.Text = `{jUtil.Abr(Health)}/{jUtil.Abr(MaxHealth)}`
    else
        Healthbar.hp.Text = "Dead"
    end
    Healthbar.fill.Size = UDim2.fromScale(math.clamp(Health/MaxHealth, 0, 1), 1)
    -- fill not changing size for some reason?
end

local function HealthbarFn(e)
    local Healthbar: BillboardGui?, Health:number?,  MaxHealth: number? = world:get(e, HealthbarCom.Healthbar, LivingCom.Health, LivingCom.MaxHealth)
    if not Healthbar or not MaxHealth or not Health then return end
    UpdateHealthbar(e, Healthbar, Health, MaxHealth)
end

world:changed(LivingCom.Health, HealthbarFn)
world:added(LivingCom.IsDead, HealthbarFn)
world:removed(LivingCom.IsDead, HealthbarFn)
world:added(LivingCom.LivingGuid, function(e: jecs.Entity, _, guid)
    for _, View:Instance in workspace.entities:GetChildren() do
        if View:GetAttribute("LivingGuid") == guid then
            world:set(e, link.View, View)
            LivingIndex:Set(e, guid)
            Logger.print("Set", guid)
            Logger.print("set livingguid")
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
        Healthbar:Destroy()
        world:remove(e, HealthbarCom.Healthbar)
    end
end, -1, "postsim"}