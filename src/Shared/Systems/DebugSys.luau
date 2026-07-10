local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local CameraCom = require(ReplicatedStorage.Components.CameraCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local Input = require(ReplicatedStorage.Modules.Input)
local Indexer = require(ReplicatedStorage.Modules.Indexer)
local Logger = require(ReplicatedStorage.Modules.Logger)

local UserIdIndex = Indexer.new(PlayerCom.UserId)

local world = WorldProvider.Get("Main")

return function()
	local player = Players.LocalPlayer
	local e = UserIdIndex:First(player.UserId)
	if not e then
		Logger.warn("Local player entity was not found")
		return
	end

	local mouse = player:GetMouse()
	local camera = workspace.CurrentCamera
	world:set(e, CameraCom.LookAt, mouse.Hit.Position)

	if camera then
		local screenCenter = camera.ViewportSize / 2
		local mousePos = Vector2.new(mouse.X, mouse.Y)
		local offset = (mousePos - screenCenter) * 0.1
		world:set(e, CameraCom.CameraOffset, offset)
		world:add(e, CameraCom.UpdateQueued)
	end

	if Input.justPressed("StaticCamera") then
		if camera then
			world:set(e, CameraCom.StaticCameraCF, camera.CFrame)
			world:add(e, CameraCom.UpdateQueued)
		end
	elseif Input.justReleased("StaticCamera") then
		world:remove(e, CameraCom.StaticCameraCF)
		world:add(e, CameraCom.UpdateQueued)
	end
end
