local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local LivingFac = require(ServerStorage.Factories.LivingFac)
local conch = require(ReplicatedStorage.Packages.conch)
return {
    "dummy",
    {
        description = "Spawns a normal dummy",
        permissions = { "super-user"},
        arguments = function() end,
        callback = function()
            local context = conch.get_command_context()
            local Player: Player = context.executor.player
            local Pivot = Player.Character:GetPivot()
            local NewPivot = Pivot * CFrame.new(-Vector3.zAxis*3)
            local Dummy: Model = ReplicatedStorage.Assets.Dummy:Clone()
            LivingFac.new(nil, {View = Dummy, MaxHealth = 100})
            Dummy:PivotTo(NewPivot)
        end
    }
}