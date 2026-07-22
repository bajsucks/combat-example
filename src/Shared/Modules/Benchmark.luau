--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(ReplicatedStorage.Constants.env)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local module = {}

local LastLog: number? = nil
local Results = {}

function module.Bench(fn: (number)->(), dt: number, Name: string)
    if not LastLog then LastLog = os.clock() end
    local a = os.clock()
    fn(dt)
    local result = os.clock() - a
    if Results[Name] then
        Results[Name] += result
    else
        Results[Name] = result
    end
end

local function GetLogTime(): number?
    if not LastLog then return nil end
    return os.clock() - LastLog
end

function module.LogIfOverEnv()
    local LogTime = GetLogTime()
    if not LogTime then return end
    if LogTime >= env.debug_options.bench_time then
        module.Log()
    end
end

local function Percent(a: number, b: number)
    if b == 0 then error("div by 0") end
    return `{math.floor(a/b*100*100)/100}%`
end


local function totime(t): string
    local str: string = jUtil.SecondsToReadableTime(t, 3)
    return str
end

local function format(Name: string, Time: string, Percentage: string): string
    return string.format("\n%-20s %-10s %-15s", Name, Time, Percentage)
end

function module.Log()
    local LogTime = GetLogTime()
    local SystemTime = 0
    local ResultsSorted = {}
    local str: string = "BENCHMARK"
    for Name, Seconds in Results do
        SystemTime += Seconds
        table.insert(ResultsSorted, {Name, Seconds})
    end
    table.sort(ResultsSorted, function(a: {number}, b: {number}) return a[2] > b[2] end)
    if not LogTime then return end
    local unaccounted = LogTime - SystemTime
    str = str..`\nBench time: {totime(LogTime)}\nSystem time: {totime(SystemTime)}\nTime not accounted for: {totime(unaccounted)} ({Percent(unaccounted, LogTime)})\n`
    for _, tbl: {any} in ResultsSorted do
        str = str..format(tbl[1], totime(tbl[2]), Percent(tbl[2], SystemTime))
    end
    print(str)
    table.clear(Results)
    LastLog = nil
end

return module