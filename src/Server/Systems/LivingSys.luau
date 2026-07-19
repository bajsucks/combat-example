--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LivingCom = require(ReplicatedStorage.Components.LivingCom)
local WorldProvider = require(ReplicatedStorage.Modules.WorldProvider)
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
			print("set IsDead")
		end
		table.clear(DeadQueue)
	end
end, -1, "postsim"}
