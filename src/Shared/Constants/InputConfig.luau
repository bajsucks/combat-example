local Config = {}

Config.Keybindings = {
	[Enum.KeyCode.W] = "w",
	[Enum.KeyCode.A] = "a",
	[Enum.KeyCode.S] = "s",
	[Enum.KeyCode.D] = "d",
	[Enum.KeyCode.H] = "h",
	[Enum.KeyCode.Space] = "space",
	[Enum.KeyCode.ButtonA] = "buttonA",
}
Config.NetworkedBinds = {
	-- [Enum.KeyCode.Q] = "q",
	[Enum.KeyCode.R] = "r",
	-- [Enum.KeyCode.T] = "t",
	-- [Enum.KeyCode.Z] = "z",
	-- [Enum.KeyCode.X] = "x",
	-- [Enum.KeyCode.C] = "c",
	-- [Enum.KeyCode.V] = "v",
}

Config.Actions = {
	boolean = {
		jump = { "space", "buttonA" },
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
