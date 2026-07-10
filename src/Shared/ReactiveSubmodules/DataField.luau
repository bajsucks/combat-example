--[[
    Reactive Submodule that synchronizes UI fields with Data / SessionData
    made by baj
    
    This is not public
]]
--[[
    Usage:
    Tag - DataField
    Attribute - DataType [Data / SessionData]
    Attribute - Track [Field to track, for example to track `Data.Money` Track should be `Money`]
    Attribute - Format [Formatting function to use. Will pull the name from ReplicatedStorage/Modules/Format. Example: `HumanTime` with data 59 will turn it into `59s`]
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Data = require(ReplicatedStorage.Modules.Data.Data)
local Format = require(ReplicatedStorage.Modules.Format)
local SessionDataClient = require(ReplicatedStorage.Modules.SessionData.SessionDataClient)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local module = {}
local DataUpdated = ReplicatedStorage.Remotes.Data.DataUpdated
local SessionDataUpdated = ReplicatedStorage.Remotes.SessionData.SessionDataReplicate

local function Update(obj: TextLabel, Type: string, Track: string, Data, f: string?)
	local val = Data[Track]
	if not val then
		return
	end
	obj.Text = if f and Format[f] then Format[f](val) else val
end

function module.new(obj: TextLabel)
	if obj:IsDescendantOf(StarterGui) then
		return
	end
	local Type = obj:GetAttribute("DataType")
	assert(Type, "A DataField instance must have a type! Available types: Data, SessionData")
	local Track = obj:GetAttribute("Track")
	assert(Track, "A DataField instance must have a track! Track is an entry from Data or SessionData.")
	local f = obj:GetAttribute("Format")
	local j = Janitor.new()
	local con: RBXScriptConnection
	if Type == "Data" then
		Update(obj, Type, Track, Data.Data, f)
		con = DataUpdated.OnClientEvent:Connect(function(NewData)
			Update(obj, Type, Track, NewData, f)
		end)
	else
		Update(obj, Type, Track, SessionDataClient.Data, f)
		con = SessionDataUpdated.OnClientEvent:Connect(function(NewData)
			Update(obj, Type, Track, NewData, f)
		end)
	end
	j:Add(con)
	local function Clean()
		j:Destroy()
	end
	obj.Destroying:Once(Clean)
end

export type Field = typeof(module.new())

module.Tags = {
	DataField = module.new,
}

return module
