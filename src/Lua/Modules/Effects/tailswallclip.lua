local TailsWallClip = {}

local CIRC_TICS = 14
local CIRC_SCALE_TICS = 6
local CIRC_ALPHA_TICS = 9
local CIRC_START_SCALE = tofixed("1")
local CIRC_START_ALPHA = tofixed("1")
local CIRC_END_SCALE = tofixed("0.65")

local DUST_DELAY = 5
local DUST_RANGE = 24
local DUST_ANGLE_RANGE = 45

local function GetLineAngle(mo, line)
	local dir = ANGLE_90
	local side = P_PointOnLineSide(mo.x, mo.y, line)

	if side then
		dir = -$
	end

	return R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y) + dir
end

local function SpawnDust(self, mo)
	local rx = P_RandomRange(-DUST_RANGE, DUST_RANGE)*FU
	local ry = P_RandomRange(-DUST_RANGE, DUST_RANGE)*FU
	local ra = mo.player.drawangle - FixedAngle(P_RandomRange(-DUST_ANGLE_RANGE, DUST_ANGLE_RANGE)*FU)

	local d = P_SpawnMobjFromMobj(mo, rx, ry, 0, MT_THOK)

	d.state = S_DUST1
	P_InstaThrust(d, ra, 4*FU)
	d.momz = mo.momz - 3*d.scale
end

function TailsWallClip:new(p, line)
	local px, py = P_ClosestPointOnLine(p.mo.x, p.mo.y, line)
	local angle = GetLineAngle(p.mo, line)

	local e = P_SpawnMobj(px + P_ReturnThrustX(nil, angle, -FU), py + P_ReturnThrustY(nil, angle, -FU), p.mo.z, MT_THOK)
	e.state = S_FACESTABBERSPEAR
	e.tics = -1
	e.color = SKINCOLOR_WHITE
	e.colorized = true
	e.frame = A
	e.renderflags = RF_PAPERSPRITE
	e.angle = angle - ANGLE_90
	e.blendmode = AST_ADD
	e.scale = CIRC_START_SCALE
	e.destscale = CIRC_START_SCALE
	e.alpha = CIRC_START_ALPHA
	e.flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY

	self.circ = e
	self.tics = 0
	self.player = p
end

function TailsWallClip:tick()
	self.tics = $+1

	local p = self.player
	local alive = p
		and p.valid
		and p.heist
		and p.heist:isAlive()
		and p.mo.tails
		and p.mo.tails.walljump

	if self.tics > CIRC_TICS then
		if self.circ and self.circ.valid then
			P_RemoveMobj(self.circ)
			self.circ = nil
		end

		if not alive then
			return true
		end
	elseif self.circ and self.circ.valid then
		local t = FixedDiv(self.tics, CIRC_TICS)
		local at = FixedDiv(max(0, self.tics - CIRC_TICS + CIRC_ALPHA_TICS), CIRC_ALPHA_TICS)
		local st = FixedDiv(min(self.tics, CIRC_SCALE_TICS), CIRC_SCALE_TICS)

		self.circ.scale = ease.outquad(st, CIRC_START_SCALE, CIRC_END_SCALE)
		self.circ.alpha = ease.outquad(at, CIRC_START_ALPHA, 0)
	end

	if not alive then return end

	if not (self.tics % DUST_DELAY) then
		SpawnDust(self, p.mo)
	end
end

function TailsWallClip:kill()
	if self.circ and self.circ.valid then
		P_RemoveMobj(self.circ)
		self.circ = nil
	end
end

return TailsWallClip