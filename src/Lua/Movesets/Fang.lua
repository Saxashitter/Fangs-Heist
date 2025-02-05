local POPGUN_TIME = 24
local POPGUN_FRICTION = tofixed("0.92")

local SKID_TIME = 3

-- slot character
FangsHeist.makeCharacter("fang", {
	difficulty = FHD_MEDIUM,
	pregameBackground = "FH_PREGAME_FANG",
	attackCooldown = 53
})

function A_ForceFrame(mo, var1, var2)
	mo.frame = var1
end

-- slot states
states[freeslot "S_FH_FANG_GUN_GRND2"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FIRE,
	action = A_ForceFrame,
	var1 = D,
	tics = -1
}
states[freeslot "S_FH_FANG_GUN_GRND1"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FIRE|FF_SPR2ENDSTATE,
	tics = 3,
	nextstate = S_FH_FANG_GUN_GRND1,
	var1 = S_FH_FANG_GUN_GRND2
}
states[freeslot "S_FH_FANG_GUN_AIR2"] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEE,
	tics = -1,
	action = A_ForceFrame,
	var1 = skins["fang"].sprites[SPR2_MLEE].numframes-1
}
states[freeslot "S_FH_FANG_GUN_AIR1"] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEE|FF_SPR2ENDSTATE,
	tics = 3,
	nextstate = S_FH_FANG_GUN_AIR1,
	var1 = S_FH_FANG_GUN_AIR2
}

local popgunStates = {
	[S_FH_FANG_GUN_GRND1] = true,
	[S_FH_FANG_GUN_GRND2] = true,
	[S_FH_FANG_GUN_AIR1] = true,
	[S_FH_FANG_GUN_AIR2] = true
}

local function initialize(p)
	p.fang = {
		popgun = 0,
		skidtime = 0
	}
end

local function hasControl(p)
	if p.pflags & PF_STASIS then return false end
	if p.pflags & PF_FULLSTASIS then return false end
	if p.pflags & PF_SLIDING then return false end
	if p.powers[pw_nocontrol] then return false end
	if P_PlayerInPain(p) then return false end
	if not (p.mo.health) then return false end

	return true
end

local function getState(p)
	if not P_IsObjectOnGround(p.mo) then
		if p.pflags & PF_JUMPED then
			return S_PLAY_JUMP
		end

		if p.mo.momz*P_MobjFlip(p.mo) > 0 then
			return S_PLAY_SPRING
		end

		return S_PLAY_FALL
	end

	local speed = FixedHypot(p.mo.momx, p.mo.momz)
	if speed > p.runspeed then
		return S_PLAY_RUN
	end

	if speed then
		return S_PLAY_WALK
	end

	return S_PLAY_STND
end

local function doPopgun(p)
	p.drawangle = p.mo.angle
	p.mo.state = P_IsObjectOnGround(p.mo) and S_FH_FANG_GUN_GRND1 or S_FH_FANG_GUN_AIR1

	local cork = P_SpawnMobjFromMobj(
		p.mo,
		0,
		0,
		(p.mo.height/2)-(mobjinfo[MT_CORK].height/2),
		MT_CORK
	)

	if cork and cork.valid then
		cork.target = p.mo

		local speed = FixedHypot(p.mo.momx,p.mo.momy)
		P_InstaThrust(cork, p.mo.angle, speed+24*FU)

		cork.scale = $*3/2
		cork.momz = 2*FU*P_MobjFlip(p.mo)
		cork.flags = $ & ~MF_NOGRAVITY
		cork.angle = p.mo.angle

		S_StartSoundAtVolume(p.mo,sfx_s1c4,150)
	end

	if not P_IsObjectOnGround(p.mo)
	and p.pflags & PF_JUMPED
	and not (p.pflags & PF_THOKKED)
	and not FangsHeist.playerHasSign(p) then
		p.pflags = $ & ~PF_JUMPED|PF_STARTJUMP
		P_SetObjectMomZ(p.mo, max(p.mo.momz*P_MobjFlip(p.mo)*5/4, FU*6))

		if p.mo.momz*P_MobjFlip(p.mo) > FU*10 then
			p.pflags = $|PF_JUMPED|PF_STARTJUMP
		end

		p.pflags = $|PF_THOKKED
	end

	p.heist.attack_cooldown = POPGUN_TIME
	p.fang.popgun = POPGUN_TIME

	S_StartSound(p.mo, sfx_corkp)
end

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then
		p.fang = nil
		return
	end
	if not (p.mo and p.mo.skin == "fang" and p.heist) then
		p.fang = nil
		return
	end

	if not p.fang then
		initialize(p)
	end

	if p.fang.popgun then
		p.fang.popgun = max(0, $-1)

		if popgunStates[p.mo.state]
		and P_IsObjectOnGround(p.mo)
		and FixedHypot(p.rmomx, p.rmomy) then
			p.rmomx = FixedMul($, POPGUN_FRICTION)
			p.rmomy = FixedMul($, POPGUN_FRICTION)
			p.mo.momx = p.cmomx+p.rmomx
			p.mo.momy = p.cmomy+p.rmomy

			p.fang.skidtime = max(0, $-1)
			if not (p.fang.skidtime) then
				p.fang.skidtime = SKID_TIME
				S_StartSound(p.mo,sfx_s3k7e)

				local r = p.mo.radius/FRACUNIT

				P_SpawnMobj(
					P_RandomRange(-r,r)*FU+p.mo.x,
					P_RandomRange(-r,r)*FU+p.mo.y,
					p.mo.z,
					MT_DUST
				)
			end
		end

		if p.fang.popgun == 0
		and popgunStates[p.mo.state] then
			p.mo.state = getState(p)
			p.fang.skidtime = 0
		end
	end

	if not hasControl(p) then return end

	if p.cmd.buttons & BT_SPIN
	and not (p.lastbuttons & BT_SPIN)
	and not (p.fang.popgun)
	and not (p.heist.attack_cooldown)
	and not (p.pflags & PF_BOUNCING) then
		if not (not P_IsObjectOnGround(p.mo) and p.powers[pw_shield]) then
			doPopgun(p)
		end
	end
end)