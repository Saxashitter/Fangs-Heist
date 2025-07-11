FangsHeist.makeCharacter("tails", {
	pregameBackground = "FH_PREGAME_TAILS"
})

local FLY_WINDUP_FRICTION = tofixed("0.896")

local FLY_TICS = 40
local FLY_MOM = 24
local FLY_GRAVITY = FU/2

local function Wrap(value, minValue, maxValue)
    local range = maxValue - minValue + 1
    return ((value - minValue) % range + range) % range + minValue
end

local function HasControl(p)
	if p.pflags & PF_STASIS then return false end
	if p.pflags & PF_FULLSTASIS then return false end
	if p.pflags & PF_SLIDING then return false end
	if p.powers[pw_nocontrol] then return false end
	if P_PlayerInPain(p) then return false end
	if not (p.mo.health) then return false end

	return true
end

local function Valid(p)
	return FangsHeist.isMode()
	and p
	and p.valid
	and p.heist
	and p.heist:isAlive()
	and p.mo.skin == "tails"
end

local function DisableWallJump(p, forced)
	if p.mo.momz*P_MobjFlip(p.mo) > 0 then
		p.mo.momz = $/2 -- no
	end

	p.mo.tails.walljump = nil
	p.mo.tails.walljump_tics = nil
end

local function GetLineAngle(mo, line)
	local dir = ANGLE_90
	local side = P_PointOnLineSide(mo.x, mo.y, line)

	if side then
		dir = -$
	end

	return R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y) + dir
end

local function StickToWall(p)
	local line = p.mo.tails.walljump
	local angle = GetLineAngle(p.mo, line)

	if p.mo.tails.walljump_tics then
		p.mo.tails.walljump_tics = $ - 1
	end

	if not p.mo.tails.walljump_tics
	or p.mo.state == S_FH_GUARD
	or p.mo.state == S_FH_STUN
	or p.mo.state == S_FH_CLASH then
		DisableWallJump(p, true)
		S_StartSoundAtVolume(p.mo, sfx_s1ab, 150)
		return
	end

	if P_IsObjectOnGround(p.mo) then
		DisableWallJump(p, true)
		return
	end

	p.drawangle = angle
	if p.mo.state ~= S_PLAY_CLING then
		p.mo.state = S_PLAY_CLING
	end

	local momz = p.mo.momz*P_MobjFlip(p.mo)

	if momz > 0 then
		p.mo.momz = FixedMul($, tofixed("0.82"))
	end

	if momz <= -2*p.mo.scale then
		P_SetObjectMomZ(p.mo, -2*p.mo.scale)
	end
end

addHook("PlayerSpawn", function(p)
	if not Valid(p) then
		return
	end

	p.mo.tails = {}
end)

addHook("PlayerThink", function(p)
	if not Valid(p) then
		if p.mo and p.mo.valid then
			p.mo.tails = nil
		end
		return
	end

	if not p.mo.tails then
		p.mo.tails = {}
	end

	if p.mo.tails.walljump_tics then
		StickToWall(p)
	end

	if p.mo.tails.doublejump_ticker then
		p.mo.tails.doublejump_ticker = $-1
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not Valid(p) then continue end

		if P_IsObjectOnGround(p.mo)
		and p.mo.tails then
			p.mo.tails.walljump_times = nil
			p.mo.tails.doublejump_times = nil
			p.mo.tails.doublejump_ticker = nil
		end
	end
end)

addHook("MobjMoveBlocked", function(mo, _, line)
	if not Valid(mo.player) then return end
	if not (line and line.valid) then return end

	local p = mo.player
	local tails = p.mo.tails

	if tails.walljump_times == 3 then return end
	if P_IsObjectOnGround(mo) then return end
	if not (p.pflags & PF_JUMPED) then return end
	if (p.pflags & PF_THOKKED) then return end
	if P_CheckSkyHit(mo, line) then return end
	if line.flags & ML_NOCLIMB then return end
	if mo.state == S_FH_GUARD
	or mo.state == S_FH_STUN
	or mo.state == S_FH_CLASH then
		return
	end

	if not tails.walljump_tics then
		local momz = p.mo.momz*P_MobjFlip(p.mo)
	
		local speed = R_PointToDist2(0,0, p.rmomx, p.rmomy)
		local speedang = R_PointToAngle2(0,0, p.rmomx, p.rmomy)
		local lineang = GetLineAngle(mo, line)
		local adiff = FixedAngle(
			AngleFixed(lineang) - AngleFixed(speedang)
		)
	
		if AngleFixed(adiff) > 180*FU then
			adiff = InvAngle($)
		end
	
		local mult = (180*FU - AngleFixed(adiff))/180
	
		P_SetObjectMomZ(mo, FixedMul(FixedMul(speed, tofixed("0.6")), mult), true)
		S_StartSound(mo, sfx_s3k4a)
		FangsHeist.Particles:new("Tails Wall Clip", p, line)
	end
	
	tails.walljump = line
	tails.walljump_tics = 7
end, MT_PLAYER)

addHook("MobjDamage", function(mo)
	if not Valid(mo.player) then return end

	mo.tails = {}
end, MT_PLAYER)

addHook("AbilitySpecial", function(p)
	if not Valid(p)
	or p.pflags & PF_JUMPDOWN then
		return
	end

	if p.mo.tails.walljump_tics then
		local angle = GetLineAngle(p.mo, p.mo.tails.walljump) + ANGLE_180
		DisableWallJump(p)

		p.drawangle = angle
		p.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP|PF_STARTDASH|PF_SPINNING|PF_THOKKED)
		P_DoJump(p, true)
		P_Thrust(p.mo, p.drawangle, 19*p.mo.scale)
		p.mo.state = S_PLAY_SPRING
		S_StartSoundAtVolume(p.mo, sfx_cdfm50, 150)

		p.mo.tails.doublejump_times = 1 -- only allow 2 double jump

		if not p.mo.tails.walljump_times then
			p.mo.tails.walljump_times = 0
		end

		p.mo.tails.walljump_times = $+1
		return
	end

	if p.pflags & PF_THOKKED then
		return
	end

	if p.mo.tails.doublejump_ticker then
		return
	end

	p.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP|PF_STARTDASH|PF_SPINNING)
	P_DoJump(p, false)
	P_SetObjectMomZ(p.mo, 9*p.jumpfactor)
	p.mo.state = S_PLAY_FLY
	FangsHeist.Particles:new("Tails Double Jump", p)

	S_StartSound(p.mo, sfx_tlfly1+(p.mo.tails.doublejump_times or 0))
	p.mo.tails.doublejump_times = ($ or 0) + 1
	p.mo.tails.doublejump_ticker = 10

	if p.mo.tails.doublejump_times == 3 then
		p.pflags = $|PF_THOKKED
	end
end)

addHook("FollowMobj", function(p, mo)
    if p.mo
    and p.mo.valid
    and p.mo.state == S_PLAY_CLING then
        local frontOffset = 0*p.mo.scale
        local zOffset = -3*p.mo.scale

        mo.state = S_TAILSOVERLAY_MINUS30DEGREES
        mo.angle = p.drawangle
        P_MoveOrigin(mo,
            p.mo.x + P_ReturnThrustX(nil, p.drawangle, frontOffset),
            p.mo.y + P_ReturnThrustY(nil, p.drawangle, frontOffset),
            p.mo.z + zOffset*P_MobjFlip(mo)
        )
        return true
    end
end, MT_TAILSOVERLAY)

FangsHeist.addPlayerScript("postthinkframe", function(p)
	if not Valid(p) then return end
	if not p.followmobj then return end
	if not p.followmobj.valid then return end

	if p.mo.state == S_PLAY_CLING then
		p.followmobj.state = S_TAILSOVERLAY_MINUS30DEGREES
		p.followmobj.frame = ($ & ~FF_FRAMEMASK)|Wrap(leveltime/3, A, G)
	end
end)