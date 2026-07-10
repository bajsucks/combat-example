--[[
    Utilities to work with the TCP/UDP mirror replication system
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.jecs)

local module = {}

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")
local mirrorTCP = WorldProvider.GetMirror("Main", "TCP")
local mirrorUDP = WorldProvider.GetMirror("Main", "UDP")

--[[
    [Server] Mark components to replicate
    @param e Entity to mark
    @param UDP whether to use the UDP channel for replication
    @param Name jecs.Name to use. If not given, will use tostring(e) instead
    @param Players An optional list of players to replicate to
]]
function module.MarkReplicate(e: jecs.Entity, UDP: boolean?, Name: string?, Players: { Player }?)
	local targetMirror = if UDP then mirrorUDP else mirrorTCP
	world:add(e, targetMirror.Schema)
	if not world:has(e, jecs.Name) then
		world:set(e, jecs.Name, Name or tostring(e))
	end
	if UDP then
		world:set(e, mirrorUDP.Networked, Players)
	else
		world:set(e, mirrorTCP.Networked, Players)
	end
end

--[[
    Collect and replicate TCP changes to clients
]]
function module.SendTCP()
	for player, changes in mirrorTCP:collect() do
		ReplicatedStorage.Remotes.ReplicateTCP:FireClient(player, changes)
	end
end

--[[
    Collect and replicate UDP changes to clients
]]
function module.SendUDP()
	for player, changes in mirrorUDP:collect() do
		ReplicatedStorage.Remotes.ReplicateUDP:FireClient(player, changes)
	end
end

--[[
    [Client] Apply TCP replication changes
]]
function module.ApplyTCP(changes)
	mirrorTCP:apply(changes)
end

--[[
    [Client] Apply UDP replication changes
]]
function module.ApplyUDP(changes)
	mirrorUDP:apply(changes)
end

--[[
    [Server] Hydrate the TCP channel of a player
]]
function module.HydrateTCP(Player: Player)
	mirrorTCP:hydrate(Player)
end

--[[
    [Server] Hydrate the UDP channel of a player
]]
function module.HydrateUDP(Player: Player)
	mirrorUDP:hydrate(Player)
end

return module
