local Config = {}

Config.Keybindings = {
	[Enum.UserInputType.MouseButton1] = "m1",
	-- [Enum.UserInputType.MouseButton2] = "m2",
	-- [Enum.KeyCode.R] = "r",
	-- [Enum.KeyCode.H] = "h",
}

Config.Actions = {
	boolean = {
		StaticCamera = { "h" },
	},
	value2d = {
		move = true,
		look = true,
	},
}

Config.Sensitivities = {
	Mouse = Vector2.new(1, 0.77) * math.rad(0.5),
	Gamepad = Vector2.new(1, 0.77) * math.rad(4) * 60,
}

Config.DeadZones = {
	GamepadMove = 0.2,
	GamepadLook = 0.2,
}

Config.ActionIds = {
	Begin = 1,
	End = 2,
	DoubleTap = 3,
}

return Config
