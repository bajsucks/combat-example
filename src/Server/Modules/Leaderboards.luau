--[[
	Made by baj
	Leaderboard functionality
]]

local Leaderboards = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local jMath = require(ReplicatedStorage.Packages.jTools.jMath)
local jUtil = require(ReplicatedStorage.Packages.jTools.jUtil)
local Profiles = require(ServerScriptService.Data.Profiles)

local waittime = 0
local function getwaittime()
	waittime += 3
	return waittime
end

--[[
	@param DsName Datastore name. Has to be unique
	@param EntryPath Path to the data entry. Example path: Inventory/Weapons/Weapon1
	@param UpdateTime Datastore will update every UpdateTime seconds
	@param Template Template that will be cloned for each entry
	@param Scroll ScrollingFrame that the template will be parented to
	@param UsernamePath Path relative to template to the textlabel that will hold the username of the player
	@param RankPath Same as UsernamePath but for rank
	@param ValuePath Same as UsernamePath but for value
	@param MugshotPath Same as UsernamePath but for player's mugshot
	@param isAscending Whether the leaderboard sorted by ascending
	@param PageSize How many entries will be displayed; 100 = top 100 players
	@param Timer TextLabel that will be used to display time before the leaderboard updates
	@param UseCompression Whether the leaderboard should compress it's values. This will reduce accuracy of the values, but allows you to have way larger values without errors
	@param DisplayFunc Function that will convert raw value into text that will be displayed as a value
]]
function Leaderboards.new(
	DsName: string,
	EntryPath: string,
	UpdateTime: number,
	Template: GuiObject,
	Scroll: ScrollingFrame,
	UsernamePath: string,
	RankPath: string,
	ValuePath: string,
	MugshotPath: string,
	isAscending: boolean?,
	PageSize: number?,
	Timer: TextLabel?,
	UseCompression: boolean?,
	DisplayFunc: any?
)

	task.wait(getwaittime()) -- so leaderboards don't get queued up
	if UpdateTime < 5 then
		UpdateTime = 5
	end
	local DynamicCache, PermanentCache = {}, {}

	local store = DataStoreService:GetOrderedDataStore(DsName)

	local function Compress(Value)
		if UseCompression then
			return jMath.Compress(Value)
		else
			return Value
		end
	end
	local function Decompress(Value)
		if UseCompression then
			return jMath.Decompress(Value)
		else
			return Value
		end
	end

	local function SetNewVal(plr: Player, Value: number)
		task.spawn(function()
			store:SetAsync(tostring(plr.UserId), Compress(Value))
		end)
	end

	local function GetTop()
		local success, pages = pcall(function()
			return store:GetSortedAsync(isAscending, PageSize)
		end)
		assert(success, `{DsName} error: {pages}`)
		local top = pages:GetCurrentPage()
		return top
	end

	local function SetPermanentCache(userid: number)
		local n = Players:GetNameFromUserIdAsync(userid)
		local mugshot =
			Players:GetUserThumbnailAsync(userid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		PermanentCache[tostring(userid)] = { n, mugshot }
	end

	local function SetDynamicCache(Player: Player)
		local p = Profiles.Get(Player)
		local value = jUtil.ResolvePath(p.Data, EntryPath)
		if not value then
			return
		end
		if not DynamicCache[p] or DynamicCache[p] ~= value then
			DynamicCache[p] = value
			SetNewVal(Player, value)
		end
	end

	local function ResetDynamicCache()
		for _, v in Players:GetPlayers() do
			task.spawn(SetDynamicCache, v)
		end
	end

	local totaldt = 0
	local didHalf = false
	local IsUpdating = false
	local function Update()
		-- Updating..
		IsUpdating = true
		local top = GetTop()
		if not top then
			IsUpdating = false
			return
		end
		jUtil.ClearGUI(Scroll)
		for index, data in top do -- todo after this point
			local userid = data.key
			local value = Decompress(data.value)
			if not PermanentCache[userid] then
				SetPermanentCache(tonumber(userid))
			end
			if not PermanentCache[userid] then
				continue
			end -- failsave
			local t = Template:Clone()
			t.Parent = Scroll
			local UsernameObj = jUtil.ResolvePath(t, UsernamePath)
			local RankObj = jUtil.ResolvePath(t, RankPath)
			local ValueObj = jUtil.ResolvePath(t, ValuePath)
			local MugshotObj = jUtil.ResolvePath(t, MugshotPath)
			UsernameObj.Text = PermanentCache[userid][1]
			ValueObj.Text = DisplayFunc and DisplayFunc(value) or jUtil.Abr(value)
			MugshotObj.Image = PermanentCache[userid][2]
			RankObj.Text = "#" .. index
			t.LayoutOrder = index
		end
		didHalf = false
		IsUpdating = false
	end

	ResetDynamicCache()
	Update()
	RunService.Heartbeat:Connect(function(dt)
		totaldt += dt
		if IsUpdating and Timer then
			Timer.Text = "Updating.."
			totaldt = 0
			return
		elseif Timer then
			Timer.Text = "Update in " .. jUtil.SecondsToReadableTime(UpdateTime - totaldt)
		end
		if totaldt >= UpdateTime - 3 and not didHalf then
			didHalf = true
			ResetDynamicCache() -- Reset dynamic cache 3 seconds before the leaderboard updates
		end

		if totaldt >= UpdateTime then
			totaldt = 0
			didHalf = false
			Update()
		end
	end)
end

return Leaderboards
