local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EUtil = require(ReplicatedStorage.Modules.EUtil)
local Relay = require(ReplicatedStorage.Modules.Relay)
local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

export type ChildCache = { any }

-- NEVER allow for the same index to appear twice
local Replicated = {
	-- Components
	-- Tags
}
local Static = {
	-- Components
	View = world:component() :: jecs.Entity<Instance>, -- instance link
	PhysicCache = world:component() :: jecs.Entity<ChildCache>, -- cached instance/property for physic relationships
	KinematicCache = world:component() :: jecs.Entity<ChildCache>, -- cached instance/property for kinematic relationships
	-- Relationships
	Static = world:component(), -- sync com -> inst once
	Physic = world:component(), -- sync inst -> com every frame
	Kinematic = world:component(), -- sync com -> inst every frame
}
local Merged = EUtil.Merge(Replicated, Static)
for i, id in Merged do
	world:set(id, jecs.Name, i)
end
for _, id in Replicated do
	Relay.MarkReplicate(id)
end

return Merged :: typeof(Replicated) & typeof(Static)
