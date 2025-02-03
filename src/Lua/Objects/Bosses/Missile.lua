freeslot "MT_FH_EGGMAN_MISSILE1"
freeslot "S_FH_EGGMAN_MISSILE1"

states[S_FH_EGGMAN_MISSILE1] = {
	sprite = SPR_RCKT,
	frame = A,
	tics = -1
}

mobjinfo[MT_FH_EGGMAN_MISSILE1] = {
	spawnstate = S_FH_EGGMAN_MISSILE1,
	radius = 16*FU,
	height = 8*FU,
	flags = MF_NOGRAVITY
}

--[[
	When launched, this missile locked onto a player until he's found dead.
	It's quite slippery, so that means you can lead it into walls.
	You can also block it, if you want.
]]

local function L_DoBrakes(mo,factor)
	mo.momx = FixedMul($,factor)
	mo.momy = FixedMul($,factor)
	mo.momz = FixedMul($,factor)
end

local function L_SpeedCap(mo,limit,factor)
	local spd = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)

	if spd > limit
		if factor == nil
			factor = FixedDiv(limit,spd)
		end
		L_DoBrakes(mo,factor)
		return factor
	end
end

local function L_ReturnThrustXYZ(mo, point, speed)
	local horz = R_PointToAngle2(mo.x, mo.y, point.x, point.y)
	local vert = R_PointToAngle2(0, mo.z+(mo.height/2), FixedHypot(mo.x-point.x, mo.y-point.y), point.z+(point.height/2))

	local x = FixedMul(FixedMul(speed, cos(horz)), cos(vert))
	local y = FixedMul(FixedMul(speed, sin(horz)), cos(vert))
	local z = FixedMul(speed, sin(vert))

	return x, y, z
end

addHook("MobjThinker", function(mo)
	if not (mo and mo.valid and mo.health) then
		return
	end

	local trgt = mo.target

	if not S_SoundPlaying(mo, sfx_buzz1) then
		S_StartSound(mo, sfx_buzz1)
	end

	if trgt and trgt.valid then
		if FixedHypot(mo.x-trgt.x, mo.y-trgt.y) <= mo.radius+trgt.radius
		and abs(mo.z-trgt.z) <= max(mo.height, trgt.height) then
			local tracer = (mo.tracer and mo.tracer.valid) and mo.tracer or mo
	
			if P_DamageMobj(trgt, mo, tracer) then
				P_KillMobj(mo)
			end
	
			return
		end

		local momx, momy, momz = L_ReturnThrustXYZ(mo, trgt, 3*FU)
	
		mo.momx = $+momx
		mo.momy = $+momy
		mo.momz = $+momz
		mo.angle = R_PointToAngle2(mo.x, mo.y, trgt.x, trgt.y)
	
		L_DoBrakes(mo, FU*15/16)
	end


	if mo.z == mo.floorz
	or mo.z+mo.height == mo.ceilingz then
		P_KillMobj(mo)
		return
	end
	P_SpawnGhostMobj(mo)
end, MT_FH_EGGMAN_MISSILE1)

addHook("MobjMoveBlocked", function(mo)
	if mo and mo.valid then
		P_KillMobj(mo)
	end
end, MT_FH_EGGMAN_MISSILE1)