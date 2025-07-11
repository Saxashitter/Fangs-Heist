freeslot "spr_msud"
freeslot "S_X3UPDASH"
freeslot "sfx_msupds"
states[S_X3UPDASH] = {
	sprite = SPR_MSUD,
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 8,
	var2 = 1,
	tics = 9,
	nextstate = S_NULL
	}
//Some values to modify it!

//DRIFT TURN SPEED!
local DTS = ANG10

//MINIMUM SPEED FOR DRIFT!
local MINSPEED = FU * 15

//It's easy to comprehend.
local DASHMODETICS = 90

//Minimun speed for getting dash mode!
local MINDASHMODE = 26 * FU

//Drift speed loss over time! 
local DSLOT = FU / 8
local DSMAX = FU * 46

local DMBASESPEED = 36 * FU
local DMSPEEDUP = FU/8
local DMMAXSPEED = 46 * FU

local AIRDASHSPEED = 12 * FU

local DASHFLAGS = STR_ATTACK|STR_WALL|STR_CEILING|STR_SPIKE

local function Valid(p)
	return FangsHeist.isMode(p)
	and p
	and p.valid
	and p.heist
	and p.heist:isAlive()
	and p.mo.skin == "metalsonic"
end

local function DashModeDisable(p)
	if not p.mo.metalsonic.dmt then return end

	p.mo.metalsonic.dmt = 0
	p.mo.color = p.skincolor
	p.mo.metalsonic.dmspeed = DMBASESPEED
	p.normalspeed = skins[p.skin].normalspeed
	p.powers[pw_strong] = $ & ~DASHFLAGS
end

local function AirDashDisable(p)
	if not p.mo.metalsonic.airdash then
		return
	end

	p.mo.metalsonic.airdash = false
	p.mo.metalsonic.adp = 0
end

local function DriftDisable(p)
	if not p.mo.metalsonic.drift then
		return
	end

	p.mo.metalsonic.drifthold = false
	p.mo.metalsonic.drift = false
	p.mo.metalsonic.speed = 0
end

local function DashModeTick(p)
	if (P_IsObjectOnGround(p.mo)
	and not (p.pflags & PF_SPINNING)
	and not p.mo.metalsonic.drifthold
	and FixedDiv(p.speed, p.mo.scale) < MINDASHMODE)
	or P_PlayerInPain(p)
	or not (p.mo and p.mo.health) then
		if p.mo and p.mo.health and p.mo.metalsonic.dmt >= DASHMODETICS then
			S_StartSound(p.mo, sfx_kc65)
			p.normalspeed = skins[p.mo.skin].normalspeed
		end

		DashModeDisable(p)
		return
	end

	p.mo.metalsonic.dmt = $ + 1

	if p.mo.metalsonic.dmt == DASHMODETICS then
		S_StartSound(p.mo, sfx_cdfm40)
	end

	if p.mo.metalsonic.dmt > DASHMODETICS then
		p.powers[pw_strong] = $|DASHFLAGS
		p.mo.metalsonic.dmspeed = min($ + DMSPEEDUP, DMMAXSPEED)
		p.normalspeed = p.mo.metalsonic.dmspeed

		if p.mo.state == S_PLAY_RUN then
			p.mo.state = S_PLAY_DASH
		end

		if leveltime%4 < 2 then
			p.mo.color = skincolors[p.skincolor].invcolor
		else
			p.mo.color = p.skincolor + leveltime%2
		end
	end
end

local function AirDashTick(p)
	if not p.mo.metalsonic.airdash then
		return
	end

	p.mo.metalsonic.adp = $ + 1

	if p.mo.metalsonic.adp < 7 then
		p.mo.state = S_PLAY_SPINDASH
		p.mo.momx = $*2/3
		p.mo.momy = $*2/3
		P_SetObjectMomZ(p.mo, FU/2)
		p.pflags = $&~PF_JUMPED&~PF_SPINNING
	end

	if p.mo.metalsonic.adp == 7 then
		local dust = P_SpawnGhostMobj(p.mo)
		dust.fuse = 99999
		dust.state = S_X3UPDASH
		dust.scale = $*5/2
		S_StartSound(p.mo, sfx_msupds)
	end

	if p.mo.metalsonic.adp > 7 then
		P_SetObjectMomZ(p.mo, AIRDASHSPEED)
		p.mo.state = S_PLAY_SPRING

		if P_GetPlayerControlDirection(p)
			P_Thrust(p.mo, p.mo.angle, p.mo.metalsonic.sspd/(1 + (p.mo.metalsonic.adp / 6))/24)
		end
	end

	if p.mo.metalsonic.adp > 24 or not (p.cmd.buttons & BT_SPIN) then
		AirDashDisable(p)
		p.mo.state = S_PLAY_FALL
		p.mo.momz = $/3

		if P_GetPlayerControlDirection(p)
			P_InstaThrust(p.mo, p.mo.angle, p.mo.metalsonic.sspd/(1 + (p.mo.metalsonic.adp / 6)))
		end
	end
end

local function DriftTick(p)
	local speed = FixedDiv(p.speed, p.mo.scale)
	if speed > MINSPEED
	and p.cmd.buttons & BT_SPIN
	and P_IsObjectOnGround(p.mo)
	and not p.mo.metalsonic.drift then
		p.mo.metalsonic.drift = true
	end

	if not p.mo.metalsonic.drift then
		return
	end

	if not (p.cmd.buttons & BT_SPIN)
	and p.mo.metalsonic.drifthold
	or not P_IsObjectOnGround(p.mo)
	or speed < MINSPEED then
		p.mo.rollangle = 0
		p.pflags = $&~PF_SPINNING

		if P_IsObjectOnGround(p.mo) then
			p.mo.state = S_PLAY_WALK
		elseif p.mo.state ~= S_PLAY_SPRING
		and p.mo.state ~= S_PLAY_ROLL then
			p.mo.state = S_PLAY_FALL
		end

		if S_SoundPlaying(p.mo, sfx_msdrft)
			S_StopSoundByID(p.mo, sfx_msdrft)
		end

		DriftDisable(p)
		return
	end

	local sidemove = 0
	if abs(p.cmd.sidemove) > 12 then
		sidemove = p.cmd.sidemove*FU/50
	end

	if sidemove then
		if not p.mo.metalsonic.drifthold then
			p.mo.metalsonic.da = R_PointToAngle2(0,0, p.rmomx, p.rmomy)
			p.mo.metalsonic.speed = speed*13/14 --small start punishment
			p.mo.metalsonic.drifthold = true
		end

		p.mo.metalsonic.da = $ - FixedMul(max((DTS - (ANG1 * (speed/FU/10))), ANG2), sidemove)
		p.mo.state = S_PLAY_SPINDASH
		p.mo.rollangle = 0 - FixedMul(ANGLE_22h, sidemove)
		p.drawangle = p.mo.metalsonic.da - FixedMul(ANGLE_22h, sidemove)
	
		p.mo.metalsonic.speed = $ - (DSLOT/12)

		if p.mo.metalsonic.speed > DSMAX then
			p.mo.metalsonic.speed = $ - DSLOT
		end
		P_InstaThrust(p.mo, p.mo.metalsonic.da, FixedMul(p.mo.metalsonic.speed, p.mo.scale))

		local dust = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_SPINDUST)
		dust.fuse = 5

		if not S_SoundPlaying(p.mo, sfx_msdrft)
			S_StartSoundAtVolume(p.mo, sfx_msdrft, 200)
		end
	else
		if p.mo.metalsonic.drifthold then
			p.drawangle = p.mo.metalsonic.da
			p.mo.state = S_PLAY_ROLL
			p.mo.rollangle = 0
		end

		p.mo.metalsonic.drifthold = false

		if S_SoundPlaying(p.mo, sfx_msdrft)
			S_StopSoundByID(p.mo, sfx_msdrft)
		end
	end
end

addHook("PlayerThink", function(p)
	if not Valid(p) then
		p.mo.metalsonic = nil
		return
	end

	p.dashmode = 0

	if not p.mo.metalsonic then
		p.mo.metalsonic = {
			dmt = 0,
			drift = false,
			drifthold = false,
			da = 0,
			speed = 0,
			dmspeed = DMBASESPEED,
			airdash = false,
			adp = 0,
			sspd = 0
		}
	end

	DashModeTick(p)
	AirDashTick(p)
	DriftTick(p)
end)

addHook("MobjDamage", function(mo)
	if not Valid(mo.player) then return end
	if not mo.player.metalsonic then return end

	DashModeDisable(mo.player)
	AirDashDisable(mo.player)
	DriftDisable(mo.player)
end, MT_PLAYER)

addHook("JumpSpinSpecial", function(p)
	if not Valid(p) then return end
	if p.pflags & PF_THOKKED then return end
	if p.mo.state == S_PLAY_PAIN
	or p.mo.state == S_PLAY_DEAD then return end
	if (p.lastbuttons & BT_SPIN) then return end

	p.mo.metalsonic.airdash = true
	p.mo.metalsonic.sspd = p.speed
	p.pflags = $|PF_THOKKED&~PF_SPINNING
	S_StartSoundAtVolume(p.mo, sfx_cdfm35, 150)
end)