local Logger = require(script.Parent.Logger)
local module = {}

function module.Params(View, offset, size)
    return {
        SpatialOperation = "InBox",
        SizeOrPart = size,
        Blacklist = {View},
        Debug = Logger.isDebug(),
        LookingFor = "Humanoid",
        InitialPosition = View:GetPivot() + offset
    }
end
return module