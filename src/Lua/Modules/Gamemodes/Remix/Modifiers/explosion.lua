local modifier = {name = "Explosion"}

local function ReturnExplosionTime()
	return P_RandomRange(10*TICRATE, 25*TICRATE)
end

local function SignExplosion()
	local signs = FangsHeist.Carriables.FindCarriables("Sign")

	for k, v in ipairs(signs) do
		local point = v.mobj

		local bombThatDiesOnSpawn = P_SpawnMobjFromMobj(point, 0,0,0, MT_FBOMB)

		if not bombThatDiesOnSpawn.valid then
			continue
		end

		if v.target and v.target.valid then
			P_DamageMobj(v.target, bombThatDiesOnSpawn, bombThatDiesOnSpawn)
		end
		P_KillMobj(bombThatDiesOnSpawn)
	end

	FangsHeist.Net.explosion_time = ReturnExplosionTime()
end

function modifier:init()
	print("ITZ BOMBS")
	FangsHeist.Net.explosion_time = ReturnExplosionTime()
end

function modifier:tick()
	FangsHeist.Net.explosion_time = $-1
	print(FangsHeist.Net.explosion_time)

	if not FangsHeist.Net.explosion_time then
		SignExplosion()
	end
end

return modifier