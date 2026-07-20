local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IndexerUtils = require(script.Parent.IndexerUtils)
local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local link = require(ReplicatedStorage.Components.link)
local env = require(ReplicatedStorage.Constants.env)
local DamageFac = require(ReplicatedStorage.Factories.DamageFac)
local EZHitbox = require(ReplicatedStorage.Packages.EZHitbox)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Logger = require(script.Parent.Logger)
local SM = require(script.Parent.SM)
local module = {}
local WorldProvider = require(script.Parent.WorldProvider)
local world = WorldProvider.Get("Main")

function module.GetMap(source: jecs.Entity, Move:string)
    local Fighter: string = world:get(source, AttackCom.Fighter)
    if not Fighter then return end
    local FighterMap = ReplicatedStorage.Constants.AttackMaps:FindFirstChild(Fighter)
    if not FighterMap then return end
    local Map = FighterMap:FindFirstChild(Move)
    return Map and require(Map) or false
end

function module.Box(View: Instance, cf: CFrame, params:{})
    if Logger.isDebug() and not params.Lifetime then -- box is instant so ezhitbox won't display it
        local VisualBox = Instance.new("Part")
        VisualBox.Color = Color3.fromRGB(255, 0, 0)
        VisualBox.Anchored = true
        VisualBox.Transparency = 0.8
        VisualBox.Size = params.Size
        VisualBox.CanCollide = false
        VisualBox.Parent = workspace.visual
        VisualBox:PivotTo(cf)
        task.defer(function()
            task.wait(0.05)
            VisualBox:Destroy()
        end)
    end
    return EZHitbox.box(params.Size, cf, {
        AutoStart = true,
        Blacklist = {View},
        Debug = Logger.isDebug(),
        LookingFor = "Humanoid",
        VelocityPrediction = false,
        Lifetime = params.Lifetime
    })
end

local function log(reason:string)
    Logger.warn("Ended because", reason)
end

function module.Sanitycheck(source: jecs.Entity, Move: string, HitboxN: number?, Hits:{string})
    local View: Model?, Player: Player?, Fighter: string? = world:get(source, link.View, PlayerCom.Player, AttackCom.Fighter)
    if not View or not Player or not Fighter then log("Invalid 1"); return end
    local Stunned = world:has(source, AttackCom.Blocking, AttackCom.Stunned)
    if Stunned then log("Invalid: stun"); return end
    if not HitboxN and not Hits then -- if it's windup and you're already inattack you're cooked
        if world:has(source, AttackCom.InAttack) then log("Invalid: inattack"); return end
    end
    local Map = module.GetMap(source, Move)
    if not Map then log("Invalid: map"); return end
    local Ping = Player:GetNetworkPing()
    local MapHitboxes = Map.Hitboxes
    if not MapHitboxes then log("Invalid: maphitboxes"); return end
    if not HitboxN and not Hits then return true end -- windup sanity check ends early
    local hb = MapHitboxes[HitboxN]
    if not hb then log("Invalid: hb"); return end
    local HitboxBound: Vector3|number = hb.Size
    local HitboxOffset: Vector3 = hb.Offset:Abs()
    local MaxHitboxBound = 0
    if typeof(HitboxBound) == "Vector3" then
        MaxHitboxBound = math.max(HitboxBound.X, HitboxBound.Z)
    end
    MaxHitboxBound += HitboxOffset.X + HitboxOffset.Z -- y is ignored for sanity checks because gravity, instead it should be logged to catch repeat offenders (like autokills)
    local Bounds = (Ping*env.MaxSaneVelocity*1.25) + MaxHitboxBound
    local Pos = View:GetPivot().Position
    for _, Guid in Hits do
        local eHit = IndexerUtils.LivingByGuid(Guid)
        local HitView:Model = world:get(eHit, link.View)
        local HitPos = HitView:GetPivot().Position
        local diff = Pos - HitPos
        local diffXZ = jUtil.VectorNoY(diff).Magnitude
        local diffY = math.abs(diff.Y)
        if diffXZ > Bounds then log("Invalid: bounds"); return end
        if diffY > Bounds then
            Logger.warn(`JECC AntiCheat detection: dY{diffY} > Bounds {Bounds}`)
        end
    end
    return true
end

function module.ReplicatedWindup(Player: Player, Move:string)
    local source: jecs.Entity = IndexerUtils.PlayerByUserId(Player.UserId)
    if not source or not Move then return end
    if module.Sanitycheck(source, Move) then
        local Map = module.GetMap(source, Move)
        if not Map then return end
        Map.Attack(source, true)
    end
end

function module.ReplicatedHitbox(Player: Player, Move:string, HitboxN: number, Hits: {string})
    if not Move or not HitboxN or not Hits or #Hits == 0 then return end
    local source: jecs.Entity = IndexerUtils.PlayerByUserId(Player.UserId)
    if not source then return end
    if module.Sanitycheck(source, Move, HitboxN, Hits) then
        local Map = module.GetMap(source, Move)
        if not Map then return end
        local params = Map.Hitboxes[HitboxN]
        Logger.print("SERVERDAMAGE", params.Damage)
        local Stun = params.Stun
        for _, guid in Hits do
            local Target = IndexerUtils.LivingByGuid(guid)
            DamageFac.new({source = source, damage = params.Damage, target = Target})
            if Stun then
                SM.SetTimer(Target, Move, {AttackCom.Stunned}, nil, Stun)
            end
        end
    end
end

function module.ConnectInterrupt(source: jecs.Entity, j: Janitor.Janitor, thread: thread)
    local Cleanup = world:added(AttackCom.Stunned, function(e: jecs.Entity)
        if source ~= e then return end
        warn("Interrupted")
        j:Destroy()
        if coroutine.status(thread) == "suspended" then
            coroutine.close(thread)
        elseif coroutine.status(thread) ~= "dead" then
            Logger.warn("Failed to close thread during interrupt!!!!!!!")
        end
        Logger.warn("INTERRUPTED ON SERVER")
    end)
    j:Add(Cleanup, true)
end

return module