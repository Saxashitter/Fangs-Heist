local module = {}
// PVP rewrite #3, this time we aren't gonna have a Battlemod like system.

rawset(_G, "FH_ATTACKCOOLDOWN", TICRATE)
rawset(_G, "FH_ATTACKTIME", G)
rawset(_G, "FH_BLOCKCOOLDOWN", 5)
rawset(_G, "FH_BLOCKTIME", 5*TICRATE)
rawset(_G, "FH_BLOCKDEPLETION", FH_BLOCKTIME/3)

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

local function bouncePlayer(p, sp, stopAttack)
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
	if sp.heist.blocking then
		sp.heist.block_time = min(FH_BLOCKTIME, $+FH_BLOCKDEPLETION)
		if sp.heist.block_time == FH_BLOCKTIME then
			if not projectile then
				bouncePlayer(p, sp, false)
			end
			S_StartSound(sp.mo, sfx_fhbbre)
		else
			if not projectile then
				bouncePlayer(p, sp, true)
			end
			S_StartSound(p.mo, sfx_s3k7b)
			return
		end
	end

	local tier = 1
	local speed = FixedHypot(FixedHypot(p.mo.momx-sp.mo.momx, p.mo.momy-sp.mo.momy), p.mo.momz-sp.mo.momz)

	tier = max(1, min(FixedDiv(speed, 10*FU)/FU, #attackSounds))

	S_StartSound(p.mo, attackSounds[tier][P_RandomRange(1, 2)])
	P_DamageMobj(sp.mo, (projectile and projectile.valid) and projectile or p.mo, p.mo)
	if not projectile then
		bouncePlayer(p, sp)
	end
end

local function attackPlayers(p)
	for sp in players.iterate do
		if not playerCheck(sp) then continue end
		if sp == p then continue end
		if FangsHeist.partOfTeam(p, sp)
		and not FangsHeist.playerHasSign(sp) then
			continue
		end
		if sp.powers[pw_flashing]
		or sp.powers[pw_invulnerability] then
			continue
		end

		local distXY = FixedHypot(p.mo.x-sp.mo.x, p.mo.y-sp.mo.y)
		local distZ = abs(p.mo.z-sp.mo.z)

		if distXY > FixedMul(p.mo.radius+sp.mo.radius, FU*3) then continue end
		if distZ > max(p.mo.height, sp.mo.height)*2 then continue end

		if sp.heist.attack_time then
			bouncePlayer(p, sp, true)
			bouncePlayer(sp, p, true)
			S_StartSound(p.mo, sfx_s3k7b)
			S_StartSound(sp.mo, sfx_s3k7b)
			continue
		end

		FangsHeist.damagePlayer(p, sp)
	end
end

local function manageBlock(p)
	if not (p.heist.block_cooldown) then
		if not p.heist.blocking
		and p.cmd.buttons & BT_FIRENORMAL
		and not (p.lastbuttons & BT_FIRENORMAL)
		and not (p.heist.attack_cooldown) then
			p.heist.blocking = true
			p.powers[pw_strong] = $|STR_BLOCK
			S_StartSound(p.mo, sfx_fhbonn)
			p.heist.block_cooldown = FH_BLOCKCOOLDOWN
		end
	
		if p.heist.blocking
		and not (p.cmd.buttons & BT_FIRENORMAL) then
			p.heist.blocking = false
			p.powers[pw_strong] = $ & ~STR_BLOCK
			S_StartSound(p.mo, sfx_fhboff)
			p.heist.block_cooldown = FH_BLOCKCOOLDOWN
		end
	end

	if not (p.heist.blockMobj and p.heist.blockMobj.valid) then
		p.heist.blockMobj = nil
	end

	if p.heist.blocking
	and not (p.heist.blockMobj) then
		local thok = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)

		thok.state = S_FH_SHIELD
		thok.dispoffset = 10
		thok.flags = MF_NOTHINK
		thok.spriteyoffset = -2*FU
		thok.colorized = true

		p.heist.blockMobj = thok
	end

	if p.heist.blocking then
		p.heist.blockMobj.color = p.mo.color
	
		local t = FixedDiv(p.heist.block_time, FH_BLOCKTIME*2)
		local scale = FixedDiv(p.mo.height, 22*FU)

		p.heist.blockMobj.scale = ease.linear(t, scale, 0)

		local z = ease.linear(t, 0, p.mo.height/2)
		P_MoveOrigin(p.heist.blockMobj,
			p.mo.x, p.mo.y, p.mo.z+z)
	
		p.heist.block_time = min(FH_BLOCKTIME, $+1)
	else
		if p.heist.blockMobj then
			P_RemoveMobj(p.heist.blockMobj)
			p.heist.blockMobj = nil
		end
		p.heist.block_time = max(0, $-2)
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

		p.heist.block_cooldown = max(0, $-1)
		p.heist.attack_cooldown = max(0, $-1)
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

		if p.heist.attack_time then
			attackPlayers(p)
		end
	end
end

return module