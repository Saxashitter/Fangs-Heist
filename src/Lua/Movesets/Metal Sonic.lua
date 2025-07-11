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

//MINIMUN SPEED FOR DRIFT!
local MINSPEED = FU * 15

//It's easy to comprehend.
local DASHMODETICS = 90

//Minimum speed for getting dash mode!
local MINDASHMODE = 26 * FU

//Drift speed loss over time! 
local DSLOT = FU / 8
local DSMAX = FU * 46

local DMBASESPEED = 36 * FU
local DMSPEEDUP = FU/8
local DMMAXSPEED = 46 * FU

local AIRDASHSPEED = 15 * FU

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
	and p.speed < MINDASHMODE)
	or P_PlayerInPain(p)
	or not (p.mo and p.mo.health) then
		DashModeDisable(p)
		return
	end

	p.mo.metalsonic.dmt = $ + 1
	if p.mo.metalsonic.dmt > DASHMODETICS then
		p.mo.metalsonic.dmspeed = min($ + DMSPEEDUP, DMMAXSPEED)
		p.normalspeed = p.mo.metalsonic.dmspeed

		if p.mo.state == S_PLAY_RUN then
			p.mo.state = S_PLAY_DASH
		end

		if leveltime%4 < 2 then
			p.mo.color = skincolors[p.skincolor].invcolor
		else
			p.mo.color = p.skincolor + leveltime%2
			p.normalspeed = skins[p.mo.skin].normalspeed
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
		p.mo.momx = 0
		p.mo.momy = 0
		p.mo.momz = (FU/2) * P_MobjFlip(p.mo)
		p.pflags = $&~PF_JUMPED&~PF_SPINNING
	end
	if p.mo.metalsonic.adp == 7 then
		local dust = P_SpawnGhostMobj(p.mo)
		dust.fuse = 99999
		dust.state = S_X3UPDASH
		dust.scale = (FU * 2) + (FU/2)
		S_StartSound(p.mo, sfx_msupds)
	end
	if p.mo.metalsonic.adp > 7 then
		p.mo.momz = (AIRDASHSPEED * P_MobjFlip(p.mo))
		p.mo.state = S_PLAY_SPRING
	end
	if p.mo.metalsonic.adp > 24 or not (p.cmd.buttons & BT_SPIN) then
		AirDashDisable(p)
		p.mo.state = S_PLAY_FALL
		p.mo.momz = $/3
		p.mo.momx = FixedMul(p.mo.metalsonic.sspd, cos(p.drawangle))/(1 + (p.mo.metalsonic.adp / 6))
		p.mo.momy = FixedMul(p.mo.metalsonic.sspd, sin(p.drawangle))/(1 + (p.mo.metalsonic.adp / 6))
	end
end

local function DriftTick(p)
	if p.speed > MINSPEED
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
	or p.speed < MINSPEED then
		p.mo.rollangle = 0
		p.pflags = $&~PF_SPINNING

		if P_IsObjectOnGround(p.mo) then
			p.mo.state = S_PLAY_WALK
		elseif p.mo.state ~= S_PLAY_SPRING
		and p.mo.state ~= S_PLAY_ROLL then
			p.mo.state = S_PLAY_FALL
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
			p.mo.metalsonic.speed = p.speed
			p.mo.metalsonic.drifthold = true
		end

		p.mo.metalsonic.da = $ - FixedMul(max((DTS - (ANG1 * (p.speed/FU/10))), ANG2), sidemove)
		p.mo.state = S_PLAY_SPINDASH
		p.mo.rollangle = 0 - FixedMul(ANGLE_22h, sidemove)
		p.drawangle = p.mo.metalsonic.da - FixedMul(ANGLE_22h, sidemove)
	
		P_InstaThrust(p.mo, p.mo.metalsonic.da, p.mo.metalsonic.speed)
		p.mo.metalsonic.speed = $ - (DSLOT/12)

		if p.mo.metalsonic.speed > DSMAX then
			p.mo.metalsonic.speed = $ - DSLOT
		end

		local dust = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_SPINDUST)
		dust.fuse = 5
	else
		if p.mo.metalsonic.drifthold then
			p.drawangle = p.mo.metalsonic.da
			p.mo.state = S_PLAY_ROLL
			p.mo.rollangle = 0
		end

		p.mo.metalsonic.drifthold = false
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
end)