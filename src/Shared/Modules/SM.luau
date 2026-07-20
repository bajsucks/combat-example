local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldProvider = require(script.Parent.WorldProvider)
local world = WorldProvider.Get("Main")
local SM = {}
SM.States = {}

local function GetStates(e: jecs.Entity)
	if not SM.States[e] then
		SM.States[e] = {}
	end
	return SM.States[e]
end

--[[
    Sets a state

	@param e Entity to affect
	@param StateId unique state id to use
	@param Tags Component tags to apply
	@param CheckFn Function that returns true if the state should continue

	@return function Function to cancel the state
]]
function SM.Set(e: jecs.Entity, StateId: string, Tags: {}, CheckFn: (e: jecs.Entity) -> boolean?)
	local States = GetStates(e)
	States[StateId] = {
		Tags = Tags,
		CheckFn = CheckFn,
	}
	for _, v in Tags do
		world:add(e, v)
	end
	return function()
		SM.Rm(e, StateId)
	end
end

--[[
    Will auto-cancel the state after this amount of seconds passes

	@param e Entity to affect
	@param StateId unique state id to use
	@param Tags Component tags to apply
	@param CheckFn Function that returns true if the state should continue

	@return function Function to cancel the state
]]
function SM.SetTimer(e: jecs.Entity, StateId: string, Tags: {}, CheckFn: (e: jecs.Entity) -> boolean?, Time: number)
	local States = GetStates(e)
	States[StateId] = {
		Tags = Tags,
		CheckFn = CheckFn,
		TimeGoal = os.clock() + Time,
	}
	for _, v in Tags do
		world:add(e, v)
	end
	return function()
		SM.Rm(e, StateId)
	end
end

--[[
    Will auto-cancel the state after this amount of heartbeats passes

	@param e Entity to affect
	@param StateId unique state id to use
	@param Tags Component tags to apply
	@param CheckFn Function that returns true if the state should continue

	@return function Function to cancel the state
]]
function SM.SetFrames(e: jecs.Entity, StateId: string, Tags: {}, CheckFn: (e: jecs.Entity) -> boolean?, Frames: number)
	local States = GetStates(e)
	States[StateId] = {
		Tags = Tags,
		CheckFn = CheckFn,
		FramesGoal = Frames,
		FramesNow = 0,
	}
	for _, v in Tags do
		world:add(e, v)
	end
	return function()
		SM.Rm(e, StateId)
	end
end

--[[
    Cancels the state immediately

	@param e Entity to affect
	@param StateId unique state id to use
]]
function SM.Rm(e: jecs.Entity, StateId: string)
	local States = GetStates(e)
	local State = States[StateId]
	if not State then
		return
	end
	local ToRemove = {}
	for _, v in State.Tags do
		ToRemove[v] = true
	end
	States[StateId] = nil
	for _, tbl in States do
		for _, v in tbl.Tags do
			if ToRemove[v] then
				ToRemove[v] = nil
			end
		end
	end
	for i in ToRemove do
		world:remove(e, i)
	end
end

function SM.Process()
	local clock = os.clock()
	for e: jecs.Entity, States: {} in SM.States do
		for StateId: string, State: {} in States do
			if State.CheckFn and not State.CheckFn(e) then
				SM.Rm(e, StateId)
				continue
			end
			if State.TimeGoal then
				if clock > State.TimeGoal then
					SM.Rm(e, StateId)
					continue
				end
			end
			if State.FramesGoal then
				State.FramesNow += 1
				if State.FramesNow > State.FramesGoal then
					SM.Rm(e, StateId)
					continue
				end
			end
		end
	end
end

return SM