local function RotatePoint(x_original, y_original, angle_fixedpoint)
	local cos_angle = cos(angle_fixedpoint) -- Use fixed-point cos
	local sin_angle = sin(angle_fixedpoint) -- Use fixed-point sin
	
	local x_rotated = FixedMul(x_original, cos_angle) - FixedMul(y_original, sin_angle)
	local y_rotated = FixedMul(x_original, sin_angle) + FixedMul(y_original, cos_angle)
	
	return x_rotated, y_rotated
end

local function CheckCollision(hitbox, mo)
	if mo.z > hitbox.z+hitbox.s/2 then
		return false
	end
	if mo.z+mo.height < hitbox.z-hitbox.s/2 then
		return false
	end
	local moX = mo.x - hitbox.x
	local moY = mo.y - hitbox.y

	moX, moY = RotatePoint($1, $2, InvAngle(hitbox.a))

	local angle = R_PointToAngle2(moX, moY, 0, 0)
	local offsetX = FixedMul(mo.radius, cos(angle))
	local offsetY = FixedMul(mo.radius, sin(angle))

	local nearestX = max(0, min(moX, hitbox.w))
	local nearestY = max(0, min(moY, hitbox.h))

	local dist = R_PointToDist2(moX, moY, nearestX, nearestY)
	return dist <= mo.radius
end

-- copied from another project
FangsHeist.makeHitbox = function(x, y, z, w, h, s, a)
	return {
		x = x,
		y = y,
		z = z,
		w = w,
		h = h,
		s = s,
		a = a
	}
end

FangsHeist.useHitbox = function(source, hitbox, func)
	local foundPlayers = {}
	local minX = INT32_MAX
	local maxX = -INT32_MAX
	local minY = INT32_MAX
	local maxY = -INT32_MAX

	local positions = {
		{RotatePoint(-hitbox.w, -hitbox.h, hitbox.a)},
		{RotatePoint(-hitbox.w, hitbox.h, hitbox.a)},
		{RotatePoint(hitbox.w, hitbox.h, hitbox.a)},
		{RotatePoint(hitbox.w, -hitbox.h, hitbox.a)},
	}

	for _, v in ipairs(positions) do
		minX = min($, v[1])
		maxX = max($, v[1])
		minY = min($, v[2])
		maxY = max($, v[2])
	end

	searchBlockmap("objects", function(_, found)
		if found.type ~= MT_PLAYER then return end
		if not (found.player and found.player.valid) then return end
		if found.player == source then return end
		if not CheckCollision(hitbox, found) then return end

		func(source, hitbox, found.player)
	end, source.mo, hitbox.x+minX*2, hitbox.x+maxX*2, hitbox.y+minY*2, hitbox.y+maxY*2)

	return foundPlayers
end


function FangsHeist.clashPlayers(p, sp)
	local angle = R_PointToAngle2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)

	P_InstaThrust(p.mo, angle, -p.speed)
	P_InstaThrust(sp.mo, angle, p.speed)

	local char1 = FangsHeist.Characters[p.mo.skin]
	local char2 = FangsHeist.Characters[sp.mo.skin]

	char1:onClash(p, sp)
	char2:onClash(sp, p)

	p.mo.state = S_PLAY_FALL
	sp.mo.state = S_PLAY_FALL

	p.powers[pw_flashing] = 10
	sp.powers[pw_flashing] = 10
end

function FangsHeist.stopVoicelines(p)
	local char = FangsHeist.Characters[p.heist.locked_skin]

	for k, tbl in pairs(char.voicelines) do
		for _, snd in ipairs(tbl) do
			S_StopSoundByID(p.mo, snd)
		end
	end
end

function FangsHeist.playVoiceline(p, line, private)
	local char = FangsHeist.Characters[p.heist.locked_skin]

	if not char.voicelines[line] then
		print("no lines for" .. line)
		return
	end

	FangsHeist.stopVoicelines(p)

	local lines = char.voicelines[line]

	S_StartSound(p.mo, lines[P_RandomRange(1, #lines)], private and p)
	print("playing")
end