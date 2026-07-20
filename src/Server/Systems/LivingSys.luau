local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local PlayerCom = require(ReplicatedStorage.Components.PlayerCom)
local link = require(ReplicatedStorage.Components.link)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
local EasyRagdoll = require(ReplicatedStorage.Packages.EasyRagdoll)
local world = WorldProvider.Get("Main")

local DamageQuery = world:query(LivingCom.Health, LivingCom.QDamage):without(LivingCom.IsDead):cached()
local HealQuery = world:query(LivingCom.Health, LivingCom.MaxHealth, LivingCom.QHeal):without(LivingCom.IsDead):cached()

local DeadQueue = {}
return {function()
	for e, Health: number, MaxHealth: number, QHeal: { number } in HealQuery do
		for _, HealVal in QHeal do
			Health = math.min(Health + HealVal, MaxHealth)
		end
		world:set(e, LivingCom.Health, Health)
		table.clear(QHeal)
	end

	for e, Health: number, QDamage: { number } in DamageQuery do
		for _, DamageVal in QDamage do
			Health = math.max(Health - DamageVal, 0)
			if Health == 0 then
				table.insert(DeadQueue, e)
				break
			end
		end
		world:set(e, LivingCom.Health, Health)
		table.clear(QDamage)
	end

	if #DeadQueue > 0 then
		for _, e in DeadQueue do
			world:add(e, LivingCom.IsDead)
			local Char: Model?, Player: Player? = world:get(e, link.View, PlayerCom.Player)
			if Char then
				EasyRagdoll.SetRagdoll(Char, true, true, 100)
				task.delay(1.5, function()
					Char:Destroy()
					if Player then
						Player:LoadCharacterAsync()
					else
						world:delete(e)
					end
				end)
			end
		end
		table.clear(DeadQueue)
	end
end, -1, "postsim"}
