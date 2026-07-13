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
    local char = player and player.Character
    local camera = workspace.CurrentCamera
    if not (char and camera) then return end

    local e = UserIdIndex:First(player.UserId)
    if not e then return end

    local LookAtPos = world:get(e, CameraCom.LookAt)
    if LookAtPos and char:FindFirstChild("HumanoidRootPart") then
        local rootPos = char:GetPivot().Position
        local targetPos = Vector3.new(LookAtPos.X, rootPos.Y, LookAtPos.Z)
        if (targetPos - rootPos).Magnitude > 0.1 then
            char:PivotTo(CFrame.lookAt(rootPos, targetPos))
        end
    end

    local shakes = world:get(e, CameraCom.CameraShake)
    if shakes and #shakes > 0 then
        shakeTick += dt
        local totalNoise = Vector3.new()
        local activeCount = 0

        for _, shake in shakes do
            local intensity = shake.Intensity
            totalNoise += Vector3.new(
                math.noise(shakeTick * 10, 0, 0) * intensity,
                math.noise(0, shakeTick * 10, 0) * intensity,
                math.noise(0, 0, shakeTick * 10) * intensity
            )

            if not shake.duration or shake.duration - dt > 0 then
                if shake.duration then shake.duration -= dt end
                activeCount += 1
                shakes[activeCount] = shake
            end
        end

        for i = #shakes, activeCount + 1, -1 do
            shakes[i] = nil
        end

        shakeOffset = shakeOffset:Lerp(totalNoise, 1 - math.exp(-15 * dt))
        if activeCount == 0 then world:remove(e, CameraCom.CameraShake) end
    else
        shakeOffset = shakeOffset:Lerp(Vector3.new(), 0.1)
    end

    if world:has(e, CameraCom.UpdateQueued) then
        local cameraCF = world:get(e, CameraCom.StaticCameraCF)
        camera.CameraType = if cameraCF then Enum.CameraType.Scriptable else Enum.CameraType.Custom
        if cameraCF then camera.CFrame = cameraCF end

        local offset = world:get(e, CameraCom.CameraOffset) or Vector2.zero
        camera.CFrame = camera.CFrame * CFrame.new(offset.X / 100, offset.Y / 100, 0) + shakeOffset
        world:remove(e, CameraCom.UpdateQueued)
    end
end, -1, "prerender"}