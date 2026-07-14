local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AttackFac = require(ServerStorage.Factories.AttackFac)
local LivingFac = require(ServerStorage.Factories.LivingFac)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local link = require(ReplicatedStorage.Components.link)
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local Logger = require(ReplicatedStorage.Modules.Logger)
local Relay = require(ReplicatedStorage.Modules.Relay)
local PlayerFac = require(ServerStorage.Factories.PlayerFac)
local DataLoader = require(ServerStorage.Modules.DataLoader)
local DataUtility = require(ServerStorage.Modules.DataUtility)
local jecs = require(ReplicatedStorage.Packages.jecs)

local UserIdIndex = Indexer.new(PlayerCom.UserId)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

Players.PlayerAdded:Connect(function(Player)
	local e = PlayerFac.new({ UserId = Player.UserId, Player = Player })
	UserIdIndex:Set(e, Player.UserId)
end)

local function FlushPlayerEntity(e: jecs.Entity, Player: Player)
	DataUtility.End(Player, DataLoader.Dehydrate(e))
end

local function PlayerRemoving(Player)
	local e = UserIdIndex:First(Player.UserId)
	if not e then
		Logger.warn("Tried to remove a player that was already removed, huh")
	end
	if world:has(e, PlayerCom.IsLoaded) and world:has(e, PlayerCom.Hydrated) then
		FlushPlayerEntity(e, Player)
	end
	UserIdIndex:Set(e, nil)
	world:delete(e)
end

local CloseQuery = world:query(PlayerCom.Player):with(PlayerCom.IsLoaded, PlayerCom.Hydrated):cached()
local function BindToClose()
	for e, Player in CloseQuery do
		FlushPlayerEntity(e, Player)
	end
end
game:BindToClose(BindToClose)
Players.PlayerRemoving:Connect(PlayerRemoving)

ReplicatedStorage.Remotes.PlayerLoaded.OnServerEvent:Connect(function(Player)
	Logger.print(`Received player loaded for {Player.DisplayName}!`)
	local e = UserIdIndex:First(Player.UserId)
	if not e then
		error("Tried to load player that is not registered!")
	end
	if world:has(e, PlayerCom.Hydrated) then
		error("Player is already hydrated!")
	end
	world:add(e, PlayerCom.IsLoaded)
	-- hydrate, since the player is now ready
	Logger.print("Beginning profile load!")
	local Profile = DataUtility.Begin(Player)
	DataLoader.Hydrate(e, Profile.Data) -- Data hydration
	Relay.HydrateTCP(Player) -- Entity hydration to client
	Relay.HydrateUDP(Player)
	local Name = Player.DisplayName == Player.Name and Player.DisplayName or `{Player.DisplayName} ({Player.Name})`
	Logger.print(`Player {Name} was hydrated successfully`)
	world:add(e, PlayerCom.Hydrated)
	local function Spawn(Char)
		world:set(e, link.View, Char)
		LivingFac.Destroy(e)
		AttackFac.Destroy(e)
		LivingFac.new(e, {View = Player.Character})
		AttackFac.new(e)
	end
	local c = Player.CharacterAdded:Connect(function(Char)
		Spawn(Char)
	end)
	if Player.Character then
		Spawn(Player.Character)
	else
		Player.CharacterAdded:Wait()
	end
	Players.PlayerRemoving:Once(function(p)
		if p == Player then
			c:Disconnect()
		end
	end)
end)

return {}