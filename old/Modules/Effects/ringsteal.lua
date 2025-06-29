local RingSteal = {}

local RING_OUT_TICS = 16
local RING_STILL_TICS = 8
local RING_IN_TICS = 18
local RING_DELAY = 2

local function RandomFixed(start, finish)
	return P_RandomRange(start/FU, finish/FU)*FU
end

function RingSteal:new(mo, tmo, rings)
	self.tmo = tmo

	self.tics = 0

	-- Spawn fake rings fron mobj.
	self.rings = {}

	for i = 1, rings do
		local speed = P_RandomRange(4, 16)
		local angle = FixedAngle(P_RandomRange(0, 359)*FU)
		local aiming = FixedAngle(P_RandomRange(-180, 180)*FU)

		local cosine = speed*cos(aiming)
		local sine = speed*sin(aiming)

		local ring = P_SpawnMobjFromMobj(mo,
			0,0,mo.height/2,
			MT_THOK)
		ring.fuse = -1
		ring.tics = -1
		ring.state = S_RING
		ring.frame = $|FF_TRANS60

		ring.start_position = {
			x = ring.x,
			y = ring.y,
			z = ring.z
		}
		ring.out_position = {
			x = ring.x+RandomFixed(-80*FU, 80*FU),
			y = ring.y+RandomFixed(-80*FU, 80*FU),
			z = ring.z+RandomFixed(0*FU, 80*FU)*P_MobjFlip(ring)
		}

		table.insert(self.rings, ring)
	end
end

function RingSteal:tick()
	if not self.tmo
	or not self.tmo.valid then
		return true
	end

	for i = #self.rings, 1, -1 do
		local ring = self.rings[i]

		if not ring.valid then
			table.remove(self.rings, i)
			continue
		end

		local still = RING_STILL_TICS + RING_DELAY*(i-1)
		local tics = self.tics

		if tics < RING_OUT_TICS then
			local t = FixedDiv(tics, RING_OUT_TICS)
	
			local start = ring.start_position
			local out = ring.out_position

			local x = ease.outquad(t, start.x, out.x)
			local y = ease.outquad(t, start.y, out.y)
			local z = ease.outquad(t, start.z, out.z)
	
			P_MoveOrigin(ring, x, y, z)
			continue
		end
		tics = $ - RING_OUT_TICS

		if tics < still then
			local out = ring.out_position

			P_SetOrigin(ring, out.x, out.y, out.z)
			continue
		end
		tics = $ - still

		if tics < RING_IN_TICS then
			local t = FixedDiv(tics, RING_IN_TICS)

			local out = ring.out_position
			local tmo = self.tmo

			local x = ease.inquad(t, out.x, tmo.x)
			local y = ease.inquad(t, out.y, tmo.y)
			local z = ease.inquad(t, out.z, tmo.z+tmo.height/2)

			P_MoveOrigin(ring, x, y, z)
			continue
		end

		ring.state = S_SPRK1
		ring.frame = $ & ~FF_TRANS60
		S_StartSound(self.tmo, sfx_itemup)

		if self.tmo.type == MT_PLAYER
		and self.tmo.player then
			self.tmo.player.rings = $+1
		end

		table.remove(self.rings, i)
	end

	if #self.rings == 0 then
		return true
	end

	self.tics = $+1
end

function RingSteal:kill()
	for _, ring in ipairs(self.rings) do
		if not ring.valid then
			continue
		end

		P_RemoveMobj(ring)
	end
end

return RingSteal