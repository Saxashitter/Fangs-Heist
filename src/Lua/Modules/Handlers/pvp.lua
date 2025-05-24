local module = {}
// PVP rewrite #3, this time we aren't gonna have a Battlemod like system.

local STR_INSTASHIELD = STR_ATTACK|STR_BUST
local STR_BLOCK = STR_HEAVY

for i = 1,4 do
	sfxinfo[freeslot("sfx_dmga"..i)].caption = "Attack"
	sfxinfo[freeslot("sfx_dmgb"..i)].caption = "Attack"
end
sfxinfo[freeslot"sfx_fhboff"].caption = "Block disabled"
sfxinfo[freeslot"sfx_fhbonn"].caption = "Block enabled"
sfxinfo[freeslot"sfx_fhbbre"].caption = "Block broken"

states[freeslot "S_FH_INSTASHIELD"] = {
	sprite = freeslot"SPR_TWSP",
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	tics = G,
	var1 = G,
	var2 = 1
}
states[freeslot "S_FH_SHIELD"] = {
	sprite = freeslot"SPR_FHSH",
	frame = A|FF_FULLBRIGHT|FF_TRANS30,
	tics = -1
}

mobjinfo[freeslot "MT_FH_INSTASHIELD"] = {
	radius = 64*FU,
	height = 64*FU,
	spawnstate = S_FH_INSTASHIELD,
	flags = MF_NOGRAVITY|MF_SCENERY|MF_NOCLIPHEIGHT|MF_NOCLIP
}

local function doAttack(p)
	if FangsHeist.Characters[p.mo.skin]:onAttack(p) then
		return
	end
	p.heist.attack_cooldown = FangsHeist.Characters[p.mo.skin].attackCooldown
	p.heist.attack_time = FH_ATTACKTIME

	local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_FH_INSTASHIELD)
	shield.target = p.mo

	S_StartSound(p.mo, sfx_s3k42)

	if not (p.powers[pw_strong] & STR_INSTASHIELD) then
		p.powers[pw_strong] = $|STR_INSTASHIELD
		p.heist.strongAdded = true
	end
end

local function playerCheck(p)
	return p and FangsHeist.isPlayerAlive(p) and not P_PlayerInPain(p) and not p.heist.exiting
end

function FangsHeist.bouncePlayers(p, sp, stopAttack)
	local angle = R_PointToAngle2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)

	P_InstaThrust(p.mo, angle, -12*FU)
	p.mo.momz = 0

	if not P_IsObjectOnGround(p.mo) then
		p.mo.state = S_PLAY_FALL
		p.pflags = $|PF_JUMPED|PF_THOKKED
	end

	if stopAttack then
		p.heist.attack_time = 0
		if p.heist.strongAdded then
			p.powers[pw_strong] = $ & ~STR_INSTASHIELD
			p.heist.strongAdded = false
		end
	end
end

local attackSounds = {
	{sfx_dmga1, sfx_dmgb1},
	{sfx_dmga2, sfx_dmgb2},
	{sfx_dmga3, sfx_dmgb3},
	{sfx_dmga4, sfx_dmgb4}
}

function FangsHeist.damagePlayer(p, sp, projectile)
	local tier = 1
	local speed = FixedHypot(FixedHypot(p.mo.momx-sp.mo.momx, p.mo.momy-sp.mo.momy), p.mo.momz-sp.mo.momz)

	if not (projectile and projectile.valid) then
		projectile = false
	end

	tier = max(1, min(FixedDiv(speed, 10*FU)/FU, #attackSounds))
	local sound = attackSounds[tier][P_RandomRange(1, 2)]

	if P_DamageMobj(sp.mo, projectile or p.mo, p.mo) then
		if not FangsHeist.Characters[p.mo.skin]:onHit(p, sp, (projectile), sound) then
			if not projectile then
				S_StartSound(p.mo, sound)
				FangsHeist.bouncePlayers(p, sp)
			end
		end
	end
end

local function attackPlayers(p)
	for sp in players.iterate do
		if not playerCheck(sp) then continue end
		if sp == p then continue end
		if p.heist:isPartOfTeam(sp)
		and not sp.heist:hasSign() then
			continue
		end
		if sp.powers[pw_flashing]
		or sp.powers[pw_invulnerability] then
			continue
		end

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

		if FangsHeist.Characters[sp.mo.skin]:isAttacking(sp) then
			FangsHeist.bouncePlayers(p, sp, true)
			FangsHeist.bouncePlayers(sp, p, true)
			S_StartSound(p.mo, sfx_s3k7b)
			S_StartSound(sp.mo, sfx_s3k7b)
			continue
		end

		FangsHeist.damagePlayer(p, sp)
	end
end

addHook("MobjThinker", function(mo)
	if not playerCheck(mo.target.player) then
		P_RemoveMobj(mo)
		return
	end

	P_MoveOrigin(mo,
		mo.target.x,
		mo.target.y,
		mo.target.z)
end, MT_FH_INSTASHIELD)

function module.tick()
	for p in players.iterate do
		if p.heist
		and not (p.heist.shield and p.heist.shield.valid) then
			p.heist.shield = nil
		end
	
		if not playerCheck(p) then
			if p.heist then 
				p.heist.blocking = false
				p.heist.block_time = 0
				p.heist.block_cooldown = 0
				p.powers[pw_strong] = $ & ~STR_BLOCK
				if p.heist.blockMobj
				and p.heist.blockMobj.valid then
					P_RemoveMobj(p.heist.blockMobj)
					p.heist.blockMobj = nil
				end
			end
			continue
		end

		if p.heist.attack_cooldown then
			p.heist.attack_cooldown = max(0, $-1)

			if not (p.heist.attack_cooldown) then
				local ghost = P_SpawnGhostMobj(p.mo)
				ghost.destscale = $*3
			end
		end

		p.heist.block_cooldown = max(0, $-1)
		p.heist.attack_time = max(0, $-1)

		if not p.heist.attack_time and p.heist.strongAdded then
			p.powers[pw_strong] = $ & ~STR_INSTASHIELD
			p.heist.strongAdded = false
		end

		manageBlock(p)

		if not (p.heist.blocking)
		and p.cmd.buttons & BT_ATTACK
		and not (p.lastbuttons & BT_ATTACK)
		and not (p.heist.attack_cooldown) then
			doAttack(p)
		end

		if FangsHeist.Characters[p.mo.skin]:isAttacking(p) then
			attackPlayers(p)
		end
	end
end

return module