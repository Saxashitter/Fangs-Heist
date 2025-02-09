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
	
		local radius1 = fixmul(fixmul(p.mo.radius, p.mo.scale), char1.attackRange)
		local radius2 = fixmul(fixmul(sp.mo.radius, sp.mo.scale), char2.damageRange)
	
		if distXY > radius1+radius2 then continue end
	
		local height1 = fixmul(p.mo.height, char1.attackZRange)
		local height2 = fixmul(sp.mo.height, char2.damageZRange)
	
		local z = abs((p.mo.z+p.mo.height/2)-(sp.mo.z+sp.mo.height/2))
	
		if z > max(height1, height2) then continue end

		if FangsHeist.partOfTeam(p, sp)
		and not friendlyfire then
			continue
		end

		if char2:isAttacking(sp) then
			FangsHeist.clashPlayers(p, sp)
			continue
		end

		if P_DamageMobj(sp.mo, p.mo, p.mo) then
			char1:onHit(p, sp)
			return sp, FixedHypot(p.mo.momx, p.mo.momy)-FixedHypot(sp.mo.momx, sp.mo.momy)
		end
		if sp.heist.blocking then
			return sp, false
		end
	end
end