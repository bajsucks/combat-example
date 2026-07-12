local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local CameraCom = require(ReplicatedStorage.Components.CameraCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)

local Indexer = require(ReplicatedStorage.Modules.Indexer)
local UserIdIndex = Indexer.new(PlayerCom.UserId)

local world = WorldProvider.Get("Main")

local shakeOffset = Vector3.new()
local shakeTick = 0

return {function(dt: number)
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local e = UserIdIndex:First(player.UserId)
	if not e then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local LookAtPos = world:get(e, CameraCom.LookAt)
	if LookAtPos then
		local char = player.Character
		local rootPart = char and char:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local RootPos = char:GetPivot().Position
			local TargetPos = Vector3.new(LookAtPos.X, RootPos.Y, LookAtPos.Z)
			if (TargetPos - RootPos).Magnitude > 0.1 then
				char:PivotTo(CFrame.lookAt(RootPos, TargetPos))
			end
		end
	end

	local shakes = world:get(e, CameraCom.CameraShake)
	if shakes and #shakes > 0 then
		shakeTick += dt
		local totalNoise = Vector3.new()
		local nextShakes = {}

		for _, shake in shakes do
			local intensity = shake.Intensity
			local noiseX = math.noise(shakeTick * 10, 0, 0) * intensity
			local noiseY = math.noise(0, shakeTick * 10, 0) * intensity
			local noiseZ = math.noise(0, 0, shakeTick * 10) * intensity
			totalNoise += Vector3.new(noiseX, noiseY, noiseZ)

			if shake.duration then
				local remaining = shake.duration - dt
				if remaining > 0 then
					table.insert(nextShakes, { Intensity = shake.Intensity, duration = remaining })
				end
			else
				table.insert(nextShakes, shake)
			end
		end

		shakeOffset = shakeOffset:Lerp(totalNoise, 1 - math.exp(-15 * dt))

		if #nextShakes == 0 then
			world:remove(e, CameraCom.CameraShake)
		else
			world:set(e, CameraCom.CameraShake, nextShakes)
		end
	else
		shakeOffset = shakeOffset:Lerp(Vector3.new(), 0.1)
	end
	if world:has(e, CameraCom.UpdateQueued) then
		local CameraCF = world:get(e, CameraCom.StaticCameraCF)
		if CameraCF then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CameraCF
		else
			camera.CameraType = Enum.CameraType.Custom
		end
		local offset = world:get(e, CameraCom.CameraOffset) or Vector2.zero
		camera.CFrame *= CFrame.new(Vector3.new(offset.X / 100, offset.Y / 100, 0))
		camera.CFrame += shakeOffset
		world:remove(e, CameraCom.UpdateQueued)
	end
end, -1, "prerender"}