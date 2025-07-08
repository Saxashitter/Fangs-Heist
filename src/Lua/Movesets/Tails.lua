FangsHeist.makeCharacter("tails", {
	pregameBackground = "FH_PREGAME_TAILS"
})

local FLY_WINDUP_FRICTION = tofixed("0.896")

local FLY_TICS = 40
local FLY_MOM = 24
local FLY_GRAVITY = FU/2

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

	if not P_LineIsBlocking(p.mo, line)
	or not p.mo.tails.walljump_tics then
		DisableWallJump(p, true)
		return
	end

	p.drawangle = FixedAngle(AngleFixed(angle) + 180*FU)
	if p.mo.state ~= S_PLAY_FALL then
		p.mo.state = S_PLAY_FALL
	end

	P_InstaThrust(p.mo, angle, FU)

	if p.mo.momz*P_MobjFlip(p.mo) <= -4*p.mo.scale then
		P_SetObjectMomZ(p.mo, -4*p.mo.scale)
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

	if p.mo.tails.walljump then
		StickToWall(p)
	end
end)

addHook("MobjMoveBlocked", function(mo, _, line)
	if not Valid(mo.player) then return end
	if not (line and line.valid) then return end

	local p = mo.player
	local tails = p.mo.tails

	if P_IsObjectOnGround(mo) then return end
	if not (p.pflags & PF_JUMPED) then return end
	if (p.pflags & PF_THOKKED) then return end
	if tails.walljump then return end

	tails.walljump = line
	tails.walljump_tics = TICRATE
	p.pflags = ($|PF_THOKKED) & ~(PF_STARTJUMP|PF_JUMPED|PF_STARTJUMP)

	local momz = p.mo.momz*P_MobjFlip(p.mo)
	p.mo.momz = max(momz, momz*3/2)

	FangsHeist.Particles:new("Tails Wall Clip", p, line)
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

	if p.mo.tails.walljump then
		p.drawangle = GetLineAngle(p.mo, p.mo.tails.walljump) + ANGLE_180
		p.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP|PF_STARTDASH|PF_SPINNING|PF_THOKKED)
		P_DoJump(p)
		P_InstaThrust(p.mo, p.drawangle, 19*p.mo.scale)
		p.mo.state = S_PLAY_SPRING
		DisableWallJump(p)
		return
	end

	if p.pflags & PF_THOKKED then
		return
	end

	-- double jump

	p.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP|PF_STARTDASH|PF_SPINNING)
	P_DoJump(p)
	p.pflags = $|PF_THOKKED
	p.mo.state = S_PLAY_SPRING
	FangsHeist.Particles:new("Tails Double Jump", p)
end)