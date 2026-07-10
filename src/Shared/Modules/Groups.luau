--[[
    This module holds references to frequently used queries
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)

local Groups = {}

-- Groups of tags/components
Groups.ValidPlayer = {
	PlayerCom.IsLoaded,
	PlayerCom.Player,
}

return Groups
