local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local module = {}
local Logger = require(script.Parent.Logger)
local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local CooldownCom = require(ReplicatedStorage.Components.CooldownCom)
local CombatInfo = require(ReplicatedStorage.Constants.CombatInfo)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local WorldProvider = require(script.Parent.WorldProvider)
local world = WorldProvider.Get("Main")

function module.IsOnCooldown(Source, Keybind)
    local Cooldowns, Fighter = world:get(Source, CooldownCom.Cooldowns, AttackCom.Fighter)
    if not Fighter then
        Logger.warn("Something went wrong btw");
        return false 
    end
    if not Cooldowns then
        Cooldowns = {}
        world:set(Source, CooldownCom.Cooldowns, Cooldowns)
    end
    if not Cooldowns[Fighter] then return false end
    local expires = Cooldowns[Fighter][Keybind]
    if not expires then return false end
    if workspace:GetServerTimeNow() > expires then return false end
    return true
end

function module.SetCooldown(Source, Keybind)
    if RunService:IsClient() then
        module.CreateCooldownVisuals(Source, Keybind)
        return
    end
    local Cooldowns, Fighter = world:get(Source, CooldownCom.Cooldowns, AttackCom.Fighter)
    if not Cooldowns then
        Cooldowns = {}
        world:set(Source, CooldownCom.Cooldowns, Cooldowns)
    end
    if not Fighter then
        Logger.warn("Something went wrong btw");
        return false 
    end
    if not Cooldowns[Fighter] then
        Cooldowns[Fighter] = {}
    end
    local CooldownDuration = CombatInfo[Fighter].Cooldown
    if not CooldownDuration then return true end -- doesn't have a cooldown
    local c = Cooldowns[Fighter]
	c[Keybind] = workspace:GetServerTimeNow() + CooldownDuration
    return true
end

local CooldownAddConst = 0.1
-- all cooldowns are slower by 0.1 to make sure you can't use a move while it's still on cooldown on the server because delay blah blah
-- TLDR important const but can be tweaked a lil
function module.CreateCooldownVisuals(Source, Keybind)
    if Logger.isDebug() and RunService:IsServer() then
        Logger.warn("Buffoon, that's a client tool!");
    end
    local Cooldowns, Fighter = world:get(Source, CooldownCom.Cooldowns, AttackCom.Fighter)
    if not Cooldowns then
        Cooldowns = {}
        world:set(Source, CooldownCom.Cooldowns, Cooldowns)
    end
    Logger.warn(debug.info)
    local cInfo = CombatInfo[Fighter][Keybind]
    if not cInfo.Cooldown then Logger.warn(Keybind, "is missing cooldown info!"); return end
    local CooldownDuration = cInfo.Cooldown + CooldownAddConst
    local VisualName = cInfo.VisualName
    if not CooldownDuration then return end
    if not Cooldowns[Fighter] then
        Cooldowns[Fighter] = {}
    end
    local c = Cooldowns[Fighter]
	c[Keybind] = workspace:GetServerTimeNow() + CooldownDuration
    if not VisualName then return end
    local ui = ReplicatedStorage.Assets.cooldown:Clone()
    ui.Parent = jUtil.GetLocalPlayerGui().Cooldowns
    ui.n.Text = VisualName
    ui.bar.c.Text = jUtil.Abr(CooldownDuration)
    local num = Instance.new("NumberValue")
    num.Value = CooldownDuration
    TweenService:Create(ui.bar.bar.fill, TweenInfo.new(CooldownDuration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)}):Play()
    local tw = TweenService:Create(num, TweenInfo.new(CooldownDuration, Enum.EasingStyle.Linear), {Value = 0})
    tw:Play()
    local j = Janitor.new()
    j:Add(num, "Destroy")
    j:Add(ui, "Destroy")
    j:Add(num.Changed:Connect(function()
        ui.bar.c.Text = jUtil.Abr(num.Value)
    end), "Disconnect")
    tw.Completed:Once(function()
        j:Destroy()
    end)
end

return module