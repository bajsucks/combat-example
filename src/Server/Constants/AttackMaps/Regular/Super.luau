--[[
    Empty attack. You can use this as a template for all attacks
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttackCom = require(ReplicatedStorage.Components.AttackCom)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local jecs = require(ReplicatedStorage.Packages.jecs)
local world = WorldProvider.Get("Main")

-- Put stuff like damage here so it's easy to change later
-- local var = {
    
-- }

return function(source:jecs.Entity)
    local AAT = world:get(source, AttackCom.Threads) -- Active Attack Threads
    if not AAT then
        AAT = {}
        world:set(source, AttackCom.Threads, AAT)
    end
    local ThreadGUID = jUtil.GetGUID()
    local function Interrupt()
        -- cancel stuff for attack
        AAT[ThreadGUID] = nil
        if jUtil.DictCount(AAT) == 0 then
            world:remove(source, AttackCom.Threads)
        end
    end

    AAT[ThreadGUID] = {task.defer(function()

        -- code here chat

        Interrupt()
    end), Interrupt}
end