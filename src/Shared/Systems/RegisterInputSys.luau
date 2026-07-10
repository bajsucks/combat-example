local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputConfig = require(ReplicatedStorage.Constants.InputConfig)

UserInputService.InputBegan:Connect(function(InputObject: InputObject)
	if InputConfig.NetworkedBinds[InputObject.KeyCode] then
		ReplicatedStorage.Remotes.Input:FireServer(InputConfig.ActionIds.Begin, InputObject.KeyCode)
	end
end)
UserInputService.InputEnded:Connect(function(InputObject: InputObject)
	if InputConfig.NetworkedBinds[InputObject.KeyCode] then
		ReplicatedStorage.Remotes.Input:FireServer(InputConfig.ActionIds.End, InputObject.KeyCode)
	end
end)
local mouse = Players.LocalPlayer:GetMouse()
mouse.Button1Down:Connect(function()
	ReplicatedStorage.Remotes.Input:FireServer(InputConfig.ActionIds.Begin, "m1")
end)
mouse.Button1Up:Connect(function()
	ReplicatedStorage.Remotes.Input:FireServer(InputConfig.ActionIds.End, "m1")
end)
mouse.Button2Down:Connect(function()
	ReplicatedStorage.Remotes.Input:FireServer(InputConfig.ActionIds.Begin, "m2")
end)
mouse.Button2Up:Connect(function()
	ReplicatedStorage.Remotes.Input:FireServer(InputConfig.ActionIds.End, "m2")
end)
return {}
