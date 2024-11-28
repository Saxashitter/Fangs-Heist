local module = {}
// General PVP handler.
// PVP REWRITE #2

local STR_CAN_ATTACK = STR_PUNCH|STR_ATTACK|STR_STOMP|STR_GLIDE|STR_MELEE|STR_STOMP

local function p_check(p)
	return p and p.valid and FangsHeist.isPlayerAlive(p)
end

function module.canPlayerBeHit(p)
	local invincible = p.powers[pw_flashing] or p.powers[pw_invulnerability]

	return not P_PlayerInPain(p)
	and not (invincible)
end

function module.canPlayerHitOthers(p)
	local isAttacking = 0

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

// COPIED FROM BATTLEMOD
module.getPriority = function(player)
	local grounded = P_IsObjectOnGround(player.mo)
	local pflags = player.pflags
	local abil1 = player.charability
	local abil2 = player.charability2
	local anim1 = (player.panim == PA_ABILITY)
	local anim2 = (player.panim == PA_ABILITY2)
	local thokked = pflags&PF_THOKKED
	local shieldability = pflags&PF_SHIELDABILITY
	local shield =  player.powers[pw_shield]&SH_NOSTACK
	
	local spinjump = (pflags&PF_JUMPED and not(pflags&PF_NOJUMPDAMAGE))
	local spindash = pflags&PF_SPINNING and pflags&PF_STARTDASH
	local spinning = pflags&PF_SPINNING
	
	local super = (player.powers[pw_super])
	local invstar = (player.powers[pw_invulnerability])
	local homing = (player.homing)
	local bubble = (shield==SH_BUBBLEWRAP)
	local flame = (shield==SH_FLAMEAURA)
	local elemental = (shield==SH_ELEMENTAL)
	local attr = (shield==SH_ATTRACT)
	
	local sonicthokked = (abil1 == CA_THOK and thokked)
	local knuckles = (abil1 == CA_GLIDEANDCLIMB)
	local flying = (abil1 ==CA_FLY and player.panim == PA_ABILITY)
	local gliding = pflags&PF_GLIDING
	local twinspin = (abil1 == CA_TWINSPIN and anim1)
	local melee = (abil2 ==CA2_MELEE and anim2)
	local tailbounce = pflags&PF_BOUNCING
	local dashing = player.dashmode > 3*TICRATE and not(player.pflags&PF_STARTDASH)
	local prepdash = player.dashmode > 3*TICRATE and player.pflags&PF_STARTDASH
	
	// this part is by me, im dealing with my own stuff
	/* System:
			Spindash = 1
			Jump = 2
			Melee = 3
			Roll = 4
	*/
	local attacking = melee
	or tailbounce
	or twinspin
	or gliding

	if invstar
	or super then
		return 5
	end

	if spindash then
		return 1
	end
	if attacking then
		return 3
	end
	if spinjump then
		return 2
	end
	if roll then
		return 4
	end

	return 0
end

/*function module.getPriority(p, sp)
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
end*/

function module.bouncePlayers(p, sp)
	local momx1 = sp.mo.momx
	local momy1 = sp.mo.momy
	local momz1 = sp.mo.momz

	local momx2 = p.mo.momx
	local momy2 = p.mo.momy
	local momz2 = p.mo.momz

	local isPain1 = P_PlayerInPain(sp)
	local isPain2 = P_PlayerInPain(p)

	if not isPain1
	and sp.mo.health
	and (sp.pflags & PF_SPINNING|PF_JUMPED) then
		sp.mo.momx = momx2
		sp.mo.momy = momy2
		sp.mo.momz = momz2
	end
	if not isPain2
	and p.mo.health
	and (p.pflags & PF_SPINNING|PF_JUMPED) then
		p.mo.momx = momx1
		p.mo.momy = momy1
		p.mo.momz = momz1
	end
end

function module.damagePlayer(p, ap) // ap: attacking player
	local i = ap.mo
	local s = ap.mo

	P_DamageMobj(p.mo, ap.mo, s)

	module.bouncePlayers(p, ap)
end

local valid = function(p)
	return not P_PlayerInPain(p)
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

	local priority1 = module.getPriority(p)
	local priority2 = module.getPriority(sp)

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

			if dist > FixedMul(p.mo.radius+sp.mo.radius, FU+(FU*3/4)) then
				continue
			end

			if height > FixedMul(max(p.mo.height, sp.mo.height), FU+(FU*3/4)) then
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