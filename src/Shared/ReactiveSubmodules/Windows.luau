--[[
    Windows reactive submodule
    To be used with ReactiveTags

    Dependency: jTools https://github.com/bajsucks/jTools has to be placed in ReplicatedStorage.Packages
    ^ If you don't want to install it, you can just download jUtil, Scaler and Janitor separately. jUtil is only used for .HasProperty() function.
]]
--[[
    Usage:

    Tag - Window
    Attribute - WindowUID* - UID of the window. Should only be used at 1 window at a time.
    Attribute - WindowType - Type of the window. Used for .CloseAllType()
    Attribute - DefaultCloseAnim - Default closing animation (I forgot what this is tbh never used it)

    Tag - WindowManager
    Attribute - TargetUID* - Target WindowUID. This will be the window that this manager affects.
    Attribute - ButtonType - [Close/Open/Switch]
    Attribute - CloseOthers - Whether this manager will close all other windows that are not the target.
    Attribute - CloseOthersOfType - Whether this manager will close all windows of a selected type that are not the target.
    Attribute - AnimOpen - Animation to use when opening the target window
    Attribute - AnimOpenSpeed - Length of that animation in seconds
    Attribute - AnimClose - Animation to use when closing the target window
    Attribute - AnimCloseSpeed - Length of that animation in seconds
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local Scaler = require(ReplicatedStorage.Packages.jTools.Scaler)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local module = {}
local WindowObj = {}
WindowObj.__index = WindowObj

local RegisterUID = {} :: { string: WindowObj }
local RegisterType = {} :: { string: { WindowObj } }
export type WindowObj = typeof(module.WindowNew())

local function ChangeScale(UIScale: UIScale, Value: number)
	if not UIScale then
		return
	end
	local sc = Scaler.FromInstance(UIScale, "Scale")
	sc:Effect("Window", Value)
end

local function GetEffector(UIScale: UIScale)
	if not UIScale then
		return
	end
	return Scaler.FromInstance(UIScale, "Scale")
end

function module.FromWindowUID(WindowUID: string): WindowObj
	return RegisterUID[WindowUID]
end
function module.WaitForWindowUID(WindowUID: string): WindowObj
	repeat
		task.wait()
	until RegisterUID[WindowUID]
	return RegisterUID[WindowUID]
end

function module.CloseAllType(Type: string, Anim: string?, IgnoreSelf: boolean?, self: WindowObj?)
	for _, obj: WindowObj in RegisterType[Type] do
		if IgnoreSelf and obj == self then
			continue
		end
		if not obj:GetState() then
			continue
		end
		if Anim == "None" then
			obj:SetState(false)
		else
			obj:SetState(false, Anim or self.DefaultCloseAnim)
		end
	end
end

function WindowObj.CloseOthers(self: WindowObj, Anim: string?)
	for _, obj: WindowObj in RegisterUID do
		if obj == self then
			continue
		end
		if not obj:GetState() then
			continue
		end
		if Anim == "None" then
			obj:SetState(false)
		else
			obj:SetState(false, Anim or self.DefaultCloseAnim)
		end
	end
end

function module.WindowNew(Window: GuiObject | LayerCollector)
	if Window:IsDescendantOf(StarterGui) then
		return
	end
	local self = setmetatable({}, WindowObj)
	assert(
		jUtil.IsA(Window, { "GuiObject", "LayerCollector" }),
		"The only eligable classes for windows are GuiObject or LayerCollector!"
	)

	local UID = Window:GetAttribute("WindowUID") :: string?
	local Type = Window:GetAttribute("WindowType") :: string?
	local DefaultCloseAnim = Window:GetAttribute("DefaultCloseAnim") :: string?

	self.UID = UID
	self.Type = Type
	self.Window = Window
	self.Action = nil
	self.DefaultCloseAnim = DefaultCloseAnim
	self.Janitor = Janitor.new()
	if not Window:IsA("LayerCollector") then
		self.UIScale = Window:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
		self.UIScale.Parent = Window
	end
	if self:GetState() then
		ChangeScale(self.UIScale, 1)
	else
		ChangeScale(self.UIScale, 0)
	end

	RegisterUID[UID] = self
	if Type then
		RegisterType[Type] = RegisterType[Type] or {}
		RegisterType[Type][UID] = self
	end
	local function Clean()
		self:Destroy()
	end
	Window.Destroying:Once(Clean)
	return self
end

function WindowObj.Destroy(self: WindowObj)
	local UID = self.UID
	self.Janitor:Destroy()
	RegisterUID[UID] = nil
	if self.Type then
		RegisterType[self.Type][UID] = nil
	end
end

function WindowObj.GetState(self: WindowObj)
	local state = false
	if jUtil.HasProperty(self.Window, "Visible") then
		state = self.Window.Visible
	elseif jUtil.HasProperty(self.Window, "Enabled") then
		state = self.Window.Enabled
	end
	if self.Action == "Close" then
		return not state
	else
		return state
	end
end

function WindowObj.SetState(self: WindowObj, state: boolean, Anim: string?, Speed: number?, IgnoreScale: boolean?)
	if Anim == "Pop" then
		self:Pop(state, Speed)
	else
		if jUtil.HasProperty(self.Window, "Visible") then
			self.Window.Visible = state
		elseif jUtil.HasProperty(self.Window, "Enabled") then
			self.Window.Enabled = state
		end
		if not IgnoreScale then
			local NewScale = state and 1 or 0
			ChangeScale(self.UIScale, NewScale)
		end
	end
end

function WindowObj.Pop(self: WindowObj, state: boolean, speed: number?)
	self.Janitor:Cleanup()
	self.Action = state and "Open" or "Close"
	if state then
		self:SetState(state, nil, nil, true)
	end
	local function Stop()
		self:SetState(state)
		self.Action = nil
	end
	if not self.UIScale then
		warn("No UIScale present!")
		Stop()
		return
	end
	local tween: Tween
	local Effector = GetEffector(self.UIScale)
	if state then
		tween = Effector:Tween("Window", 1, TweenInfo.new(speed or 0.35, Enum.EasingStyle.Back))
	else
		tween = Effector:Tween("Window", 0, TweenInfo.new(speed or 0.2, Enum.EasingStyle.Linear))
	end
	tween:Play()
	self.Janitor:Add(tween.Completed:Once(Stop))
end

function module.ButtonNew(Button: GuiButton)
	if Button:IsDescendantOf(StarterGui) then
		return
	end
	local TargetUID = Button:GetAttribute("TargetUID") :: string?
	assert(TargetUID, "Failed to create a WindowManager: TargetUID is not specified!")
	local ButtonType = Button:GetAttribute("ButtonType") or "Switch"
	local CloseOthers = Button:GetAttribute("CloseOthers") or false
	local CloseOthersOfType = Button:GetAttribute("CloseOthersOfType") or false
	local AnimOpen = Button:GetAttribute("AnimOpen") :: string?
	local AnimOpenSpeed = Button:GetAttribute("AnimOpenSpeed") :: number?
	local AnimClose = Button:GetAttribute("AnimClose") :: string? -- "None" will FORCE the window to nil. If not "None", CloseOthers and CloseOthersOfType will use DefaultCloseAnim from window.
	local AnimCloseSpeed = Button:GetAttribute("AnimCloseSpeed") :: number?
	local j = Janitor.new()
	local con = Button.Activated:Connect(function()
		local self = module.FromWindowUID(TargetUID)
		if not self then
			return
		end
		if CloseOthers then
			self:CloseOthers(AnimClose)
		elseif CloseOthersOfType then
			module.CloseAllType(CloseOthersOfType, AnimClose, true, self)
		end
		if ButtonType == "Open" then
			if self:GetState() then
				return
			end
			self:SetState(true, AnimOpen, AnimOpenSpeed)
		elseif ButtonType == "Close" then
			if not self:GetState() then
				return
			end
			self:SetState(false, AnimClose, AnimCloseSpeed)
		elseif ButtonType == "Switch" then
			local TargetState = not self:GetState()
			local Anim = TargetState and AnimOpen or AnimClose
			local speed = TargetState and AnimOpenSpeed or AnimCloseSpeed
			self:SetState(TargetState, Anim, speed)
		end
	end)
	j:Add(con)
	Button.Destroying:Connect(function()
		j:Destroy()
	end)
end

module.Tags = {
	Window = module.WindowNew,
	WindowManager = module.ButtonNew,
}

return module
