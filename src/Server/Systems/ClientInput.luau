local ClientInput = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputCom = require(ReplicatedStorage.Components.InputCom)
local InputConfig = require(ReplicatedStorage.Constants.InputConfig)
local InputRemote = ReplicatedStorage.Remotes.Input

local jecs = require(ReplicatedStorage.Packages.jecs)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world = WorldProvider:Get("Main")
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local UserIdIndex = Indexer.new(PlayerCom.UserId)

function ClientInput.OnInput(Player: Player, ActionId: number, Input: Enum.KeyCode)
	local e = UserIdIndex:First(Player.UserId)
	if not e then return end
	local InputKey = typeof(Input) ~= "EnumItem" and Input or InputConfig.NetworkedBinds[Input]
	if typeof(InputKey) ~= "string" then
		error("ARGH!")
	end
	if ActionId == InputConfig.ActionIds.Begin then
		local IE = world:entity()
		world:set(IE, InputCom.source, e)
		world:set(IE, InputCom.Keybind, InputKey)
	elseif ActionId == InputConfig.ActionIds.End then
		for IE: jecs.Entity, source: jecs.Entity, Keybind: string in world:query(InputCom.source, InputCom.Keybind) do
			if world:get(source, PlayerCom.Player) == Player and Keybind == InputKey then
				world:delete(IE)
			end
		end
	end
end

InputRemote.OnServerEvent:Connect(ClientInput.OnInput)

Players.PlayerRemoving:Connect(function(Player: Player)
	for IE: jecs.Entity, source: jecs.Entity in world:query(InputCom.source) do
		if world:get(source, PlayerCom.Player) == Player then
			world:delete(IE)
		end
	end
end)

return {}
