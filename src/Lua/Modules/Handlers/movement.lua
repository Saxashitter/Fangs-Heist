local WALK_SPEED = 16*FU
local RUN_SPEED = 32*FU
local RUN_ANIM = 25*FU
local RUN_SLOWDOWN = 20
local ACCEL_SPEED = FU/12
local RUN_PREP = 8

local module = {}

local customMovement = CV_RegisterVar({
	name = "fh_custommovement",
	defaultvalue = "DefaultCast",
	flags = CV_NETVAR,
	PossibleValue = {Off = 0, On = 1, DefaultCast = 2}
})

local function L_TurnAngle(oldangle, newangle, factor) // FUNCTION BY CLAIREBUN!
	factor = $ or FRACUNIT/8
	return oldangle + FixedMul(newangle-oldangle,factor)
end

module.supportedSkins = {
	sonic = true,
	tails = true,
	knuckles = true,
	amy = true,
	fang = true,
	metalsonic = true
}

function module.canDoMovement(p)
	if not (p.mo and p.mo.health and not P_PlayerInPain(p) and not (p.powers[pw_carry]) and p.heist) then
		return false
	end

	if customMovement.value == 0 then
		return false
	end

	if customMovement.value == 2
	and not (module.supportedSkins[p.mo.skin]) then
		return false
	end

	return true
end

local function player_moveangle(p)
	local forwardmove = p.cmd.forwardmove
	local sidemove = p.cmd.sidemove
	local camera_angle = (p.cmd.angleturn<<16)
	local controls_angle = R_PointToAngle2(0,0, forwardmove*FU, -sidemove*FU)

	return camera_angle+controls_angle
end

local function approach(from, to, by)
	if from > to then
		return max(from-by, to)
	end

	return min(from+by, to)
end

local function init(p)
	local move = {}

	move.momx = 0
	move.momy = 0
	move.run = false
	move.runangle = 0
	move.runslow = 0
	move.runstart = RUN_PREP
	move.walkframe = -1
	move.jump = false

	p.heist.move = move
end

for i = 1,4 do
	sfxinfo[freeslot("sfx_fhwlk"..i)].caption = "Step"
end

local function manage_footsteps(p)
	if (p.mo.state ~= S_PLAY_WALK
	and p.mo.state ~= S_PLAY_RUN)
	or not P_IsObjectOnGround(p.mo) then
		p.heist.move.walkframe = -1
		return
	end

	local frame = p.mo.frame & FF_FRAMEMASK
	local maxframes = skins[p.mo.skin].sprites[p.mo.sprite2].numframes

	if p.heist.move.walkframe ~= frame
	and (frame == 0 or frame == maxframes/2) then
		S_StartSound(p.mo, sfx_fhwlk1)
	end

	p.heist.move.walkframe = frame
end

local function walk(p)
	local angle = player_moveangle(p)
	local m = p.heist.move

	p.camerascale = ease.linear(FU/10, $, FU)

	if p.cmd.sidemove or p.cmd.forwardmove then
		local speedx = P_ReturnThrustX(p.mo, angle, WALK_SPEED)
		local speedy = P_ReturnThrustY(p.mo, angle, WALK_SPEED)
	
		p.drawangle = angle
		p.heist.move.momx = ease.linear(ACCEL_SPEED, $, speedx)
		p.heist.move.momy = ease.linear(ACCEL_SPEED, $, speedy)
	else
		p.heist.move.momx = ease.linear(ACCEL_SPEED, $, 0)
		p.heist.move.momy = ease.linear(ACCEL_SPEED, $, 0)

		if FixedHypot(p.heist.move.momx, p.heist.move.momy) < 5*p.mo.scale then
			p.heist.move.momx = 0
			p.heist.move.momy = 0
		end
	end

	p.mo.momx = p.cmomx+p.heist.move.momx
	p.mo.momy = p.cmomy+p.heist.move.momy
	P_MovePlayer(p)
end

local function run(p)
	local m = p.heist.move
	p.camerascale = ease.linear(FU/10, $, FU*2)

	if p.cmd.sidemove or p.cmd.forwardmove then
		local turn = player_moveangle(p)

		m.runangle = L_TurnAngle($, turn, FU/70)
	end

	m.momx = P_ReturnThrustX(p.mo, m.runangle, RUN_SPEED)
	m.momy = P_ReturnThrustY(p.mo, m.runangle, RUN_SPEED)

	p.mo.momx = p.cmomx+p.heist.move.momx
	p.mo.momy = p.cmomy+p.heist.move.momy
	P_MovePlayer(p)
	p.drawangle = m.runangle
end

local function runprep(p)
	local m = p.heist.move

	m.momx = -6*cos(p.drawangle)
	m.momy = -6*sin(p.drawangle)

	m.runstart = max(0, $-1)

	p.mo.momx = p.cmomx+p.heist.move.momx
	p.mo.momy = p.cmomy+p.heist.move.momy
	P_MovePlayer(p)
end

local function runslow(p)
	local m = p.heist.move

	m.momx = 4*cos(p.drawangle)
	m.momy = 4*sin(p.drawangle)

	m.runslow = max(0, $-1)

	p.mo.momx = p.cmomx+p.heist.move.momx
	p.mo.momy = p.cmomy+p.heist.move.momy
	P_MovePlayer(p)
end

function module.runMovement(p)
	if not module.canDoMovement(p) then
		if p.heist then
			p.heist.move = nil
		end
		return
	end

	if not (p.heist.move) then
		init(p)
	end

	local m = p.heist.move

	p.charability = CA_NONE
	p.charability2 = CA2_NONE
	p.charflags = 0
	p.powers[pw_noautobrake] = 2
	p.jumpfactor = FU
	p.runspeed = RUN_ANIM

	if p.pflags & PF_JUMPED
	and p.pflags & PF_STARTJUMP then
		p.heist.move.jump = true
	elseif not (p.pflags & PF_JUMPED
	and p.pflags & PF_STARTJUMP)
	and p.heist.move.jump then
		p.heist.move.jump = false

		if p.pflags & PF_JUMPED
		and not P_IsObjectOnGround(p.mo)
		and p.mo.momz > 0 then
			p.mo.momz = 0
		end
	end

	local runPress = (p.cmd.buttons & BT_SPIN)

	if not m.run
	and P_IsObjectOnGround(p.mo)
	and runPress then
	-- and not (m.runslow) then
		m.run = true
		m.runangle = R_PointToAngle2(0,0,p.mo.momx,p.mo.momy)
	end

	if m.run
	and P_IsObjectOnGround(p.mo)
	and not runPress then
	-- and not (m.runstart) then
		m.run = false
		m.runslow = RUN_SLOWDOWN
		m.runstart = RUN_PREP
	end

	manage_footsteps(p)

	if not m.run then
		--[[if m.runslow then
			runslow(p)
			return
		end]]

		p.powers[pw_strong] = 0
		walk(p)
		return
	end

	--[[if m.runstart then
		runprep(p)
		return
	end]]

	p.powers[pw_strong] = STR_ATTACK|STR_BUST
	run(p)
end

-- spring check by marilyn
function module.springCols(mo, spring)
	if not (mo and mo.valid) then return end
	if not mo.health then return end
	if not (mo.player and mo.player.heist and mo.player.heist.move) then return end
	if not (spring and spring.valid) then return end
	if mo.z + mo.height < spring.z or spring.z + spring.height < mo.z then return end  
	if not (spring.flags & MF_SPRING) then return end

	local horiz = false
	local verti = false

	if spring.type ~= MT_YELLOWSPRING
	and spring.type ~= MT_REDSPRING
	and spring.type ~= MT_BLUESPRING then
		horiz = true
	end
	
	if spring.type ~= MT_YELLOWHORIZ
	and spring.type ~= MT_REDHORIZ
	and spring.type ~= MT_BLUEHORIZ then
		verti = true
	end

	if horiz then
		local m = mo.player.heist.move

		local speed = RUN_SPEED
		if verti then
			speed = WALK_SPEED
		end

		m.momx = FixedMul(speed, cos(spring.angle))
		m.momy = FixedMul(speed, sin(spring.angle))
		m.runangle = spring.angle
	end
end

return module