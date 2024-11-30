local module = {}

module.rings = {
	redring = FangsHeist.require"Modules/Handlers/RingTypes/redring",
	railring = FangsHeist.require"Modules/Handlers/RingTypes/railring"
}

local function thrust_all(mo, angle, aiming, speed)
	local xy_speed = FixedMul(speed, cos(aiming))
	local z_speed = FixedMul(speed, sin(aiming))

	P_InstaThrust(mo, angle, xy_speed)
	mo.momz = z_speed
end

function module.fireRing(p, type)
	if not (p and p.mo and type and module.rings[type]) then
		return
	end
	if (p.heist.weapon_cooldown) then return end

	local data = module.rings[type]

	local angle = p.mo.angle
	local aiming = p.aiming

	local missile = P_SPMAngle(p.mo, data.type, angle, 1)

	if missile
	and missile.valid then
		if data.onSpawn then
			data.onSpawn(p, missile)
		end

		p.rings = max(0, $-1)
		p.heist.weapon_cooldown = data.cooldown or 0
	end

	return missile
end

return module