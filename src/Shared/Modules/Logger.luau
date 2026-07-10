--[[
    Debug logging based on the environment constant
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local env = require(ReplicatedStorage.Constants.env)

local module = {}

function module.print(...)
	if not env.debug_options.debug then
		return
	end
	if env.debug_options.debug_verbosity == 1 then
		print(..., ">", debug.info(2, "sl"))
		return
	end
	if env.debug_options.debug_verbosity == 2 then
		print(..., debug.traceback(nil, 2))
		return
	end
	print(...)
end

function module.warn(...)
	if not env.debug_options.debug then
		return
	end
	if env.debug_options.debug_verbosity == 1 then
		warn(..., ">", debug.info(2, "sl"))
		return
	end
	if env.debug_options.debug_verbosity == 2 then
		warn(..., debug.traceback(nil, 2))
		return
	end
	warn(...)
end

function module.isDebug(): false | number
	return env.debug_options.debug and env.debug_options.debug_verbosity or false
end

return module
