local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local InputConfig = require(ReplicatedStorage.Constants.InputConfig)
local InputRemote = ReplicatedStorage.Remotes.Input
local ClientInput = {}
ClientInput.Inputs = {}

function ClientInput.OnInput(Player: Player, ActionId: number, Input: Enum.KeyCode)
	local tbl = ClientInput.Inputs[Player]
	local InputKey = typeof(Input) ~= "EnumItem" and Input or InputConfig.NetworkedBinds[Input]
	if typeof(InputKey) ~= "string" then
		error("ARGH!")
	end
	if ActionId == InputConfig.ActionIds.Begin then
		tbl[InputKey] = true
	elseif ActionId == InputConfig.ActionIds.End then
		tbl[InputKey] = nil
	end
end

function ClientInput.ProcessInputs()
	for Player: Player, Inputs: { [string]: boolean } in ClientInput.Inputs do
		for InputKey: string in Inputs do
			local fnModule = ServerStorage.Inputs:FindFirstChild(InputKey)
			if not fnModule then
				continue
			end
			local fn = require(fnModule)
			fn(Player)
		end
	end
end

InputRemote.OnServerEvent:Connect(ClientInput.OnInput)

Players.PlayerAdded:Connect(function(Player: Player)
	ClientInput.Inputs[Player] = {}
end)

Players.PlayerRemoving:Connect(function(Player: Player)
	ClientInput.Inputs[Player] = nil
end)

return ClientInput
