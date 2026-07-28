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

local Benchmark = require(script.Parent.Benchmark)
local Logger = require(script.Parent.Logger)
local Relay = require(ReplicatedStorage.Modules.Relay)
local conch = require(ReplicatedStorage.Packages.conch)
-- simulation and order
if RunService:IsClient() then
	local Input = require(ReplicatedStorage.Modules.Input)
	
	local tbl = {prerender = {}, presim = {}, postsim = {}, postreplication = {}}
	local function get(Inst)
		if Inst:IsA("ModuleScript") then
			local fn, priority, phase = table.unpack(require(Inst))
			if not fn then return end
			tbl[phase] = tbl[phase] or {}
			local n = Inst.Name
			if Logger.isDebug() then
				local MOD_fn = fn
				fn = function(dt)
					Benchmark.Bench(MOD_fn, dt, n)
				end
			end
			table.insert(tbl[phase], {fn, priority})
		end
	end
	for _, Inst in ReplicatedStorage.ClientSystems:GetChildren() do
		get(Inst)
	end
	for _, Inst in ReplicatedStorage.Systems:GetChildren() do
		get(Inst)
	end
	for _, phase in tbl do
		table.sort(phase, function(a, b) return a[2] < b[2]  end)
	end
	RunService.PreRender:Connect(function(dt: number)
		Input.update(dt)
		Input.runPhase("PreRender", function()
			for _, fntbl in tbl.prerender do
				fntbl[1](dt)
			end
		end)
	end)
	RunService.PreSimulation:Connect(function(dt: number)
		Input.runPhase("PreSimulation", function()
			for _, fntbl in tbl.presim do
				fntbl[1](dt)
			end
		end)
	end)
	RunService.PostSimulation:Connect(function(dt: number)
		Input.runPhase("PostSimulation", function()
			for _, fntbl in tbl.postsim do
				fntbl[1](dt)
			end
			for _, fntbl in tbl.postreplication do
				fntbl[1](dt)
			end
			Benchmark.LogIfOverEnv()
		end)
	end)
	ReplicatedStorage.Remotes.ReplicateTCP.OnClientEvent:Connect(Relay.ApplyTCP)
	ReplicatedStorage.Remotes.ReplicateUDP.OnClientEvent:Connect(Relay.ApplyUDP)
else
	local env_server = require(ServerStorage.Constants.env_server)
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
	local tbl = {prerender = {}, presim = {}, postsim = {}, postreplication = {}}
	local function get(Inst)
		if Inst:IsA("ModuleScript") then
			local fn, priority, phase = table.unpack(require(Inst))
			if not fn then return end
			tbl[phase] = tbl[phase] or {}
			local n = Inst.Name
			if Logger.isDebug() then
				local MOD_fn = fn
				fn = function(dt)
					Benchmark.Bench(MOD_fn, dt, n)
				end
			end
			table.insert(tbl[phase], {fn, priority})
		end
	end
	for _, Inst in ServerStorage.Systems:GetChildren() do
		get(Inst)
	end
	for _, Inst in ReplicatedStorage.Systems:GetChildren() do
		get(Inst)
	end
	for _, phase in tbl do
		table.sort(phase, function(a, b) return a[2] < b[2]  end)
	end
	RunService.PreSimulation:Connect(function(dt: number)
		for _, fntbl in tbl.presim do
			fntbl[1](dt)
		end
	end)
	RunService.PostSimulation:Connect(function(dt: number)
		TotalDt += dt
		for _, fntbl in tbl.postsim do
			fntbl[1](dt)
		end
		Replicate()
		for _, fntbl in tbl.postreplication do
			fntbl[1](dt)
		end
		Benchmark.LogIfOverEnv()
	end)

	for _, command in ReplicatedStorage.ConchCommands:GetChildren() do
		command = require(command)
		conch.register(command[1], command[2])
		Logger.print("registered", command)
	end
end

return module
