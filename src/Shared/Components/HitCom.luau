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
    Source = world:component() :: jecs.Entity<jecs.Entity>,
    Target = world:component() :: jecs.Entity<jecs.Entity>,
    Damage = world:component() :: jecs.Entity<number>,
    Effects = world:component() :: jecs.Entity<(e: jecs.Entity)->()>,
    -- Tags

    -- Relationships
    
}
local Merged = EUtil.Merge(Replicated, Static)
for i, id in Merged do
    world:set(id, jecs.Name, i)
end
for _, id in Replicated do
    Relay.MarkReplicate(id)
end

return Merged :: typeof(Replicated) & typeof(Static)
