local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local module = {}

function module.AddCommas(val: number)
	val = tostring(val)
	while true do
		local count
		val, count = string.gsub(val, "^(-?%d+)(%d%d%d)", "%1,%2")
		if count == 0 then
			break
		end
	end

	return val
end

function module.HumanTime(val: number)
	return jUtil.SecondsToReadableTime(val)
end

function module.Robux(val: number)
	return `{val}{utf8.char(0xE002)}`
end

function module.Cash(val: number)
	return `${jUtil.Abr(val)}`
end

return module
