-- Attack Constants
rawset(_G, "FH_ATK_FLASH_TICS", 10)
rawset(_G, "FH_ATK_XYMULT", FU*7)
rawset(_G, "FH_ATK_ZMULT", FU*5)
rawset(_G, "FH_ATK_HEALTH", FU*20)
rawset(_G, "FH_ATK_HEALTHDEATH", FU*100)

-- Parry Constants
rawset(_G, "FH_PRY_DUR", 35)
rawset(_G, "FH_PRY_TICS", 16)
rawset(_G, "FH_PRY_PRF", 7)

-- Hurt Constants
rawset(_G, "FH_HRT_DUR", 35)

local FLAGS_RESET = PF_JUMPED|PF_THOKKED|PF_SPINNING|PF_STARTDASH|PF_BOUNCING|PF_GLIDING

local function L_ReturnThrustXYZ(mo, point, speed)
	local horz = R_PointToAngle2(mo.x, mo.y, point.x, point.y)
	local dist = R_PointToDist2(mo.x, mo.y, point.x, point.y)
	local vert = R_PointToAngle2(0, mo.z+mo.height/2, dist, point.z)

	local x = FixedMul(FixedMul(speed, cos(horz)), cos(vert))
	local y = FixedMul(FixedMul(speed, sin(horz)), cos(vert))
	local z = FixedMul(speed, sin(vert))

	return x, y, z
end

-- Returns true if the player can be hit.
local function CanBeHit(p1, p2)
	local team1 = p1.heist:getTeam()
	local team2 = p2.heist:getTeam()

	if team1 == team2
	or p2.heist.exiting then
		return false
	end

	return true
end

local function Knockback(target, source)
	local angle, zangle = ReturnAngles(target, source)
	local spd = 7*source.scale
	local xySpd = FixedMul(spd, sin(zangle))
	local zSpd = -FixedMul(spd, cos(zangle))

	P_InstaThrust(target, angle, xySpd)
	target.momz = zSpd
end

local TIERS = {
	{sfx_dmga1, sfx_dmgb1},
	{sfx_dmga2, sfx_dmgb2},
	{sfx_dmga3, sfx_dmgb3},
	{sfx_dmga4, sfx_dmgb4}
}

local function Damage(p, sp)
	if not P_DamageMobj(sp.mo, p.mo, p.mo) then
		return false
	end

	local speed = FixedSqrt(
		FixedMul(p.mo.momx, p.mo.momx) +
		FixedMul(p.mo.momy, p.mo.momy) +
		FixedMul(p.mo.momz, p.mo.momz)
	)
	speed = max(4*p.mo.scale, $)

	local mx, my, mz = L_ReturnThrustXYZ(p.mo, {
		x = sp.mo.x,
		y = sp.mo.y,
		z = sp.mo.z+sp.mo.height/2
	}, -speed/2)

	p.mo.momx = mx
	p.mo.momy = my
	p.mo.momz = mz
	P_MovePlayer(p)

	p.heist.attack_time = 0
	p.heist.attack_cooldown = 9
	p.powers[pw_flashing] = max($, FH_ATK_FLASH_TICS)

	if p == displayplayer then
		P_StartQuake(28*FU, 12)
	end

	FangsHeist.runHook("PlayerHit", p, p2)
	return true
end

local function CanClash(p, sp)
	local clash = FangsHeist.runHook("PlayerCanClash", p)
	local clash2 = FangsHeist.runHook("PlayerCanClash", sp)

	if clash == nil then clash = true end
	if clash2 == nil then clash2 = true end

	if not (sp.heist.attack_time or atk) then
		return false
	end

	if clash and not clash2 then
		return false
	end

	if not clash and not clash2 then
		return true
	end

	if clash and clash2 then
		return true
	end

	if not clash and clash2 then
		return 1 -- strange ik
	end

	return false
end

local function AttemptAttack(p, sp)
	if not (sp and sp.valid and sp.heist and sp.heist:isAlive() and not sp.heist.exiting) then
		return
	end

	local clash = FangsHeist.runHook("PlayerCanClash", sp)
	if clash == nil then clash = true end

	local radius = FangsHeist.runHook("PlayerAttackRadius", p) or FixedMul(p.mo.radius, FH_ATK_XYMULT)
	local height = FangsHeist.runHook("PlayerAttackHeight", p) or FixedMul(p.mo.height, FH_ATK_ZMULT)
	local x = p.mo.x + p.mo.momx
	local y = p.mo.y + p.mo.momx
	local z = p.mo.z + p.mo.momz

	local distance = R_PointToDist2(x, y, sp.mo.x, sp.mo.y)

	if distance > sp.mo.radius+radius then return end
	if abs((z + p.mo.height/2) - (sp.mo.z + sp.mo.height/2)) > max(height, sp.mo.height)/2 then
		return
	end

	if P_PlayerInPain(sp) then return end
	if p.heist:getTeam() == sp.heist:getTeam() then return end

	if CanClash(p, sp) then
		if CanClash(p, sp) == 1 then return end

		local speed = 18*FU
		local mx, my, mz = L_ReturnThrustXYZ(p.mo, {
			x = sp.mo.x,
			y = sp.mo.y,
			z = sp.mo.z+sp.mo.height/2
		}, speed)

		p.mo.momx = -mx
		p.mo.momy = -my
		p.mo.momz = -mz
		sp.mo.momx = mx
		sp.mo.momy = my
		sp.mo.momz = mz

		P_MovePlayer(p)
		P_MovePlayer(sp)

		sp.heist.attack_time = 0
		p.heist.attack_time = 0

		S_StartSound(p.mo, sfx_fhclsh)
		S_StartSound(sp.mo, sfx_fhclsh)

		if p == displayplayer
		or sp == displayplayer then
			P_StartQuake(7*FU, 12)
		end

		FangsHeist.runHook("PlayerClash", p, sp)
		FangsHeist.runHook("PlayerClash", sp, p)
		return
	end

	Damage(p, sp)
end

local function DoAttack(p)
	if FangsHeist.runHook("PlayerAttack", p) == true then
		return
	end

	if p.mo.heistwhiff
	and p.mo.heistwhiff.valid then
		P_RemoveMobj(p.mo.heistwhiff)
	end

	local shield = P_SpawnMobjFromMobj(p.mo, 0,0,p.mo.height/2, MT_THOK)
	shield.state = S_FH_WHIFF
	shield.frame = $|FF_FULLBRIGHT
	shield.scale = 2*FU
	shield.destscale = shield.scale

	p.heist.instashield = shield

	p.heist.attack_cooldown = TICRATE
	p.heist.attack_time = G+1

	S_StartSound(p.mo, sfx_s3k42)
	FangsHeist.playVoiceline(p, "attack")
end

local function RingSpill(p, dontSpill, p2)
	if not p.rings then
		return false
	end

	local gamemode = FangsHeist.getGamemode()
	local rings_spill = min(5, p.rings)

	if not dontSpill 
	and not p2 then
		P_PlayerRingBurst(p, rings_spill)
	elseif p2 then
		FangsHeist.Particles:new("Ring Steal", p.mo, p2.mo, rings_spill)
	end

	S_StartSound(p.mo, sfx_s3kb9)
	p.rings = $-rings_spill
	p.heist:gainProfitMultiplied(-FH_RINGPROFIT*rings_spill)

	return rings_spill
end

addHook("ShouldDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end
	
	if t.player.heist.exiting then
		return false
	end

	if dt == DMG_WATER then
		return false
	end

	local canDamage = not (t.player.powers[pw_flashing] or t.player.powers[pw_invulnerability])
	local forced

	if i
	and i.valid then
		if i.type == MT_CORK then
			if not canDamage then
				return false
			end
		end
		if i.type == MT_LHRT then
			if not canDamage then
				return false
			end
			
			forced = true
		end
	end

	if s and s.valid and s.player and s.player.heist then
		local team1 = t.player.heist:getTeam()
		local team2 = s.player.heist:getTeam()

		if team1 == team2 then
			return false
		end
	end

	if t.state == S_FH_CLASH then
		return false
	end

	return forced
end, MT_PLAYER)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	local returnval
	local gamemode = FangsHeist.getGamemode()

	FangsHeist.playVoiceline(t.player, "hurt")

	if not (t.player.powers[pw_shield]) then
		local rings = RingSpill(t.player, nil, s and s.valid and s.player)
	
		if rings then
			P_ResetPlayer(t.player)
			P_DoPlayerPain(t.player, s, i)
			returnval = true
		end
	end

	if not (t.player.powers[pw_shield])
	and i
	and i.valid then
		local speedAdd = 40*FixedDiv(t.player.heist.health, 100*FU)
		local speed = FixedSqrt(
			FixedMul(i.momx, i.momx) +
			FixedMul(i.momy, i.momy) +
			FixedMul(i.momz, i.momz)
		)
		speed = max(4*i.scale, $)

		local tier = TIERS[max(1, min(FixedDiv(speed, 9*FU)/FU, #TIERS))]
		local sound = tier[P_RandomRange(1, #tier)]

		S_StartSound(t, sound)

		P_InstaThrust(t, R_PointToAngle2(0,0, i.momx, i.momy), speed + speedAdd)
		t.player.heist.hitlast = s
	end

	if s
	and s.player
	and s.player.heist then
		local team = s.player.heist:getTeam()

		if not (t.health) then
			s.player.heist.deadplayers = $+1
			s.player.heist:gainProfitMultiplied(FH_DEADPLAYERPROFIT)
		else
			s.player.heist.hitplayers = $+1
			s.player.heist:gainProfitMultiplied(FH_HITPLAYERPROFIT)
		end
	end

	if t.health then
		local health = FH_ATK_HEALTH

		if i
		and i.flags & MF_ENEMY then
			health = 6*FU
		end

		if i
		and i.flags & MF_MISSILE then
			health = 2*FU
		end

		if i
		and i.player
		and i.player.heist then
			health = FangsHeist.runHook("PlayerAttackDamage", i.player, t.player) or $ 
		end

		t.player.heist.health = $ + health
		if t.player == consoleplayer then
			FangsHeist.doHealthShake(20)
			P_StartQuake(28*FU, 12)

			if consoleplayer.heist.health >= FH_ATK_HEALTHDEATH then
				FangsHeist.doHealthShiver()
			end
		end
	end

	return returnval
end, MT_PLAYER)

FangsHeist.addPlayerScript("thinkframe", function(p)
	if not p.heist:isAlive() then return end
	if not p.mo.heist_airdodge then return end

	if P_IsObjectOnGround(p.mo)
	or P_PlayerInPain(p)
	or p.powers[pw_flashing] == 0
	or not p.mo.health then
		p.mo.heist_airdodge = nil
	end
end)

FangsHeist.addPlayerScript("prethinkframe", function(p)
	if not p.heist:isAlive() then return end
	if not p.mo.heist_airdodge then return end

	p.cmd.buttons = 0 -- no actions, just things joystick related
end)

FangsHeist.addPlayerScript("thinkframe", function(p)
	if not (p.heist.instashield
	and p.heist.instashield.valid)
	or not p.heist:isAlive() then
		p.heist.instashield = nil
		return
	end

	local shield = p.heist.instashield
	P_MoveOrigin(shield,
		p.mo.x,
		p.mo.y,
		p.mo.z+p.mo.height/2)
end)

addHook("MobjMoveBlocked", function(mo)
	if not FangsHeist.isMode() then return end
	if not mo.health then return end
	if not mo.player.heist then return end
	if not P_PlayerInPain(mo.player) then return end
	if mo.player.heist.health < FH_ATK_HEALTHDEATH then return end
	if not mo.player.heist.hitlast then return end

	local source = mo.player.heist.hitlast

	if not (source and source.valid) then
		source = nil
	end

	P_DamageMobj(mo, source, source, 999, DMG_INSTAKILL)
end, MT_PLAYER)

return function(p)
	if not p.heist:isAlive() then
		return
	end

	if not P_PlayerInPain(p) then
		p.heist.hitlast = nil
	end

	if p.mo.state == S_FH_STUN then
		p.pflags = $|PF_FULLSTASIS
		P_SpawnGhostMobj(p.mo)
	end

	local press = p.cmd.buttons & ~p.lastbuttons

	if not P_PlayerInPain(p)
	and not p.heist.exiting then
		-- Attack
		if press & BT_ATTACK
		and p.heist.attack_time == 0
		and p.heist.attack_cooldown == 0 then
			DoAttack(p)
		end
	end

	if not p.heist.exiting then
		if p.heist.attack_cooldown then
			p.heist.attack_cooldown = $-1
	
			if p.heist.attack_cooldown == 0 then
				local ghost = P_SpawnGhostMobj(p.mo)
				ghost.destscale = 4*FU
	
				S_StartSound(p.mo, sfx_ngskid)
			end
		end
		if p.heist.attack_time then
			p.heist.attack_time = max(0, $-1)
	
			local radius = FixedMul(p.mo.radius, FH_ATK_XYMULT)
			local height = FixedMul(p.mo.height, FH_ATK_ZMULT)
			local x = p.mo.x + p.mo.momx
			local y = p.mo.y + p.mo.momx
			local z = p.mo.z + p.mo.momz - height/2
	
			-- ok luigi you can stop complaining now
			searchBlockmap("objects", function(_, found)
				if not found.valid then return end
				if not (found.flags & MF_ENEMY)
				and not (found.flags & MF_MONITOR) then return end
	
				local distance = R_PointToDist2(x, y, found.x, found.y)
				if distance > radius+found.radius then
					return
				end
	
				if z > found.z+found.height then return end
				if found.z > z+height then return end
	
				P_DamageMobj(found, p.mo, p.mo)
			end, p.mo, x-radius*2, x+radius*2, y-radius*2, y+radius*2)
		end
	
		if FangsHeist.runHook("PlayerScanAttack", p)
		or p.heist.attack_time then
			for sp in players.iterate do
				if AttemptAttack(p, sp) then
					break
				end
			end
		end
	else
		p.heist.attack_cooldown = 0
		p.heist.attack_time = 0
	end
end