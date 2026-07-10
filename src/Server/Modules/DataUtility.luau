local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Logger = require(ReplicatedStorage.Modules.Logger)
local dsInfo = require(ServerStorage.Constants.DatastoreInfo)
local DefaultData = require(ServerStorage.Constants.DefaultData)
local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)

local prefix = RunService:IsStudio() and dsInfo.prefix_studio or dsInfo.prefix_live

local ds = ProfileStore.New(prefix .. "PlayerData", DefaultData)

local module = {}
module.Profiles = {}
module.wiping = {}

local function key(Player: Player)
	return "PlayerDataStore_" .. Player.UserId
end

--[[
    The actual data wipe, does not handle edge cases
]]
local function Wipe(Player: Player): boolean
	Logger.warn("Wiping the")
	local success = ds:RemoveAsync(key(Player))
	if not success then
		Player:Kick("Failed to reset your data!")
	end
	return success
end
--[[
    Wipe a player's data, close their session and kick them out
]]
function module.Wipe(Player: Player)
	local Profile = module.Profiles[Player]
	if Profile then
		module.wiping[Player.UserId] = true
		Profile:EndSession()
	end
end
--[[
	@return Profile
]]
function module.Begin(Player: Player)
	Logger.print("Begin loading profile")
	local wipeSuccess = true -- true because we only do stuff if it failed
	if RunService:IsStudio() then
		if not dsInfo.save_data_studio then
			wipeSuccess = Wipe(Player)
		end
	elseif not dsInfo.save_data_live then
		wipeSuccess = Wipe(Player)
	end
	if not wipeSuccess then
		Logger.warn("No wipe success!")
		return
	end -- FAAHH
	local Success, Profile = pcall(function()
		return ds:StartSessionAsync(key(Player))
	end)
	if not Success or not Profile then
		Logger.warn("Failed to load profile for", Player.DisplayName)
		AnalyticsService:LogCustomEvent(Player, "ProfileFail")
		Player:Kick("Unable to load your save data. Most likely it is an issue with Roblox servers.")
		if Profile then
			error(Profile)
		end
		return
	end
	Profile:AddUserId(Player.UserId)
	Profile:Reconcile()

	Profile.OnSessionEnd:Connect(function()
		module.Profiles[Player] = nil
		if module.wiping[Player.UserId] then
			Logger.warn("Wiping data for", Player.DisplayName)
			AnalyticsService:LogCustomEvent(Player, "DataWipe")
			module.wiping[Player.UserId] = nil
			if Player:IsDescendantOf(Players) then
				Player:Kick("Your data was wiped. Please rejoin.")
				repeat
					task.wait(0.1)
				until not Profile:IsActive()
				Wipe(Player)
			end
		else
			Logger.warn("Reloading profile for", Player.DisplayName)
			--AnalyticsService:LogCustomEvent(Player, "ProfileReload")
			Player:Kick("Your save profile could've been loaded on another server. Please rejoin.")
		end
	end)
	if Player:IsDescendantOf(Players) then
		module.Profiles[Player] = Profile
	else
		Profile:EndSession()
	end
	return Profile
end

function module.End(Player: Player, FinalData: typeof(DefaultData))
	local Profile = module.Profiles[Player]
	Profile.Data = FinalData

	if Profile then
		Profile:EndSession()
	end
end

return module
