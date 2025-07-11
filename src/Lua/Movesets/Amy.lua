local function canAttack(p)
	return not (p.mo.state == S_FH_STUN
	or p.mo.state == S_FH_GUARD
	or p.mo.state == S_FH_CLASH
	or (p.amy and p.amy.thrown and p.amy.thrown.valid))
end

FangsHeist.makeCharacter("amy", {
	pregameBackground = "FH_PREGAME_AMY",
	controls = {
		{
			key = "SPIN/JUMP",
			name = "Attack (Melee)",
			cooldown = function(self, p)
				return not canAttack(p)
			end,
			visible = function(self, p)
				return p.mo.state ~= S_FH_CLASH
				and p.mo.state ~= S_FH_STUN
				and p.mo.state ~= S_FH_GUARD
			end
		},
		FangsHeist.Characters.sonic.controls[1],
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

local THROW_TIME = 27

local function throwHammer(p)
	local z = (p.mo.height/2) - (mobjinfo[MT_FH_THROWNHAMMER].height/2)
	local hammer = P_SpawnMobjFromMobj(p.mo,
		0, 0, z,
		MT_FH_THROWNHAMMER
	)

	if not (hammer and hammer.valid) then
		return
	end

	hammer.target = p.mo
	hammer.angle = p.mo.angle
	hammer.throwtime = THROW_TIME
	hammer.throwspeed = FixedHypot(p.mo.momx, p.mo.momy)+25*FU
	P_InstaThrust(hammer, hammer.angle, fixhypot(p.mo.momx, p.mo.momy) + 34*FU)

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

	local attack = canAttack(p)

	if not (p.amy.thrown and p.amy.thrown.valid) then
		p.amy.thrown = nil
	end

	local attackFlags = STR_ATTACK|STR_WALL|STR_CEILING|STR_SPIKE

	if p.mo.state == S_FH_AMY_TWIRL then
		local ghost = P_SpawnGhostMobj(p.mo)
		ghost.fuse = 3
		ghost.colorized = true

		p.pflags = $|PF_JUMPSTASIS

		p.amy.twirl = true
		p.powers[pw_strong] = $|attackFlags

		p.amy.twirlframes = $+1
		if not (p.amy.twirlframes % 3) then
			local thokring = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_THOK)
			thokring.state = S_FH_THIK
			thokring.fuse = 10
			thokring.scale = 3*p.mo.scale/2
			thokring.destscale = 0
		end
	--[[elseif attack
	and p.cmd.buttons & BT_ATTACK
	and not (p.lastbuttons & BT_ATTACK)
	and not P_PlayerInPain(p)
	and p.mo.health then
		-- Hammer Throw
		local hammer = throwHammer(p)

		p.amy.thrown = hammer]]
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

	if not (p.pflags & PF_THOKKED) then
		p.pflags = $|PF_THOKKED
		S_StartSound(p.mo, (p.mo.eflags & MFE_UNDERWATER) and sfx_s3k7d or sfx_kc5b) -- idk this sfx's name
		P_SetObjectMomZ(p.mo, 7*FU)
		P_InstaThrust(p.mo, p.mo.angle, 23*FU) -- not that fast but balanced enough
		if p.mo.eflags & MFE_UNDERWATER --op
			p.mo.momx,p.mo.momy,p.mo.momz = $1/2,$2/2,$3/2
		end

		local thokring = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_THOK)
		thokring.state = S_FH_THIK
		thokring.fuse = 10
		thokring.scale = 3*p.mo.scale/2
		thokring.destscale = 0
		p.mo.state = S_FH_AMY_TWIRL
		p.amy.twirlframes = 0
		return true
	end
end)

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if not canAttack(p)
	or not p.amy then
		return true
	end
	
	if (p.mo.state == S_PLAY_MELEE_LANDING)
	and (p.speed >= 36*FRACUNIT)
	and (p.playerstate == PST_LIVE)
	and not (p.pflags & PF_STASIS)
	and not (p.pflags & PF_FULLSTASIS)
	and (p.cmd.buttons & BT_JUMP)
	and (P_IsObjectOnGround(p.mo) == true)
		P_SetObjectMomZ(p.mo, 15*p.mo.scale)
		p.pflags = $|PF_JUMPED|PF_STARTJUMP|PF_THOKKED
		p.mo.state = S_PLAY_ROLL
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
end)

addHook("SpinSpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if not canAttack(p) then
		return true
	end
end)

local function L_ReturnThrustXYZ(mo, point, speed)
	local horz = R_PointToAngle2(mo.x, mo.y, point.x, point.y)
	local vert = R_PointToAngle2(0, mo.z, FixedHypot(mo.x-point.x, mo.y-point.y), point.z)

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
	and not p.heist:isPartOfTeam(mo.player) then
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
		mo.throwtime = 0

		return
	end

	if found.type == MT_PLAYER
	and found.player
	and found.player.heist then
		mo.momx = $*-1
		mo.momy = $*-1
		mo.momz = $*-1
		mo.throwtime = 0
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

	local pmo = mo.target

	if mo.throwtime then
		P_SpawnGhostMobj(mo)
		local time = THROW_TIME - 10

		mo.momx = fixmul($, tofixed("0.96"))
		mo.momy = fixmul($, tofixed("0.96"))
		mo.momz = fixmul($, tofixed("0.96"))

		mo.throwtime = max (0, $-1)
		mo.flags = ($|MF_BOUNCE) & ~(MF_NOCLIP|MF_NOCLIPHEIGHT)

		searchBlockmap("objects",
			onObjectFound,
			mo,
			mo.x-mo.radius*2, -- Even if you change the radius and height, keep it multiplied by 2, so it's accurate.
			mo.x+mo.radius*2,
			mo.y-mo.radius*2, 
			mo.y+mo.radius*2
		)
	else
		local angle = R_PointToAngle2(mo.x, mo.y, pmo.x, pmo.y)

		mo.momx, mo.momy, mo.momz = L_ReturnThrustXYZ(mo, {
			x = pmo.x,
			y = pmo.y,
			z = pmo.z + (pmo.height/2) - (mo.height/2)
		}, 40*FU)
		mo.flags = ($|MF_NOCLIP|MF_NOCLIPHEIGHT) & ~MF_BOUNCE

		if collisionCheck(pmo, mo) then
			S_StartSound(pmo, sfx_s3k4a)
			if pmo.player and pmo.player.amy then
				pmo.player.amy.thrown = nil
			end
			P_RemoveMobj(mo)
		end
	end
end, MT_FH_THROWNHAMMER)