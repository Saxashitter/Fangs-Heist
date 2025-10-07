--did you guys not actually add this?
FangsHeist.makeCharacter("metalsonic", {pregameBackground = "FH_PREGAME_METAL"})

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
local DASHMODETICS = 35*2

//Minimum speed for getting dash mode!
local MINDASHMODE = 26 * FU

//Drift speed loss over time! 
local DSLOT = FU / 5
local DSMAX = FU * 46

local DMBASESPEED = 36 * FU
local DMSPEEDUP = FU/8
local DMMAXSPEED = 46 * FU

local AIRDASHSPEEDZ = 0
local AIRDASHSPEEDXY = 30 * FU

local DASHFLAGS = STR_WALL|STR_CEILING|STR_SPIKE|STR_ATTACK

local MetalSlams = {}
addHook("NetVars", function(sync)
	MetalSlams = sync($)
end)

local function Valid(p)
	return FangsHeist.isMode(p)
	and p
	and p.valid
	and p.heist
	and p.heist:isAlive()
	and p.mo
	and p.mo.valid
	and p.mo.skin == "metalsonic"
end

local function SlamValid(p)
	return p
	and p.valid
	and p.heist
	and p.heist:isAlive()
	and p.mo
	and p.mo.valid
end

local function DashModeDisable(p)
	if not p.mo.metalsonic.dmt then return end

	p.mo.metalsonic.dmt = 0
	p.mo.color = p.skincolor
	p.mo.metalsonic.dmspeed = DMBASESPEED
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

local function IsSlamming(p)
	for k,v in ipairs(MetalSlams) do
		if v.player == p then
			return v
		end
	end

	return false
end

local function IsSlamTarget(mo)
	for k,v in ipairs(MetalSlams) do
		if v.mobj == mo then
			return v
		end
	end

	return false
end

local function StopSlam(k)
	if type(k) ~= "number" then
		for key,v in ipairs(MetalSlams) do
			if v == k then
				k = key
				break
			end
		end
	end

	local slam = MetalSlams[k]
	if Valid(slam.player) then
		slam.player.powers[pw_strong] = $ & ~STR_HEAVY
	end
	table.remove(MetalSlams, k)
end

local function StartSlam(p, mobj)
	p.powers[pw_strong] = $|STR_HEAVY
	DashModeDisable(p)
	AirDashDisable(p)
	DriftDisable(p)

	P_SetObjectMomZ(p.mo, 10*p.mo.scale)

	table.insert(MetalSlams, {
		player = p,
		mobj = mobj,
		tics = 0
	})
end

local function DashModeTick(p)
	if (P_IsObjectOnGround(p.mo)
	and FixedDiv(R_PointToDist2(0,0, p.rmomx, p.rmomy), p.mo.scale) < MINDASHMODE)
	or P_PlayerInPain(p)
	or not (p.mo and p.mo.health) then
		if p.mo
		and p.mo.health
		and p.mo.metalsonic.dmt >= DASHMODETICS then
			S_StartSound(p.mo, sfx_kc65)
		end

		DashModeDisable(p)
		return
	end

	if P_IsObjectOnGround(p.mo)
	and not p.mo.metalsonic.drift then
		p.mo.metalsonic.dmt = $ + 1
	
		if p.mo.metalsonic.dmt == DASHMODETICS+1 then
			S_StartSound(p.mo, sfx_cdfm40)
		end
	end

	if p.mo.metalsonic.dmt > DASHMODETICS then
		p.powers[pw_strong] = $|DASHFLAGS
		p.mo.metalsonic.dmspeed = min($ + DMSPEEDUP, DMMAXSPEED)

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
		p.mo.metalsonic.adthrust = p.mo.angle
		S_StartSound(p.mo, sfx_msupds)
	end

	if p.mo.metalsonic.adp >= 7 then
		P_SetObjectMomZ(p.mo, AIRDASHSPEEDZ)
		P_InstaThrust(p.mo, p.mo.metalsonic.adthrust, AIRDASHSPEEDXY)
		p.mo.state = S_PLAY_DASH
		p.drawangle = p.mo.metalsonic.adthrust
	end

	if p.mo.metalsonic.adp > 24 or not (p.cmd.buttons & BT_SPIN) then
		AirDashDisable(p)
		p.mo.state = S_PLAY_FALL
		p.mo.momz = $/3
	end
end

local function DriftTick(p)
	local speed = FixedDiv(p.speed, p.mo.scale)
	if speed > MINSPEED
	and p.cmd.buttons & BT_SPIN
	and P_IsObjectOnGround(p.mo)
	and p.pflags & PF_SPINNING
	and not p.mo.metalsonic.drift then
		p.mo.metalsonic.drift = true
		p.mo.metalsonic.speed = p.speed
	end

	if not p.mo.metalsonic.drift then
		return
	end

	if not (p.cmd.buttons & BT_SPIN)
	and p.mo.metalsonic.drifthold
	or not P_IsObjectOnGround(p.mo)
	or not (p.pflags & PF_SPINNING)
	or p.mo.metalsonic.speed == 0
	or speed < MINSPEED then
		p.mo.rollangle = 0
		p.pflags = $&~PF_SPINNING

		if P_IsObjectOnGround(p.mo) then
			p.mo.state = S_PLAY_WALK
		elseif p.mo.state ~= S_PLAY_SPRING
		and p.mo.state ~= S_PLAY_ROLL then
			p.mo.state = S_PLAY_FALL
		end

		if S_SoundPlaying(p.mo, sfx_msdrft) then
			S_StopSoundByID(p.mo, sfx_msdrft)
		end

		DriftDisable(p)
		return
	end

	local sidemove = 0
	if abs(p.cmd.sidemove) > 7 then
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
	
		p.mo.metalsonic.speed = max(0, $ - DSLOT)
		P_InstaThrust(p.mo, p.mo.metalsonic.da, FixedMul(p.mo.metalsonic.speed, p.mo.scale))

		local dust = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_SPINDUST)
		dust.fuse = 5

		if not S_SoundPlaying(p.mo, sfx_msdrft) then
			S_StartSoundAtVolume(p.mo, sfx_msdrft, 200)
		end
	else
		if p.mo.metalsonic.drifthold then
			p.drawangle = p.mo.metalsonic.da
			p.mo.state = S_PLAY_ROLL
			p.mo.rollangle = 0
		end

		p.mo.metalsonic.drifthold = false

		if S_SoundPlaying(p.mo, sfx_msdrft) then
			S_StopSoundByID(p.mo, sfx_msdrft)
		end
	end
end

local function SlamTick(slam)
	local p = slam.player
	local mobj = slam.mobj

	if not Valid(p) then
		return true
	end
	if not p.mo.metalsonic then return true end
	if not (mobj and mobj.valid and mobj.health) then
		return true
	end
	if mobj.type == MT_PLAYER
	and not SlamValid(mobj.player) then
		return true
	end

	local looptics = 24
	local t = FixedDiv(slam.tics % looptics, looptics)
	local angle = FixedAngle(360*t)

	local xy = FixedMul(p.mo.radius+mobj.radius, cos(angle))
	local z = FixedMul(p.mo.height/2+mobj.height, sin(angle))

	P_MoveOrigin(mobj,
		p.mo.x + P_ReturnThrustX(nil, p.drawangle, xy),
		p.mo.y + P_ReturnThrustY(nil, p.drawangle, xy),
		max(mobj.floorz, min(p.mo.z + p.mo.height/2 + z, mobj.ceilingz - mobj.height))
	)

	if mobj.type ~= MT_PLAYER then
		mobj.angle = p.drawangle
	elseif mobj.player then
		mobj.player.drawangle = p.drawangle
		mobj.state = S_PLAY_PAIN
	end

	slam.tics = $+1

	if P_IsObjectOnGround(p.mo) then
		P_SetOrigin(mobj, p.mo.x, p.mo.y, p.mo.z)
		p.mo.__forcedamage = true -- hax

		if mobj
		and mobj.valid
		and P_DamageMobj(mobj, p.mo, p.mo) then
			P_SetObjectMomZ(p.mo, 6*p.mo.scale)
		else
			p.powers[pw_flashing] = max($, TICRATE)
		end

		p.mo.__forcedamage = nil
		P_InstaThrust(p.mo, p.mo.angle, -6*p.mo.scale)
		P_SetObjectMomZ(p.mo, 5*p.mo.scale)
		p.mo.state = S_PLAY_FALL

		return true
	end
end

local function SlamPlayerTick(p)
	local slam = IsSlamming(p)

	if not slam then return end

	local gravity = P_GetMobjGravity(p.mo)
	local mo = slam.mobj

	p.pflags = $|PF_JUMPSTASIS
	p.mo.momz = $ - gravity + FixedMul(gravity, tofixed("2.25"))
	if p.mo.state ~= S_PLAY_ROLL then
		p.mo.state = S_PLAY_ROLL
	end
end

addHook("PlayerThink", function(p)
	if not Valid(p) then
		if p.mo and p.mo.valid then
			p.mo.metalsonic = nil
		end
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
	SlamPlayerTick(p)
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for k = #MetalSlams, 1, -1 do
		local v = MetalSlams[k]

		if SlamTick(v) then
			StopSlam(k)
			continue
		end
	end
end)

addHook("MobjDamage", function(mo)
	if not Valid(mo.player) then return end
	if not mo.metalsonic then return end

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

local function DashModeCollide(mo, target)
	if not Valid(mo.player) then return end
	if not target.valid then return end
	if not (target.flags & MF_ENEMY or target.type == MT_PLAYER) then return end
	if not mo.metalsonic then return end
	if not mo.metalsonic.airdash then return end
	if IsSlamming(mo.player) then return end
	if mo.z > target.z+target.height then return end
	if target.z > mo.z+mo.height then return end

	if target.type == MT_PLAYER
	and not SlamValid(target.player) then
		return
	end

	StartSlam(mo.player, target)
	return true
end

addHook("MobjCollide", DashModeCollide, MT_PLAYER)
addHook("MobjMoveCollide", DashModeCollide, MT_PLAYER)

addHook("ShouldDamage", function(mo, inf, target)
	if not Valid(mo.player) then return end
	if not mo.metalsonic then return end

	local slam = IsSlamming(mo.player)
	if not slam then return end

	if slam.mobj == inf then
		return false
	end
end, MT_PLAYER)
addHook("ShouldDamage", function(mo, _, target)
	if not mo.valid then return end

	local slam = IsSlamTarget(mo)
	if not slam then return end

	if not (target
	and target.valid
	and target.__forcedamage) then
		return false
	end
end)
