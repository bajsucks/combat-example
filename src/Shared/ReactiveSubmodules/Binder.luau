--[[
    Reactive Submodule that binds buttons to functions using tags/attributes
    made by baj
    
    This is not public
]]
--[[
    Usage:
    Tag - Binder
    Attribute - BinderID - Non-unique ID of that element. Functions binded to that ID will apply.
    Attribute - Args - Optional arguments to provide to the function.
    Function - module.Bind(ID | {ID}, func(args) | { func(args) } ) - Bind new function(s) to BinderID(s)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarterGui = game:GetService("StarterGui")

local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local SignalPlus = require(ReplicatedStorage.Packages.jTools.SignalPlus)
local module = {}
module.Binds = {}
local NewBind = SignalPlus()

function module.new(obj: GuiButton)
	if obj:IsDescendantOf(StarterGui) then
		return
	end
	local BinderID = obj:GetAttribute("BinderID")
	local Binded = module.Binds[BinderID] or {}
	NewBind:Connect(function(ID: string, func: (args: string) -> ())
		if ID ~= BinderID then
			return
		end
		table.insert(Binded, func)
	end)
	local j = Janitor.new()
	local con = obj.Activated:Connect(function()
		local args = obj:GetAttribute("Args")
		for _, func in Binded do
			func(args)
		end
	end)
	j:Add(con)
	local function Clean()
		j:Destroy()
	end
	obj.Destroying:Once(Clean)
end
--[[
    Binds a new function to BinderID
    @param ID BinderID or a table of BinderIDs that will be binded
    @param func Function(s) that will be binded
]]
function module.Bind(ID: string | { string }, func: (args: string) -> () | { (args: string) -> () })
	local function BindOne(ID: string, func: (args: string) -> ())
		module.Binds[ID] = module.Binds[ID] or {}
		table.insert(module.Binds[ID], func)
		NewBind:Fire(ID, func)
	end

	local function bind(ID: string, func: (args: string) -> () | { (args: string) -> () })
		if type(func) == "table" then
			for _, f in func do
				BindOne(ID, f)
			end
		else
			BindOne(ID, func)
		end
	end

	if type(ID) == "table" then
		for _, str in ID do
			bind(str, func)
		end
	else
		bind(ID, func)
	end
end
--[[
    Same as module.Bind(), but also erases all current binds to that ID
    @param ID BinderID that will be binded
    @param func Function(s) that will be binded
]]
function module.BindOverride(ID: string, func: (args: string) -> () | { (args: string) -> () })
	module.Binds[ID] = nil
	module.Bind(ID, func)
end

module.Tags = {
	Binder = module.new,
}

return module
