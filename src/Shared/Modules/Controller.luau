--[[
    Entrance point for all environments (both client and server)
    This module:
    - Requires components and tags in order
    - Calls systems every frame in order
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local module = {}

-- init components and tags in correct order (to avoid ID desync!)
do
	local Folder = ReplicatedStorage.Components
	local Components = Folder:GetChildren()
	table.sort(Components, function(a, b)
		return a.Name < b.Name
	end)
	for _, Component in Components do
		if not Component:IsA("ModuleScript") then
			continue
		end
		require(Component)
	end
end

local Relay = require(ReplicatedStorage.Modules.Relay)
local linkSys = require(ReplicatedStorage.Systems.linkSys)
local SM = require(ReplicatedStorage.Systems.SM)

-- simulation and order
if RunService:IsClient() then
	local PlayerReplicateSys = require(ReplicatedStorage.Systems.PlayerReplicateSys)
	local CameraSys = require(ReplicatedStorage.Systems.CameraSys)
	local DebugSys = require(ReplicatedStorage.Systems.DebugSys)
	local Input = require(ReplicatedStorage.Modules.Input)
	require(ReplicatedStorage.Systems.RegisterInputSys)

	RunService.PreSimulation:Connect(function(dt)
		Input.update(dt)

		Input.runPhase("Main", function()
			linkSys()
			PlayerReplicateSys()
			DebugSys()
			CameraSys(dt)
			SM.Process()
		end)
	end)

	ReplicatedStorage.Remotes.ReplicateTCP.OnClientEvent:Connect(Relay.ApplyTCP)
	ReplicatedStorage.Remotes.ReplicateUDP.OnClientEvent:Connect(Relay.ApplyUDP)
else
	local env_server = require(ServerStorage.Constants.env_server)

	local PlayerSys = require(ServerStorage.Systems.PlayerSys)
	local ClientInput = require(ServerStorage.Systems.ClientInput)

	local TotalDt = 0
	local function Replicate()
		if env_server.replication_throttle then
			if TotalDt >= env_server.replication_throttle_speed then
				TotalDt = TotalDt - env_server.replication_throttle_speed
				Relay.SendTCP()
				Relay.SendUDP()
			end
		else
			Relay.SendTCP()
			Relay.SendUDP()
		end
	end

	RunService.PreSimulation:Connect(function()
		linkSys()
	end)

	RunService.PostSimulation:Connect(function(dt)
		TotalDt += dt
		PlayerSys()
		ClientInput.ProcessInputs()
		Replicate()
		SM.Process()
	end)
end

return module
