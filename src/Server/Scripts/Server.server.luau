--[[
    Initializes the JECS behaviors on the server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Logger = require(ReplicatedStorage.Modules.Logger)
local entities = Instance.new("Folder")
local visual = Instance.new("Folder")
entities.Parent = workspace
visual.Parent = workspace
entities.Name = "entities"
visual.Name = "visual"

local function p(s: string)
	Logger.print("Server:", s)
end

p("Loading ECS")

require(ReplicatedStorage.Modules.Controller)

p("Loading ProfileStore")
require(ServerStorage.Modules.DataLoader)

if Logger.isDebug() then
	p("Loading Conch")
	local conch = require(ReplicatedStorage.Packages.conch)
	conch.initiate_default_lifecycle()
end