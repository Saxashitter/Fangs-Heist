function FangsHeist.clashPlayers(p, sp)
	local angle = R_PointToAngle2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)

	P_InstaThrust(p.mo, angle, -p.speed)
	P_InstaThrust(sp.mo, angle, p.speed)

	local char1 = FangsHeist.Characters[p.mo.skin]
	local char2 = FangsHeist.Characters[sp.mo.skin]

	char1:onClash(p, sp)
	char2:onClash(sp, p)

	p.mo.state = S_PLAY_FALL
	sp.mo.state = S_PLAY_FALL

	p.powers[pw_flashing] = 10
	sp.powers[pw_flashing] = 10
end

function FangsHeist.gainProfit(p, gain, dontDiv, specialSound)
	local div = 0

	if not dontDiv then
		for i = 0,FangsHeist.getTeamLength(p) do
			div = $+1
		end
	else
		div = 1
	end

	local team = FangsHeist.isInTeam(p)

	if not team then
		print "not in team bozo"
		return
	end

	team.profit = max(0, $+(gain/div))
end

function FangsHeist.damagePlayers(p, friendlyfire, damage)
	if friendlyfire == nil then
		friendlyfire = false
	end
	if damage == nil then
		damage = FH_BLOCKDEPLETION
	end

	for sp in players.iterate do
		if not (sp and sp.mo and sp.mo.health and sp.heist) then
			continue
		end
		if sp == p then continue end

		local distXY = FixedHypot(p.mo.x-sp.mo.x, p.mo.y-sp.mo.y)
	
		local char1 = FangsHeist.Characters[p.mo.skin]
		local char2 = FangsHeist.Characters[sp.mo.skin]
	
		local radius1 = fixmul(p.mo.radius, char1.attackRange)
		local radius2 = fixmul(sp.mo.radius, char2.damageRange)
	
		if distXY > radius1+radius2 then continue end
	
		local height1 = fixmul(p.mo.height, char1.attackZRange)
		local height2 = fixmul(sp.mo.height, char2.damageZRange)
	
		local z = abs((p.mo.z+p.mo.height/2)-(sp.mo.z+sp.mo.height/2))
	
		if z > max(height1, height2) then continue end

		if FangsHeist.isPartOfTeam(p, sp)
		and not friendlyfire then
			continue
		end

		if char2:isAttacking(sp) then
			FangsHeist.clashPlayers(p, sp)

			S_StartSound(p.mo, sfx_s3k7b)
			S_StartSound(sp.mo, sfx_s3k7b)

			return sp, false
		end

		local speed = FixedHypot(p.mo.momx, p.mo.momy)-FixedHypot(sp.mo.momx, sp.mo.momy)

		if P_DamageMobj(sp.mo, p.mo, p.mo) then
			char1:onHit(p, sp)

			// Retake Knockback
			local mult = FU
			local zmult = FU

			mult = $ + (FU * FangsHeist.Save.retakes)
			zmult = $ + (FU * FangsHeist.Save.retakes)

			mult = $ - FixedMul(tofixed("0.28"), FangsHeist.Save.retakes*FU)
			zmult = $ - FixedMul(tofixed("0.8"), FangsHeist.Save.retakes*FU)

			sp.mo.momx = FixedMul($, mult)
			sp.mo.momy = FixedMul($, mult)
			sp.mo.momz = FixedMul($, zmult)

			HeistHook.runHook("PlayerDamage", p, sp)

			return sp, speed
		end

		if char2:isBlocking(sp) then
			return sp, false
		end
	end
end

function FangsHeist.depleteBlock(p, damage)
	if damage == nil then
		damage = FH_BLOCKDEPLETION
	end

	local result = HeistHook.runHook("DepleteBlock", p, damage)

	if result ~= nil then
		return result
	end

	p.heist.block_time = min(FH_BLOCKTIME, $+damage)

	if p.heist.block_time == FH_BLOCKTIME then
		p.heist.block_cooldown = 5*TICRATE
		p.heist.blocking = false
		S_StartSound(p.mo, sfx_fhbbre)

		return true
	end

	S_StartSound(p.mo, sfx_s3k7b)
	return false
end