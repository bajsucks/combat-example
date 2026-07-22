--[[
    Environment constants
]]
return {
	debug_options = {
		debug = true, -- enable/disable debug mode
		debug_verbosity = 0,
		bench_time = 60,
		-- 0: only logs
		-- 1: include the script name and line number
		-- 2: include the entire call stack
	},
	Skyline = 100 -- Troop spawn raycasts will fire from this height straight down
}
