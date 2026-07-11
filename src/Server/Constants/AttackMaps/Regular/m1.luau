local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)
local function Attack(source:jecs.Entity)
    -- windup, active, endlag
end
local function Interrupt(source:jecs.Entity)
    -- cancel stuff in attack
end
return Attack, Interrupt