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
    Threads = world:component() :: jecs.Entity<{[string]: thread}>,
    -- Tags
    Blocking = world:entity() :: jecs.Entity<nil>,
    Parry = world:entity() :: jecs.Entity<nil>,
    IFrame = world:entity() :: jecs.Entity<nil>,
    Stunned = world:entity() :: jecs.Entity<nil>,
    SuperArmor = world:entity() :: jecs.Entity<nil>,
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
