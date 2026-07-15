local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local UserIdIndex = Indexer.new(PlayerCom.UserId)
local LivingIndex = Indexer.new(LivingCom.LivingGuid)

function module.PlayerByUserId(UserId:number)
    return UserIdIndex:First(UserId)
end
function module.LocalPlayer()
    return UserIdIndex:First(Players.LocalPlayer.UserId)
end

function module.LivingByView(View:Instance)
    if not View then return end
    local Guid = View:GetAttribute("LivingGuid")
    if not Guid then return end
    return LivingIndex:First(Guid)
end

return module