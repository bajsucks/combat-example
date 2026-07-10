local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Data = require(ReplicatedStorage.Modules.Data.Data)
local SeasonPass = require(ReplicatedStorage.Modules.SeasonPass)
local XP = require(ReplicatedStorage.Modules.XP)
local Collect = require(ReplicatedStorage.Packages.jTools.Collect)
local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local module = {}

function module.new(obj: GuiObject)
	if obj:IsDescendantOf(StarterGui) then
		return
	end
	local BarTrack: string = obj:GetAttribute("BarTrack")
	if not BarTrack then
		error("BarTrack attribute is missing!")
	end
	local Mover = Collect.GetTaggedDescendants(obj, "Mover")[1] -- the actual bar, X size limits 0-1
	if not Mover then
		error("Bar has no mover!")
	end
	local ValueLabel = Collect.GetTaggedDescendants(obj, "Value")[1]
	local j = Janitor.new()
	local function updateDisplay(val1, val2)
		local Ratio = math.clamp(val1 / val2, 0, 1)
		TweenService:Create(Mover, TweenInfo.new(0.25), { Size = UDim2.fromScale(Ratio, Mover.Size.Y.Scale) }):Play()
		if ValueLabel then
			ValueLabel.Text = `{math.ceil(val1)}/{math.ceil(val2)}`
		end
	end
	if BarTrack == "Health" then
		local Player: Player = Players.LocalPlayer
		local Char = Player.Character
		if not Char then
			error("nochar")
		end
		local Hum: Humanoid = Char.Humanoid
		if not Hum then
			error("nohum")
		end

		j:Add(Hum.HealthChanged:Connect(function()
			updateDisplay(Hum.Health, Hum.MaxHealth)
		end))
		j:Add(Hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
			updateDisplay(Hum.Health, Hum.MaxHealth)
		end))
		updateDisplay(Hum.Health, Hum.MaxHealth)

	elseif BarTrack == "WormHealth" then
		print("WormHealth bar init")
	elseif BarTrack == "TrainProgress" then
		updateDisplay(workspace:GetAttribute("TrainProgress"), 100)
		j:Add(
			workspace:GetAttributeChangedSignal("TrainProgress"):Connect(function()
				updateDisplay(workspace:GetAttribute("TrainProgress"), 100)
			end),
			"Disconnect"
		)
	elseif BarTrack == "XP" then
		Data.Updated:Connect(function()
			updateDisplay(XP.XPToLevel(Data.Data.XP), SeasonPass.GetMaxLevel())
		end)
		updateDisplay(XP.XPToLevel(Data.Data.XP), SeasonPass.GetMaxLevel())
	end
	j:LinkToInstance(obj)
end

module.Tags = {
	Bar = module.new,
}

return module
