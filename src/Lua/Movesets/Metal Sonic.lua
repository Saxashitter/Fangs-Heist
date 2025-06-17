-- Constants
local DASH_TICS = TICRATE
local DASH_COLORMODULO = 3
local DASH_DRIFTTICS = 17
local DASH_DRIFTFRICTION = tofixed("0.68")

local FLOAT_TICS = TICRATE

-- Functions
local function Valid(p)
	return FangsHeist.isMode()
	and p.mo
	and p.mo.valid
	and p.mo.skin == "metalsonic"
end

local function HasControl(p, noStasis)
	if not noStasis then
		if p.pflags & PF_STASIS then return false end
		if p.pflags & PF_FULLSTASIS then return false end
		if p.powers[pw_nocontrol] then return false end
	end

	if p.pflags & PF_SLIDING then return false end
	if P_PlayerInPain(p) then return false end
	if p.mo.health <= 0 then return false end

	return true
end

local function IsMovementState(state)
	return state == S_PLAY_WALK or state == S_PLAY_RUN
end

-- Dash Mode
local function InitDashMode(p)
	local dash = {}
	dash.tics = 0

	p.mo.metaldash = dash
end

local function StartDashMode(p)
	local dash = p.mo.metaldash
	local skin = skins[p.mo.skin]

	S_StartSound(p.mo, sfx_s3ka2)
end

local function StopDashMode(p)
	local dash = p.mo.metaldash
	local skin = skins[p.mo.skin]
	local dashing = dash.tics >= DASH_TICS

	dash.tics = 0

	if not dashing then
		return
	end

	S_StartSound(p.mo, sfx_kc65)
	p.mo.color = p.skincolor
end

local function ManageDashMode(p)
	local skin = skins[p.mo.skin]

	if not p.mo.metaldash then
		InitDashMode(p)
	end

	local dash = p.mo.metaldash

	local speed = R_PointToDist2(0,0,p.rmomx,p.rmomy)
	local runspeed = FixedMul(skin.runspeed, p.mo.scale)

	if (speed < runspeed and P_IsObjectOnGround(p.mo))
	or not HasControl(p) then
		if dash.tics then
			StopDashMode(p)
		end

		return
	end

	if P_IsObjectOnGround(p.mo)
	or dash.tics >= DASH_TICS then
		dash.tics = $+1
	end

	if dash.tics < DASH_TICS then
		return
	end

	if dash.tics == DASH_TICS then
		StartDashMode(p)
	end

	if P_IsObjectOnGround(p.mo)
	and IsMovementState(p.mo.state) then
		p.mo.state = S_PLAY_DASH
	end

	local tics = dash.tics - DASH_TICS
	local modulo = (tics/DASH_COLORMODULO) % 2

	if modulo then
		p.mo.color = SKINCOLOR_WHITE
	else
		p.mo.color = p.skincolor
	end

	local ghost = P_SpawnGhostMobj(p.mo)

	ghost.fuse = 3
	ghost.translation = "FH_ParryColor"
	ghost.momz = (8*ghost.scale)*P_MobjFlip(ghost)
end

local function DashPriority(self, p)
	if not Valid(p)
	or not p.mo.metaldash then
		return
	end

	local dash = p.mo.metaldash

	if dash.tics >= DASH_TICS then
		return 3
	end
end

-- Drifting
local function DoDrift(p)
	local mo = p.mo

	mo.state = S_FH_MS_DRIFT
	mo.metaldrift = true
	mo.color = p.skincolor

	mo.metaldrift_tics = DASH_DRIFTTICS
	mo.metaldrift_angle = p.drawangle
	mo.metaldrift_moveangle = R_PointToAngle2(0,0, p.rmomx, p.rmomy)
	mo.metaldrift_speed = R_PointToDist2(0,0, p.rmomx, p.rmomy)

	S_StartSound(mo, sfx_skid)
	S_StartSound(mo, sfx_alart)
end

local function ManageDrift(p)
	local skin = skins[p.mo.skin]

	p.pflags = $|PF_JUMPSTASIS

	p.mo.metaldrift_tics = max(0, $-1)
	p.drawangle = p.mo.metaldrift_angle

	P_InstaThrust(p.mo, p.mo.metaldrift_moveangle, p.mo.metaldrift_speed)
	p.mo.metaldrift_speed = max(6*p.mo.scale, $ - 2*p.mo.scale)

	if p.mo.metaldrift_tics > 0
	or not P_IsObjectOnGround(p.mo) then
		return
	end

	p.pflags = $ & ~PF_JUMPSTASIS
	local angle = p.cmd.angleturn << 16

	if p.cmd.sidemove
	or p.cmd.forwardmove then
		angle = $ + R_PointToAngle2(0,0, p.cmd.forwardmove*FU, -p.cmd.sidemove*FU)
	end

	p.drawangle = angle

	P_InstaThrust(p.mo, angle, skin.normalspeed)
	P_MovePlayer(p)

	p.mo.state = S_PLAY_DASH

	p.mo.metaldrift_tics = nil
	p.mo.metaldrift_angle = nil
	p.mo.metaldrift_speed  = nil
	p.mo.metaldrift_moveangle = nil
	p.mo.metaldrift = nil

	S_StartSound(p.mo, sfx_zoom)
	S_StartSound(p.mo, sfx_thok)
	S_StartSound(p.mo, sfx_s3ka2)
end

-- Hooks
addHook("PlayerThink", function(p)
	if not Valid(p) then
		if p.mo
		and p.mo.valid then
			p.mo.metaldash = nil
			p.mo.metaldrift_tics = nil
			p.mo.metaldrift_angle = nil
			p.mo.metaldrift_speed  = nil
			p.mo.metaldrift_moveangle = nil
			p.mo.metaldrift = nil
		end

		return
	end

	if p.mo.metaldrift
	and HasControl(p, true) then
		ManageDrift(p)
		return
	end

	p.mo.metaldrift = nil
	p.mo.metaldrift_tics = nil
	p.mo.metaldrift_angle = nil
	p.mo.metaldrift_speed  = nil
	p.mo.metaldrift_moveangle = nil

	ManageDashMode(p)
end)

addHook("ThinkFrame", function(p)
	for p in players.iterate do
		if not Valid(p) then
			continue
		end

		if not p.mo.metaldrift 
		or not p.mo.metaldash then
			p.mo.mds_tics = nil
			p.mo.mds_frame = nil
			continue
		end

		if p.mo.state ~= S_FH_MS_DRIFT then
			p.mo.state = S_FH_MS_DRIFT
			p.mo.tics = p.mo.mds_tics or $
			p.mo.frame = ($ & ~FF_FRAMEMASK)|(p.mo.mds_frame or ($ & FF_FRAMEMASK))
		end

		p.mo.mds_tics = p.mo.tics
		p.mo.mds_frame = p.mo.frame & FF_FRAMEMASK
	end
end)

addHook("SpinSpecial", function(p)
	if not Valid(p)
	or not p.mo.metaldash
	or p.pflags & PF_SPINDOWN then
		return
	end

	local dash = p.mo.metaldash

	if P_IsObjectOnGround(p.mo)
	and dash.tics >= DASH_TICS
	and not p.mo.metaldrift then
		DoDrift(p)
		return true
	end

	if p.mo.metaldrift then
		return true
	end
end)

addHook("PlayerCanDamage", function(p)
	if not Valid(p)
	or not p.mo.metaldash then
		return
	end

	local dash = p.mo.metaldash

	if dash.tics >= DASH_TICS then
		return true
	end
end)

FangsHeist.makeCharacter("metalsonic", {
	pregameBackground = "FH_PREGAME_METAL",
	attackPriority = DashPriority
})