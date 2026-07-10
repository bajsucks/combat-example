--[[
    Applies replicated players on client
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local link = require(ReplicatedStorage.Components.link)
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local Groups = require(ReplicatedStorage.Modules.Groups)
local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local UserIdIndex = Indexer.new(PlayerCom.UserId)

return function()
	for e: jecs.Entity in world:query(table.unpack(Groups.ValidPlayer)):without(PlayerCom.Handled) do -- players that were just replicated
		world:add(e, PlayerCom.Handled)
		local userId = world:get(e, PlayerCom.UserId)
		UserIdIndex:Set(e, userId)
		local Player = Players:GetPlayerByUserId(userId)
		world:set(e, PlayerCom.Player, Player)
		do
			local Char = Player.Character
			if Char then
				world:set(e, link.View, Char)
			end
		end
		Player.CharacterAdded:Connect(function(Char)
			world:set(e, link.View, Char)
		end)
	end
end
