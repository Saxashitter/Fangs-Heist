local TailsDoubleJump = {}

local TICS = 18
local ALPHA_TICS = 8
local START_RADIUS = 16*FU
local END_RADIUS = 96*FU
local AMOUNT = 16

function TailsDoubleJump:new(p)
	self.player = p
	self.tics = 0
	self.dust = {}
	for i = 1, AMOUNT do
		local a = p.drawangle - FixedAngle((360*FU/AMOUNT)*(i-1))

		local x = P_ReturnThrustX(nil, a, START_RADIUS)
		local y = P_ReturnThrustY(nil, a, START_RADIUS)

		local d = P_SpawnMobjFromMobj(p.mo, x, y, 0, MT_THOK)

		d.ox = d.x
		d.oy = d.y
		d.oz = d.z
		d.tx = d.ox + P_ReturnThrustX(nil, a, END_RADIUS)
		d.ty = d.oy + P_ReturnThrustY(nil, a, END_RADIUS)
		d.tz = d.z

		d.momx = 0
		d.momy = 0
		d.momz = 0
		d.state = S_DUST1
		d.angle = a
		d.tics = -1
		d.flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY

		table.insert(self.dust, d)
	end
end

function TailsDoubleJump:tick()
	self.tics = $+1

	if self.tics > TICS then
		return true
	end

	local alphaTics = max(0, self.tics + ALPHA_TICS - TICS)

	local t = FixedDiv(self.tics, TICS)
	local a = ease.linear(FixedDiv(alphaTics, ALPHA_TICS), FU, 0)

	for k,d in ipairs(self.dust) do
		if not (d and d.valid) then continue end

		local x = ease.outquad(t, d.ox, d.tx)
		local y = ease.outquad(t, d.oy, d.ty)
		local z = ease.outquad(t, d.oz, d.tz)

		P_MoveOrigin(d, x, y, z)
		d.alpha = a
	end
end

function TailsDoubleJump:kill()
	for k,d in ipairs(self.dust) do
		if not (d and d.valid) then continue end
		P_RemoveMobj(d)
	end
end

return TailsDoubleJump