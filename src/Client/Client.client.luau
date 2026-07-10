--[[
    Initializes the JECS behaviors on the client.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Modules.Logger)
local Jabby = require(ReplicatedStorage.Packages.Jabby)
local conch = require(ReplicatedStorage.Packages.conch)

local function p(s: string)
	Logger.print("Client:", s)
end

p("Loading ReactiveTags")
require(ReplicatedStorage.Packages.ReactiveTags)

p("Loading ECS")

require(ReplicatedStorage.Modules.Controller)

ReplicatedStorage.Remotes.PlayerLoaded:FireServer()

if Logger.isDebug() then
	p("Loading Conch")
	conch.initiate_default_lifecycle()
	conch.ui.bind_to(Enum.KeyCode.F4)

	local client = Jabby.obtain_client()
	client.spawn_app(client.apps.home, nil)
end
