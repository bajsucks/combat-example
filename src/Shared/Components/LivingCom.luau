local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EUtil = require(ReplicatedStorage.Modules.EUtil)
local Relay = require(ReplicatedStorage.Modules.Relay)
local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

-- NEVER allow for the same index to appear twice
local Replicated = {
	-- Components
	Health = world:component() :: jecs.Entity<number>,
	MaxHealth = world:component() :: jecs.Entity<number>,
	-- Tags
	IsDead = world:component(),
}
local Static = {
	-- Components
	QDamage = world:component() :: jecs.Entity<{ number }>,
	QHeal = world:component() :: jecs.Entity<{ number }>,
	-- Tags
}
local Merged = EUtil.Merge(Replicated, Static)
for i, id in Merged do
	world:set(id, jecs.Name, i)
end
for _, id in Replicated do
	Relay.MarkReplicate(id)
end

return Merged :: typeof(Replicated) & typeof(Static)
