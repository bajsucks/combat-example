local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local Logger = require(script.Parent.Logger)
local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local UserIdIndex = Indexer.new(PlayerCom.UserId)
local LivingIndex = Indexer.new(LivingCom.LivingGuid)

function module.PlayerByUserId(UserId:number)
    return UserIdIndex:First(UserId)
end

function module.LivingByView(View:Instance)
    if not View then warn("No view!"); return end
    local Guid = View:GetAttribute("LivingGuid")
    if not Guid then Logger.warn("No LivingGuid attribute!"); return end
    Logger.warn("Guid exists, bruh", Guid)
    Logger.warn(LivingIndex:First(Guid))
    -- problem: client LivingIndex doesn't actually have living people bruh
    return LivingIndex:First(Guid)
end

return module