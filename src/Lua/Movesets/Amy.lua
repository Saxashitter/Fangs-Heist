local function canAttack(p)
	return not (p.heist.blocking or p.heist.attack_cooldown or (p.amy and p.amy.thrown and p.amy.thrown.valid))
end

states[freeslot "S_FH_AMY_TWIRL"] = {
	sprite = SPR_PLAY,
	frame = freeslot "SPR2_TWRL",
	tics = 1,
	nextstate = S_FH_AMY_TWIRL
}

-- Amy Hammer
states[freeslot "S_FH_THROWNHAMMER"] = {
	sprite = freeslot "SPR_AHMR",
	frame = FF_ANIMATE,
	tics = -1,
	var1 = H,
	var2 = 1
}
mobjinfo[freeslot "MT_FH_THROWNHAMMER"] = {
	spawnstate = S_FH_THROWNHAMMER,
	radius = 64*FU,
	height = 64*FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
}

FangsHeist.makeCharacter("amy", {
	pregameBackground = "FH_PREGAME_AMY",
	attackRange = tofixed("1.3"),
	attackZRange = tofixed("1.5"),
	isAttacking = function(self, p)
		return (p.powers[pw_strong] & STR_ATTACK)
	end,
	onHit = function(self, p, projectile, sound)
		if projectile then return end

		S_StartSound(p.mo, sound)
		p.mo.momx = $*-1
		p.mo.momy = $*-1

		if not P_IsObjectOnGround(p.mo) then
			p.mo.state = S_PLAY_FALL
			return true
		end

		p.mo.state = S_PLAY_STND
		return true
	end,
	useDefaultAttack = false,

	controls = {
		{
			key = "SPIN/JUMP",
			name = "Attack (Melee)",
			cooldown = function(self, p)
				return not canAttack(p)
			end,
			visible = function(self, p)
				return not p.heist.blocking
			end
		},
		{
			key = "FIRE",
			name = "Attack (Throw)",
			cooldown = function(self, p)
				return not canAttack(p)
			end,
			visible = function(self, p)
				return not p.heist.blocking
			end
		},
		FangsHeist.Characters.sonic.controls[2]
	}
})

local function init(p)
	p.amy = {
		twirl = false,
		twirlframes = 0,
	}
end

local function check(p)
	if not (p and p.mo and p.mo.skin == "amy" and p.heist and p.amy) then
		return false
	end

	if p.pflags & PF_STASIS then
		return false
	end

	if p.exiting then
		return false
	end

	if P_PlayerInPain(p) or p.mo.health == 0 then
		return false
	end

	return true
end

local function throwHammer(p)
	local hammer = P_SpawnMobjFromMobj(p.mo,
		0, 0, p.mo.height/2 - mobjinfo[MT_FH_THROWNHAMMER].height/2,
		MT_FH_THROWNHAMMER
	)

	if not (hammer and hammer.valid) then
		return
	end

	hammer.target = p.mo
	hammer.returntics = 16
	P_InstaThrust(hammer, p.mo.angle, FixedHypot(p.mo.momx, p.mo.momy)+53*FU)

	S_StartSound(p.mo, sfx_s3k51)

	return hammer
end

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then 
		p.amy = nil
		return
	end
	if not (p and p.mo and p.mo.skin == "amy" and p.heist) then
		p.amy = nil
		return
	end

	if not (p.amy) then
		init(p)
	end

	if p.amy.thrown and p.amy.thrown.valid then
		p.heist.attack_cooldown = 62
	else
		p.amy.thrown = nil
	end

	local attackFlags = STR_ATTACK|STR_WALL|STR_CEILING|STR_SPIKE

	if p.mo.state == S_FH_AMY_TWIRL then
		local gravity = 3

		if FangsHeist.playerHasSign(p) then
			gravity = 9
		end

		p.pflags = $|PF_JUMPSTASIS
		p.mo.momz = max(-gravity*p.mo.scale, $)

		p.amy.twirl = true
		p.powers[pw_strong] = $|attackFlags

		if p.amy.twirlframes -- stupid abilityspecial runnig before playerthink
		and p.cmd.buttons & BT_JUMP
		and not (p.lastbuttons & BT_JUMP) then
			p.mo.state = S_PLAY_FALL
		end

		p.amy.twirlframes = $+1
	elseif canAttack(p)
	and p.cmd.buttons & BT_ATTACK
	and not (p.lastbuttons & BT_ATTACK)
	and not P_PlayerInPain(p) then
		-- Hammer Throw
		local hammer = throwHammer(p)

		p.amy.thrown = hammer
	end

	if p.mo.state ~= S_FH_AMY_TWIRL
	and p.amy.twirl then
		p.amy.twirl = false
		p.amy.twirlframes = 0
		p.powers[pw_strong] = $ & ~attackFlags
	end

	p.powers[pw_strong] = $ & ~STR_SPRING -- not so overpowered arent you now
end)

addHook("AbilitySpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if not canAttack(p)
	or not p.amy then
		return true
	end

	if p.pflags & PF_JUMPED
	and not (p.pflags & PF_THOKKED) then
		p.heist.attack_cooldown = 85
		S_StartSound(p.mo, sfx_s1ab) -- jet jaw sfx
		P_SetObjectMomZ(p.mo, 7*FU)
		p.mo.state = S_FH_AMY_TWIRL
		p.pflags = $|PF_THOKKED
		p.amy.twirlframes = 0
		return true
	end
end)
addHook("JumpSpinSpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if p.powers[pw_shield] then
		return
	end

	if not canAttack(p) then
		return true
	end

	if p.pflags & PF_JUMPED
	and not (p.pflags & PF_THOKKED) then
		p.heist.attack_cooldown = 50
	end
end)

addHook("SpinSpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	local canstand = (not p.mo.standingslope
		or p.mo.standingslope.flags & SL_NOPHYSICS
		or abs(p.mo.standingslope.zdelta) < FU/2)

	if not (p.panim ~= PA_ABILITY2
	and p.cmd.buttons & BT_SPIN
	and not (p.mo.momz)
	and P_IsObjectOnGround(p.mo)
	and not (p.pflags & PF_SPINDOWN)
	and canstand) then
		return
	end

	if p.heist.attack_cooldown
	or p.heist.blocking then
		return true
	end

	p.heist.attack_cooldown = 50
end)

local function L_ReturnThrustXYZ(mo, point, speed)
	local horz = R_PointToAngle2(mo.x, mo.y, point.x, point.y)
	local vert = R_PointToAngle2(0, mo.z+(mo.height/2), FixedHypot(mo.x-point.x, mo.y-point.y), point.z+(point.height/2))

	local x = FixedMul(FixedMul(speed, cos(horz)), cos(vert))
	local y = FixedMul(FixedMul(speed, sin(horz)), cos(vert))
	local z = FixedMul(speed, sin(vert))

	return x, y, z
end

local function isDamagable(mo, p)
	if mo.flags & MF_ENEMY
	or mo.flags & MF_MONITOR then
		return true
	end
	
	if mo.type == MT_PLAYER
	and p
	and p.heist
	and mo.player
	and mo.player.heist
	and not FangsHeist.partOfTeam(p, mo.player) then
		return true
	end
	
	if mo.type == MT_RING 
	or mo.type == MT_FLINGRING then
		return true
	end

	return false
end

local function collisionCheck(mo, pmo)
	return FixedHypot(mo.x-pmo.x, mo.y-pmo.y) <= pmo.radius+mo.radius
	and mo.z < pmo.z+pmo.height
	and pmo.z < mo.z+mo.height
end

local function erectRing(mo, found)
	if mo.target and mo.target.valid then
		if found.type == MT_RING 
		or found.type == MT_FLINGRING then
			P_TouchSpecialThing(found, mo.target)
			return true
		end
	end
end

local function onObjectFound(mo, found)
	if not (found and found.valid) then return end
	if not isDamagable(found, mo.target.player) then return end
	if found == mo.target then return end
	if not collisionCheck(mo, found) then return end
	
	if erectRing(mo, found) then return end
	
	if P_DamageMobj(found, mo, mo.target) then
		if found.type == MT_PLAYER then
			S_StartSound(mo, sfx_dmga3)
			S_StartSound(mo.target, sfx_dmga3, mo.target.player)
		end

		mo.momx = $*-1
		mo.momy = $*-1
		mo.momz = $*-1
		mo.returntics = 0

		return
	end

	if found.type == MT_PLAYER
	and found.player
	and found.player.heist
	and found.player.heist.blocking then
		mo.momx = $*-1
		mo.momy = $*-1
		mo.momz = $*-1
		mo.returntics = 0
	end
end

-- Hammer Thinker
addHook("MobjThinker", function(mo)
	if not (mo and mo.valid) then return  end
	if not (mo.target and mo.target.valid and mo.target.health) then
		local pmo = mo.target

		if pmo and pmo.valid and pmo.player and pmo.player.amy then
			pmo.player.amy.thrown = nil
		end
		P_RemoveMobj(mo)
		return
	end

	P_SpawnGhostMobj(mo)

	local pmo = mo.target

	local angle = R_PointToAngle2(mo.x, mo.y, pmo.x, pmo.y)
	local speed = tofixed("0.07")

	local x, y, z = L_ReturnThrustXYZ(mo, pmo, 3*FU)
	local friction = tofixed("0.95")

	mo.momx = FixedMul($+x, friction)
	mo.momy = FixedMul($+y, friction)
	mo.momz = FixedMul($+z, friction)

	searchBlockmap("objects",
		onObjectFound,
		mo,
		mo.x-mo.radius*2, -- Even if you change the radius and height, keep it multiplied by 2, so it's accurate.
		mo.x+mo.radius*2,
		mo.y-mo.radius*2, 
		mo.y+mo.radius*2
	)

	mo.returntics = max(($ or 0)-1, 0)

	if collisionCheck(pmo, mo)
	and mo.returntics == 0 then
		S_StartSound(pmo, sfx_s3k4a)
		if pmo.player and pmo.player.amy then
			pmo.player.amy.thrown = nil
		end
		P_RemoveMobj(mo)
	end

end, MT_FH_THROWNHAMMER)