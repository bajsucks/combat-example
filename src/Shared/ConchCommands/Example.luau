local ReplicatedStorage = game:GetService("ReplicatedStorage")
local conch = require(ReplicatedStorage.Packages.conch)
local args = conch.args
return {
    "ping",
    {
        description = "Ping check",
        permissions = { "super-user"},
        arguments = function() return args.player() end,
        callback = function(Player:Player)
            -- anything in this will run as server
            local context = conch.get_command_context()
            local LocalPlayer: Player = context.executor.player
            conch.log("normal", "Pong!")
            conch.log("normal", `Selected player's ping: {Player:GetNetworkPing()}`)
            conch.log("normal", `Your ping: {LocalPlayer:GetNetworkPing()}`)
        end
    }
}