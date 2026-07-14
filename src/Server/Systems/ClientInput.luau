local ClientInput = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputConfig = require(ReplicatedStorage.Constants.InputConfig)
local InputRemote = ReplicatedStorage.Remotes.Input
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world = WorldProvider:Get("Main")
local IndexerUtils = require(ReplicatedStorage.Modules.IndexerUtils)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)

function ClientInput.OnInput(Player: Player, ActionId: number, Input: Enum.KeyCode)
	local e = IndexerUtils.PlayerByUserId(Player.UserId)
	if not e then return end
	local InputKey = typeof(Input) ~= "EnumItem" and Input or InputConfig.NetworkedBinds[Input]
	if typeof(InputKey) ~= "string" then
		error("ARGH!")
	end
	local tbl = world:get(e, PlayerCom.Inputs)
	if not tbl and ActionId == InputConfig.ActionIds.Begin then
		tbl = {}
		world:set(e, PlayerCom.Inputs, tbl)
	elseif not tbl then
		return
	end
	if ActionId == InputConfig.ActionIds.Begin then
		tbl[InputKey] = true
	elseif ActionId == InputConfig.ActionIds.End then
		tbl[InputKey] = nil
		if jUtil.DictCount(tbl) <= 0 then
			world:remove(e, PlayerCom.Inputs)
		end
	end
end

InputRemote.OnServerEvent:Connect(ClientInput.OnInput)

return {}
