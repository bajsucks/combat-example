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
    Cooldowns = world:component() :: jecs.Entity<{[string]: number}>

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
