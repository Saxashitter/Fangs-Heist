local module = {}
// General PVP handler.

local STR_CAN_ATTACK = STR_PUNCH|STR_ATTACK|STR_STOMP|STR_GLIDE|STR_MELEE|STR_STOMP

function module.canHitPlayers(p)
	local isAttacking = false

	if p.powers[pw_strong] & STR_CAN_ATTACK then
		isAttacking = true
	end

	if p.pflags & PF_JUMPED then
		if not (p.pflags & PF_NOJUMPDAMAGE) then
			isAttacking = true
		end
	end

	if p.pflags & PF_SPINNING then
		isAttacking = true
	end

	return isAttacking
	and module.isPlayerAttackable(p)
	or module.isPlayerForcedToAttack(p)
end

function module.isPlayerAttackable(p)
	return (not P_PlayerInPain(p)
	or (FangsHeist.isPlayerUnconscious(p)) and not FangsHeist.isPlayerPickedUp(p))
	and not (p.powers[pw_flashing])
end

function module.isPlayerForcedToAttack(p)
	return (p.powers[pw_invulnerability])
end

local function get_damage_data(p, sp)
	local jumpDamage = false
	local spinDamage = false
	local spindashDamage = false
	local meleeDamage = false


	if p.pflags & PF_SPINNING then
		spinDamage = true
	end

	if p.pflags & PF_JUMPED then
		spinDamage = false
		jumpDamage = true
	end

	if p.pflags & PF_STARTDASH then
		jumpDamage = false
		spinDamage = false
		spindashDamage = true
	end

	if p.powers[pw_strong] & STR_CAN_ATTACK then
		jumpDamage = false
		spinDamage = false
		spindashDamage = false
		meleeDamage = true
	end

	return jumpDamage, spinDamage, spindashDamage, meleeDamage
end

function module.hitPriority(p, sp)
	/*
	CURRENT SYSTEM:
		Spindash > Roll
		Roll > Jump
		Jump > Spindash & Melee
		Melee > Spindash & Roll
	*/

	local jump1, spin1, spindash1, melee1 = get_damage_data(p, sp)
	local jump2, spin2, spindash2, melee2 = get_damage_data(sp, p)

	if spindash1
	and spin2 then
		return 1
	end

	if spin1
	and jump2 then
		return 2
	end

	if jump1
	and (spindash2 or melee2) then 
		return 3
	end

	if melee1
	and (spin2 or spindash2) then
		return 4
	end

	return 0
end

function module.damagePlayer(p, ap) // ap: attacking player
	local launch_speed = max(8*FU, FixedHypot(ap.mo.momx, ap.mo.momy))
	local launch_angle = R_PointToAngle2(0,0,ap.mo.momx, ap.mo.momy)

	P_DamageMobj(p.mo, ap.mo, ap.mo)

	if not (p.mo.health) then return end

	P_InstaThrust(p.mo, launch_angle, launch_speed)
end

function module.isPlayerHittable(p, sp)
	local dist = R_PointToDist2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)
	local heightdist = abs(p.mo.z-sp.mo.z)

	if heightdist <= max(p.mo.height, sp.mo.height)
	and dist <= (p.mo.radius+sp.mo.radius) then
		return true
	end

	return false
end

local function launch_players(p, sp, launch1, launch2)
	if launch1 == nil then
		launch1 = true
	end
	if launch2 == nil then
		launch2 = true
	end
	local angle = R_PointToAngle2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)
	local diff = FixedDiv(p.mo.z-sp.mo.z, max(p.mo.height, sp.mo.height))

	local speed1 = max(12*FU, FixedHypot(p.mo.momx, p.mo.momy))
	local speed2 = max(12*FU, FixedHypot(sp.mo.momx, sp.mo.momy))

	if launch1 then
		P_InstaThrust(p.mo, angle+ANGLE_180, FixedMul(speed2, diff))
		p.mo.momz = 12*diff
	end

	if launch2 then
		P_InstaThrust(sp.mo, angle, FixedMul(speed1, diff))
		sp.mo.momz = -12*diff
	end
end

function module.handlePVP()
	local attackables = {}
	local addedIntoAttacks = {}

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then continue end
		if not module.canHitPlayers(p) then continue end
		if not module.isPlayerAttackable(p) then continue end
		if p.heist and p.heist.exiting then continue end
		if addedIntoAttacks[p] then continue end

		addedIntoAttacks[p] = true

		for sp in players.iterate do
			if sp == p then continue end
			if not FangsHeist.isPlayerAlive(sp) then continue end
			if not module.isPlayerAttackable(sp) then continue end
			if sp.heist and sp.heist.exiting then continue end
			if not module.isPlayerHittable(p, sp) then continue end
			if addedIntoAttacks[sp] then continue end

			addedIntoAttacks[sp] = true

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

		if not module.canHitPlayers(sp)
		or FangsHeist.isPlayerUnconscious(sp) then
			if FangsHeist.isPlayerUnconscious(sp) then
				launch_players(p, sp, true, true)
			end
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

		S_StartSound(p.mo, sfx_s1c3)
		S_StartSound(sp.mo, sfx_s1c3)

		local x = p.mo.x-(p.mo.x-sp.mo.x)
		local y = p.mo.y-(p.mo.y-sp.mo.y)
		local z = p.mo.z-(p.mo.z-sp.mo.z)

		local thok = P_SpawnMobj(x,y,z, MT_THOK)
		thok.color = SKINCOLOR_RED

		launch_players(p, sp)

		p.powers[pw_flashing] = TICRATE
		sp.powers[pw_flashing] = TICRATE
	end
end

return module