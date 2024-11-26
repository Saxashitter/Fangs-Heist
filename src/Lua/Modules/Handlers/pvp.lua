local module = {}
// General PVP handler.
// PVP REWRITE #2

local STR_CAN_ATTACK = STR_PUNCH|STR_ATTACK|STR_STOMP|STR_GLIDE|STR_MELEE|STR_STOMP

function module.canPlayerBeHit(p)
	local invincible = p.powers[pw_flashing] or p.powers[pw_invulnerability]

	if not FangsHeist.isPlayerUnconscious(p) then
		return not P_PlayerInPain(p)
		and not (invincible)
	end

	return P_IsObjectOnGround(p.mo) and not (invincible)
end

function module.canPlayerHitOthers(p)
	local isAttacking = 0

	if not FangsHeist.isPlayerUnconscious(p) then
		if p.powers[pw_strong] & STR_CAN_ATTACK then
			isAttacking = 1
		end

		if p.pflags & PF_JUMPED then
			if not (p.pflags & PF_NOJUMPDAMAGE) then
				isAttacking = 1
			end
		end

		if p.pflags & PF_SPINNING then
			isAttacking = 1
		end

		if p.powers[pw_invulnerability] then
			isAttacking = 2
		end

		return isAttacking
	end

	if not FangsHeist.isPlayerPickedUp(p)
	and not P_IsObjectOnGround(p.mo)then
		isAttacking = 2
	end

	return isAttacking
end

local function get_damage_data(p, sp)
	local jumpDamage = false
	local spinDamage = false
	local spindashDamage = false
	local meleeDamage = false
	local unconscious = false

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

	if FangsHeist.isPlayerUnconscious(p) then
		jumpDamage = false
		spinDamage = false
		spindashDamage = false
		meleeDamage = false
		unconscious = true
	end

	return jumpDamage, spinDamage, spindashDamage, meleeDamage, unconscious
end

function module.getPriority(p, sp)
	/*
	CURRENT SYSTEM:
		Spindash > Roll
		Roll > Jump
		Jump > Spindash & Melee
		Melee > Spindash & Roll
	*/

	local jump1, spin1, spindash1, melee1, unconscious1 = get_damage_data(p, sp)
	local jump2, spin2, spindash2, melee2, unconscious2 = get_damage_data(sp, p)

	if unconscious1 then
		return 5
	end

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

function module.bouncePlayers(p, sp)
	local angle = R_PointToAngle2(sp.mo.x, sp.mo.y, p.mo.x, p.mo.y)
	local diff = FixedDiv(sp.mo.z-p.mo.z, max(p.mo.height, sp.mo.height))

	local speed1 = FixedHypot(p.mo.momx, p.mo.momy)
	local speed2 = FixedHypot(sp.mo.momx, sp.mo.momy)

	if not P_PlayerInPain(sp)
	and sp.mo.health then
		P_InstaThrust(sp.mo, angle, FixedMul(speed1, FU-abs(diff)))
		sp.mo.momz = 5*diff
	end
	if not P_PlayerInPain(p)
	and p.mo.health then
		P_InstaThrust(p.mo, angle, FixedMul(speed2, FU-abs(diff)))
		p.mo.momz = -5*diff
	end
end

function module.damagePlayer(p, ap) // ap: attacking player
	local i = ap.mo
	local s = ap.mo

	if ap.heist.thrower
	and ap.heist.thrower.valid
	and FangsHeist.isPlayerAlive(ap.heist.thrower) then
		s = ap.heist.thrower.mo
	end
	P_DamageMobj(p.mo, ap.mo, s)

	module.bouncePlayers(p, ap)
end

local valid = function(p)
	return (not P_PlayerInPain(p) or FangsHeist.isPlayerUnconscious(p))
	and FangsHeist.isPlayerAlive(p)
	and p.mo.health
	and not p.heist.exiting
end

local function determine_attack(data)
	local p = data.players[1]
	local sp = data.players[2]

	local attack_priority = module.canPlayerHitOthers(p)
	local attack_priority2 = module.canPlayerHitOthers(sp)

	if attack_priority > attack_priority2 then
		module.damagePlayer(sp, p)
		return
	end

	if attack_priority2 > attack_priority then
		module.damagePlayer(p, sp)
		return
	end

	local priority1 = module.getPriority(p, sp)
	local priority2 = module.getPriority(sp, p)

	if priority1 > priority2 then
		module.damagePlayer(sp, p)
		return
	end

	if priority2 > priority1 then
		module.damagePlayer(p, sp)
		return
	end

	module.bouncePlayers(p, sp)
	S_StartSound(p.mo, sfx_s1b4)
	S_StartSound(sp.mo, sfx_s1b4)
	p.powers[pw_flashing] = TICRATE/3
	sp.powers[pw_flashing] = TICRATE/3
end

local function conscious_throw_check(p, sp)
	if FangsHeist.isPlayerUnconscious(p)
	and p.heist.thrower == sp then
		return true
	end

	return false
end

function module.tick()
	local attacks = {}

	for p in players.iterate do
		if not valid(p) then continue end
		if not module.canPlayerHitOthers(p) then continue end
		if attacks[p] then continue end

		for sp in players.iterate do
			if not valid(sp) then continue end
			if not module.canPlayerBeHit(sp) then continue end
			if attacks[sp] then continue end

			if p == sp then continue end

			local dist = R_PointToDist2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)
			local height = abs(p.mo.z-sp.mo.z)

			if dist > p.mo.radius+sp.mo.radius then
				continue
			end

			if height > max(p.mo.height, sp.mo.height) then
				continue
			end

			if conscious_throw_check(p, sp)
			or conscious_throw_check(sp, p) then
				continue
			end

			attacks[sp] = {players = {p, sp}, handled = false}
			attacks[p] = attacks[sp]
		end
	end

	for _,attack in pairs(attacks) do
		if attack.handled then continue end

		determine_attack(attack)
		attack.handled = true
	end
end

return module