local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local InputConfig = require(ReplicatedStorage.Constants.InputConfig)
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local rawInput = {
	mouseDelta = Vector2.zero,
	leftThumbstickDelta = Vector2.zero,
	rightThumbstickDelta = Vector2.zero,
}

-- init rawInput
for _, name in InputConfig.Keybindings do
	rawInput[name] = false
end

UserInputService.InputBegan:Connect(function(input, sink)
	if sink then
		return
	end

	local rawName = InputConfig.Keybindings[input.KeyCode]
	if rawName then
		rawInput[rawName] = true
	end
end)

UserInputService.InputChanged:Connect(function(input, sink)
	if sink then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		rawInput.mouseDelta = Vector2.new(input.Delta.X, -input.Delta.Y)
	elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
		rawInput.leftThumbstickDelta = Vector2.new(input.Position.X, input.Position.Y)
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		rawInput.rightThumbstickDelta = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input, sink)
	if sink then
		return
	end

	local rawName = InputConfig.Keybindings[input.KeyCode]
	if rawName then
		rawInput[rawName] = false
	end
end)

-- Phase 2: Derive action state from raw inputs.

local function virtualVector2(up: boolean, down: boolean, left: boolean, right: boolean): Vector2
	local x = 0
	local y = 0
	if up then
		y += 1
	end
	if down then
		y -= 1
	end
	if left then
		x -= 1
	end
	if right then
		x += 1
	end
	return Vector2.new(x, y)
end

local function scaledDeadZone(value: number, lowerThreshold: number): number
	local lowerBound = math.max(math.abs(value) - lowerThreshold, 0)
	local scaledValue = lowerBound / (1 - lowerThreshold)

	return math.min(scaledValue, 1) * math.sign(value)
end

local function radialDeadZone(value: Vector2, threshold: number): Vector2
	local magnitude = value.Magnitude
	if magnitude == 0 then
		return Vector2.zero
	else
		return value.Unit * scaledDeadZone(magnitude, threshold)
	end
end

-- Convert raw inputs into action state. This function will apply modifiers like dead zones or sensitivity multipliers.
local function deriveActionState(deltaTime: number)
	local keyboardMove = virtualVector2(rawInput.w, rawInput.s, rawInput.a, rawInput.d)
	local gamepadMove = radialDeadZone(rawInput.leftThumbstickDelta, InputConfig.DeadZones.GamepadMove)

	local mouseLook = rawInput.mouseDelta * InputConfig.Sensitivities.Mouse
	local gamepadLook = radialDeadZone(rawInput.rightThumbstickDelta, InputConfig.DeadZones.GamepadLook)
		* UserGameSettings.GamepadCameraSensitivity
		* InputConfig.Sensitivities.Gamepad
		* deltaTime

	local state = {
		boolean = {},
		value2d = {
			move = keyboardMove + gamepadMove,
			look = mouseLook + gamepadLook,
		},
	}

	for actionName, rawInputs in InputConfig.Actions.boolean do
		local isActivated = false
		for _, rawName in rawInputs do
			if rawInput[rawName] then
				isActivated = true
				break
			end
		end
		state.boolean[actionName] = isActivated
	end

	return state
end

-- UserGameSettings.GamepadCameraSensitivity is only updated if this is called.
UserGameSettings:SetGamepadCameraSensitivityVisible()

-- 3. The API
local ACTIONS_BOOLEAN = {}
for action in InputConfig.Actions.boolean do
	ACTIONS_BOOLEAN[action] = true
end

local ACTIONS_2D = {}
for action in InputConfig.Actions.value2d do
	ACTIONS_2D[action] = true
end

local DEFAULT_PHASE_STATE = {
	boolean = {},
	justPressedCounts = {} :: { [string]: number },
	justReleasedCounts = {} :: { [string]: number },
	value2d = {},
}
for action in ACTIONS_BOOLEAN :: any do
	DEFAULT_PHASE_STATE.boolean[action] = false
end
for action in ACTIONS_2D :: any do
	DEFAULT_PHASE_STATE.value2d[action] = Vector2.zero
end

local function copyDeep<T>(value: T): T
	if typeof(value) == "table" then
		local clone = table.clone(value) :: any

		for i, v in clone do
			clone[i] = copyDeep(v)
		end

		return clone
	else
		return value
	end
end

local lastInputState = deriveActionState(0)
local currentPhase = DEFAULT_PHASE_STATE
local phases = {}

local Input = {}

function Input.justPressed(action: string): boolean
	return currentPhase.justPressedCounts[action] ~= nil
end

function Input.justReleased(action: string): boolean
	return currentPhase.justReleasedCounts[action] ~= nil
end

function Input.pressed(action: string): boolean
	return currentPhase.boolean[action]
end

function Input.released(action: string): boolean
	return not currentPhase.boolean[action]
end

function Input.value2d(action: string): Vector2
	return currentPhase.value2d[action]
end

function Input.unit2d(action: string): Vector2
	local value = currentPhase.value2d[action]
	if value.Magnitude > 0 then
		return value.Unit
	end

	return value
end

function Input.clamped2d(action: string): Vector2
	local value = currentPhase.value2d[action]
	if value.Magnitude > 1 then
		return value.Unit
	end

	return value
end

function Input.runPhase(name: string, callback: () -> ())
	if not phases[name] then
		phases[name] = copyDeep(DEFAULT_PHASE_STATE)
	end

	currentPhase = phases[name]

	callback()

	table.clear(currentPhase.justPressedCounts)
	table.clear(currentPhase.justReleasedCounts)

	for action in currentPhase.boolean do
		currentPhase.boolean[action] = false
	end

	for action in currentPhase.value2d do
		currentPhase.value2d[action] = Vector2.zero
	end

	currentPhase = DEFAULT_PHASE_STATE
end

function Input.update(deltaTime: number)
	local inputState = deriveActionState(deltaTime)

	local presses = {}
	local releases = {}
	for action, value in inputState.boolean do
		if value and not lastInputState.boolean[action] then
			table.insert(presses, action)
		elseif not value and lastInputState.boolean[action] then
			table.insert(releases, action)
		end
	end

	for _, phase in phases do
		for _, action in presses do
			phase.justPressedCounts[action] = (phase.justPressedCounts[action] or 0) + 1
		end

		for _, action in releases do
			phase.justReleasedCounts[action] = (phase.justReleasedCounts[action] or 0) + 1
		end

		for action, value in inputState.boolean do
			phase.boolean[action] = phase.boolean[action] or value
		end

		for action, value in inputState.value2d do
			phase.value2d[action] += value
		end
	end

	lastInputState = inputState

	-- Reset the mouse delta.
	rawInput.mouseDelta = Vector2.zero
end

return Input
