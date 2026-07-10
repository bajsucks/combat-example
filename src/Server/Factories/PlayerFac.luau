local Fac = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local Logger = require(ReplicatedStorage.Modules.Logger)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local mirrorTCP = WorldProvider.GetMirror("Main", "TCP")

export type PlayerConfig = {
	Player: Player,
	UserId: number,
}

--[[
    Creates a new Player entity
]]
function Fac.new(config: {}?)
	if not config or not config.Player or not config.UserId then
		Logger.warn("Tried to create a player with an invalid config! That behavior is not supported.")
		return
	end
	local e = world:entity()
	world:set(e, PlayerCom.Player, config.Player)
	world:set(e, PlayerCom.UserId, config.UserId)
	world:set(e, mirrorTCP.Networked)
	return e
end

-- does not need a Destroy() function, since when player leaves you just destroy his entity

return Fac
