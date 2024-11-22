local module = {}
// General PVP handler.

local STR_CAN_ATTACK = STR_PUNCH|STR_ATTACK|STR_STOMP|STR_GLIDE|STR_MELEE|STR_STOMP

function module.canHitPlayers(p)
	local isAttacking = false

	if p.powers[pw_strong] & STR_CAN_ATTACK then
		isAttacking = true
	end

	if not (p.pflags & PF_NOJUMPDAMAGE)
	and p.pflags & PF_JUMPED then
		isAttacking = true
	end

	if p.pflags & PF_SPINNING then
		isAttacking = true
	end

	return isAttacking
	and 	module.isPlayerAttackable(p)
	or		module.isPlayerForcedToAttack(p)
end

function module.isPlayerAttackable(p)
	return not P_PlayerInPain(p) and not (p.powers[pw_flashing])
end

function module.isPlayerForcedToAttack(p)
	return (p.powers[pw_invulnerability])
end

function module.hitPriority(p, sp)
	local priority = 0

	local speed1 = FixedHypot(p.mo.momx, p.mo.momy)
	local speed2 = FixedHypot(sp.mo.momx, sp.mo.momy)
	// we want to account for the actual speed that the player is going
	// not the players rmomx and rmomy

	local airspeed1 = p.mo.momz
	local airspeed2 = sp.mo.momz

	local diff = abs(airspeed1-airspeed2)

	if p.pflags & PF_SPINNING then
		priority = 1
	end
	if p.pflags & PF_STARTDASH then
		priority = 2
	end
	if p.pflags & PF_JUMPED then
		priority = 3
	end
	if p.powers[pw_strong] & STR_CAN_ATTACK then
		priority = 5
	end

	if diff < 16*FU then
		if speed1 >= speed2 then
			priority = $+1
		end
	else
		if abs(airspeed1) >= abs(airspeed2) then
			priority = $+1
		end
	end

	return priority
end

function module.damagePlayer(p, ap) // ap: attacking player
	if not (ap.pflags & PF_SPINNING)
	or ap.pflags & PF_STARTDASH then
		P_DamageMobj(p.mo, ap.mo, ap.mo)
		return
	end

	local launch_speed = FixedHypot(ap.mo.momx, ap.mo.momy)
	local launch_angle = R_PointToAngle2(0,0,ap.mo.momx, ap.mo.momy)

	P_DamageMobj(p.mo, ap.mo, ap.mo)

	if not (p.mo.health) then return end

	P_InstaThrust(p.mo, launch_angle, launch_speed)
end

function module.isPlayerHittable(p, sp)
	local dist = R_PointToDist2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)
	local heightdist = abs(p.mo.z-sp.mo.z)

	if heightdist <= max(p.mo.height, sp.mo.height)*3/2
	and dist <= (p.mo.radius+sp.mo.radius)*3/2 then
		return true
	end

	return false
end

function module.handlePVP()
	local attackables = {}

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then continue end
		if not module.canHitPlayers(p) then continue end
		if not module.isPlayerAttackable(p) then continue end
		if p.heist and p.heist.exiting then continue end

		for sp in players.iterate do
			if sp == p then continue end
			if not FangsHeist.isPlayerAlive(sp) then continue end
			if not module.isPlayerAttackable(sp) then continue end
			if sp.heist and sp.heist.exiting then continue end

			if not module.isPlayerHittable(p, sp) then continue end

			table.insert(attackables, {p, sp})
		end
	end

	for _,attacks in pairs(attackables) do
		local p = attacks[1]
		local sp = attacks[2]

		if module.isPlayerForcedToAttack(sp)
		and module.isPlayerForcedToAttack(p) then
			continue
		end

		if not module.canHitPlayers(sp) then
			module.damagePlayer(sp, p)
			continue
		end

		local priority1 = module.hitPriority(p, sp)
		local priority2 = module.hitPriority(sp, p)

		if priority1 > priority2
		or module.isPlayerForcedToAttack(sp) then
			module.damagePlayer(sp, p)
			continue
		end

		if priority2 > priority1
		or module.isPlayerForcedToAttack(p) then
			module.damagePlayer(p, sp)
			continue
		end

		local dp = attacks[P_RandomRange(1, #attacks)]
		local ap = (dp == sp) and p or sp

		module.damagePlayer(dp, ap, ap)
	end
end

return module