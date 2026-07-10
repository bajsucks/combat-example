--[[
    TouchyUI reactive rubmodule
    To be used with ReactiveTags

    Dependency: jTools https://github.com/bajsucks/jTools has to be placed in ReplicatedStorage.Packages
    ^ If you don't want to install it, you can just download Scaler separately.
]]
--[[
    Usage:

    Tag - Hover
    Attribute - HoverMult - Scale to icrease by during hover :default 0.95
    Attribute - HoverEnterEasingStyle - [Enum.EasingStyle] :default Exponential
    Attribute - HoverExitEasingStyle - [Enum.EasingStyle] :default Exponential
    Attribute - HoverEnterEasingDirection - [Enum.EasingDirection] :default Out
    Attribute - HoverExitEasingDirection - [Enum.EasingDirection] :default Out
    Attribute - HoverExitTime - [number] :default 0.25
    Attribute - HoverEnterTime - [number] :default 0.25

    Tag - Press
    Attribute - PressMult - Scale to increase by during press :default 0.85
    Attribute - PressBeginEasingStyle - [Enum.EasingStyle] :default Exponential
    Attribute - PressEndEasingStyle - [Enum.EasingStyle] :default Exponential
    Attribute - PressBeginEasingDirection - [Enum.EasingDirection] :default Out
    Attribute - PressEndEasingDirection - [Enum.EasingDirection] :default Out
    Attribute - PressBeginTime - [number] :default 0.15
    Attribute - PressEndTime - [number] :default 0.25
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local StarterGui = game:GetService("StarterGui")

local Scaler = require(ReplicatedStorage.Packages.jTools.Scaler)
local jSound = require(ReplicatedStorage.Packages.jTools.jSound)
local module = {}

function module.Hover(obj: GuiObject)
	if obj:IsDescendantOf(StarterGui) then
		return
	end
	local UIScale = obj:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
	UIScale.Parent = obj

	obj.MouseEnter:Connect(function()
		local Style = obj:GetAttribute("HoverExitEasingStyle") or "Exponential"
		local Direction = obj:GetAttribute("HoverExitEasingDirection") or "Out"
		local Mult = obj:GetAttribute("HoverMult") or 0.95
		local Time = obj:GetAttribute("HoverEnterTime") or 0.25
		local self = Scaler.FromInstance(UIScale, "Scale")
		self:Tween("Hover", Mult, TweenInfo.new(Time, Enum.EasingStyle[Style], Enum.EasingDirection[Direction])):Play()
		jSound.GlobalSFX(ReplicatedStorage.Assets.Sounds.UI.hover, SoundService.SG.sfx)
	end)

	obj.MouseLeave:Connect(function()
		local Style = obj:GetAttribute("HoverExitEasingStyle") or "Exponential"
		local Direction = obj:GetAttribute("HoverExitEasingDirection") or "Out"
		local Time = obj:GetAttribute("HoverExitTime") or 0.25
		local self = Scaler.FromInstance(UIScale, "Scale")
		self:Tween("Hover", 1, TweenInfo.new(Time, Enum.EasingStyle[Style], Enum.EasingDirection[Direction])):Play()
	end)
end

function module.Press(obj: GuiObject)
	if obj:IsDescendantOf(StarterGui) then
		return
	end
	local UIScale = obj:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
	UIScale.Parent = obj

	local function Press()
		local Style = obj:GetAttribute("PressBeginEasingStyle") or "Exponential"
		local Direction = obj:GetAttribute("PressBeginEasingDirection") or "Out"
		local Mult = obj:GetAttribute("PressMult") or 0.85
		local Time = obj:GetAttribute("PressBeginTime") or 0.15
		local self = Scaler.FromInstance(UIScale, "Scale")
		self:Tween("Press", Mult, TweenInfo.new(Time, Enum.EasingStyle[Style], Enum.EasingDirection[Direction])):Play()
		jSound.GlobalSFX(ReplicatedStorage.Assets.Sounds.UI.click, SoundService.SG.sfx)
	end

	local function Depress()
		local Style = obj:GetAttribute("PressEndEasingStyle") or "Exponential"
		local Direction = obj:GetAttribute("PressEndEasingDirection") or "Out"
		local Time = obj:GetAttribute("PressEndTime") or 0.25
		local self = Scaler.FromInstance(UIScale, "Scale")
		self:Tween("Press", 1, TweenInfo.new(Time, Enum.EasingStyle[Style], Enum.EasingDirection[Direction])):Play()
	end
	if obj:IsA("GuiButton") then
		obj.MouseButton1Down:Connect(Press)
		obj.MouseButton1Up:Connect(Depress)
	else
		obj.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Press()
			end
		end)
		obj.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Depress()
			end
		end)
	end
	obj.MouseLeave:Connect(Depress)
end

module.Tags = {
	Hover = module.Hover,
	Press = module.Press,
}

return module
