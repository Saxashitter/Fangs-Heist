local gamemode = {}

local function predictTicsUntilGrounded(x, y, z, height, momz, gravity)
	local floorz = P_FloorzAtPos(x, y, z, height)
	local grav = gravity
	local tics = 0

	local floorheight = z-floorz

	--[[local t_in_secs = FixedDiv(-momz + FixedSqrt(FixedMul(momz, momz) + 2 * FixedMul(grav, floorheight)), grav)
	print(t_in_secs/FU)

	return t_in_secs]]

	for i = 1,2048 do
		tics = $+1
		momz = $+grav
		z = $+momz

		if z <= floorz then
			return tics
		end

	end

	return -1
end


function gamemode:manageBombs()
	if not FangsHeist.Save.retakes then
		return
	end

	local potential_positions = {}
	local range = 80

	for p in players.iterate do
		if not p.heist then continue end
		if not p.heist:isAlive() then continue end
		if p.heist.exiting then continue end

		table.insert(potential_positions, {
			player = p
		})
	end

	local tics = TICRATE+24
	if FangsHeist.Save.retakes >= 2 then
		tics = TICRATE
	end
	if FangsHeist.Save.retakes >= 3 then
		tics = max(8, $ - 15*(FangsHeist.Save.retakes-2))
	end

	if #potential_positions
	and not (leveltime % tics) then
		for _,position in ipairs(potential_positions) do
			local scale = 1
			local p = position.player
			local z = min(position.player.mo.z+380*FU, p.mo.ceilingz - mobjinfo[MT_FBOMB].height*scale)

			local x = p.mo.x
			local y = p.mo.y
			local g = -2*FU

			local bomb = P_SpawnMobj(x, y, z, MT_FBOMB)
			if bomb and bomb.valid then
				if p.mo.momx
				and p.mo.momy then
					local speed = R_PointToDist2(0,0,p.mo.momx,p.mo.momy)
					local momangle = R_PointToAngle2(0,0,p.mo.momx,p.mo.momy)
					local thrustangle = FixedAngle(P_RandomRange(-15, 15)*FU/3)
	
					local thrustx = P_ReturnThrustX(p.mo, momangle-thrustangle, speed)
					local thrusty = P_ReturnThrustY(p.mo, momangle-thrustangle, speed)
	
					local prediction = predictTicsUntilGrounded(x, y, z, mobjinfo[MT_FBOMB].height, g, P_GetMobjGravity(bomb))
	
					x = $+thrustx*prediction
					y = $+thrusty*prediction
		
					P_SetOrigin(bomb, x, y, z)
				end

				bomb.momz = g
			end
		end
	end
end

return gamemode