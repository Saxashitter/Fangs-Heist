local module = {}
// PVP rewrite #3, this time we aren't gonna have a Battlemod like system.

local ATTACK_COOLDOWN = TICRATE
local ATTACK_TIME = G

states[freeslot "S_FH_INSTASHIELD"] = {
	sprite = freeslot"SPR_TWSP",
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	tics = G,
	var1 = G,
	var2 = 1
}

mobjinfo[freeslot "MT_FH_INSTASHIELD"] = {
	radius = 64*FU,
	height = 64*FU,
	spawnstate = S_FH_INSTASHIELD,
	flags = MF_NOGRAVITY|MF_SCENERY|MF_NOCLIPHEIGHT|MF_NOCLIP
}

local function doAttack(p)
	p.heist.attack_cooldown = ATTACK_COOLDOWN
	p.heist.attack_time = ATTACK_TIME

	local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_FH_INSTASHIELD)
	shield.target = p.mo

	S_StartSound(p.mo, sfx_s3k42)

	if not (p.powers[pw_strong] & STR_ATTACK) then
		p.powers[pw_strong] = $|STR_ATTACK|STR_HEAVY
		p.heist.strongAdded = true
	end

end

local function playerCheck(p)
	return p and FangsHeist.isPlayerAlive(p) and not P_PlayerInPain(p)
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
			p.powers[pw_strong] = $ & ~(STR_HEAVY|STR_ATTACK)
			p.heist.strongAdded = false
		end
	end
end

local function attackPlayers(p)
	for sp in players.iterate do
		if not playerCheck(sp) then continue end
		if sp == p then continue end
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

		P_DamageMobj(sp.mo, p.mo, p.mo)
		bouncePlayer(p, sp)
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
	
		if not playerCheck(p) then continue end

		p.heist.attack_cooldown = max(0, $-1)
		p.heist.attack_time = max(0, $-1)

		if not p.heist.attack_time and p.heist.strongAdded then
			p.powers[pw_strong] = $ & ~(STR_HEAVY|STR_ATTACK)
			p.heist.strongAdded = false
		end

		if not (p.heist.shield)
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