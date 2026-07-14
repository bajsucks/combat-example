local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local Logger = require(ReplicatedStorage.Modules.Logger)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

type AAT = AttackCom.AAT

local Interrupted = world   :query(AttackCom.Threads)
                            :with(AttackCom.Interrupt):cached()

local KeybindQuery = world  :query(PlayerCom.Inputs, AttackCom.Fighter)
                            :without(AttackCom.Blocking, AttackCom.Stunned, AttackCom.InAttack):cached()

return {function()
    for e: jecs.Entity, Inputs: {[string]: boolean}, Fighter: string in KeybindQuery do
        local Keybind = next(Inputs)
        if not Fighter then
            Logger.warn("No fighter son")
            continue
        end
        local maps: Folder = ServerStorage.Constants.AttackMaps:FindFirstChild(Fighter)
        if not maps then
            Logger.warn(`Tried to use an attack map that does not exist! Map fighter: {Fighter}`)
            continue
        end
        local map = maps:FindFirstChild(Keybind)
        if not map then
            Logger.warn(`Tried to use an attack map that does not exist! Map: {Keybind}`)
            continue
        end
        task.defer(require(map), e)
    end
    for e: jecs.Entity, AATs: {[string]: AAT} in Interrupted do
        for _, AAT: AAT in AATs do
            local Thread: thread, Interrupt: (jecs.Entity)->() = AAT[1], AAT[2]
            if Thread and coroutine.status(Thread) == "suspended" then
                task.cancel(Thread)
                Interrupt(e)
            else
                Logger.warn("Error while cancelling an active attack thread! Something in combat might break")
            end
        end
        world:remove(e, AttackCom.Threads)
    end
end, -1, "postsim"}