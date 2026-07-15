local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EUtil = require(ReplicatedStorage.Modules.EUtil)
local Relay = require(ReplicatedStorage.Modules.Relay)
local jecs = require(ReplicatedStorage.Packages.jecs)

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local world: jecs.World = WorldProvider.Get("Main")

-- NEVER allow for the same index to appear twice
local Replicated = {
    -- Components

    -- Tags

    -- Relationships

}

local Static = {
    -- Components
    -- Tags
    m1 = world:component() :: jecs.Entity<nil>,
    m2 = world:component() :: jecs.Entity<nil>,
    r = world:component() :: jecs.Entity<nil>,
    -- Relationships
    Pressing = world:entity() :: jecs.Entity<nil>,
}
local Merged = EUtil.Merge(Replicated, Static)
for i, id in Merged do
    world:set(id, jecs.Name, i)
end
for _, id in Replicated do
    Relay.MarkReplicate(id)
end

return Merged :: typeof(Replicated) & typeof(Static)
