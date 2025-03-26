local orig_plyr = FangsHeist.require"Modules/Variables/player"
local function valid_player(p)
	return p and p.mo and p.mo.health and p.heist and not p.heist.spectator and not p.heist.exiting
end

local bombs = {}
addHook("NetVars", function(n) bombs = n($) end)
addHook("ThinkFrame", do
	for i = #bombs, 1, -1 do
		local bomb = bombs[i]

		if not (bomb and bomb.valid) then
			table.remove(bombs, i)
			continue
		end

		bomb.alpha = min($+FU/12, FU)
	end
end)

local function choose_player()
	local plyrs = {}
	for p in players.iterate do
		if valid_player(p) then
			table.insert(plyrs, p)
		end
	end

	if not (#plyrs) then
		return false
	end

	return plyrs[P_RandomRange(1, #plyrs)]
end

local function canSpawn()
	if not (FangsHeist.Net.time_left) then
		return true
	end

	if FangsHeist.Save.retakes > 1 then
		return true
	end

	return false
end

local function handleEggman()
	if not canSpawn() then return end

	if not (FangsHeist.Net.eggman
	and FangsHeist.Net.eggman.valid) then
		local sign = FangsHeist.Net.sign
		local eggman = P_SpawnMobj(sign.x, sign.y, sign.z, MT_FH_EGGMAN)

		FangsHeist.Net.eggman = eggman

		if FangsHeist.Save.retakes > 1
		and FangsHeist.Net.time_left then
			eggman.state = S_FH_EGGMAN_COOLDOWN
		end
	end

	if FangsHeist.Net.eggman.state ~= S_FH_EGGMAN_DOOMCHASE
	and not (FangsHeist.Net.time_left) then
		FangsHeist.Net.eggman.state = S_FH_EGGMAN_DOOMCHASE
	end
end

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

local function module()
	if not FangsHeist.Net.escape then
		return
	end

	if FangsHeist.Net.time_left then
		FangsHeist.Net.time_left = max(0, $-1)

		if FangsHeist.Net.time_left <= 10*TICRATE
		and FangsHeist.Net.time_left % TICRATE == 0 then
			if FangsHeist.Net.time_left == 0 then
				S_StartSound(nil, sfx_fhuhoh)
			else
				S_StartSound(nil, sfx_fhtick)
			end
		end

		if not FangsHeist.Net.time_left then
			local linedef = tonumber(mapheaderinfo[gamemap].fh_timeuplinedef)

			if linedef ~= nil then
				P_LinedefExecute(linedef)
			end

			HeistHook.runHook("TimeUp")
		end
	end

	if FangsHeist.Net.time_left <= 30*TICRATE
	and not FangsHeist.Net.hurry_up then
		dialogue.startFangPreset("hurryup")
		FangsHeist.Net.hurry_up = true
	end

	handleEggman()

	if not (FangsHeist.Net.sign
		and FangsHeist.Net.sign.valid) then
			FangsHeist.spawnSign()
	end

	if FangsHeist.Net.round_2 then
		local mobj = FangsHeist.Net.round_2_mobj

		for p in players.iterate do
			if not FangsHeist.isPlayerAlive(p) then continue end
			if p.heist.reached_second then continue end

			if R_PointToDist2(p.mo.x,p.mo.y,mobj.x,mobj.y) > 24*FU+p.mo.radius then
				continue
			end
			if p.mo.z > mobj.z+48*FU then
				continue
			end
			if mobj.z > p.mo.z+p.mo.height then
				continue
			end

			FangsHeist.goToRound2(p)
		end
	end

	-- BOMBS FOR RETAKES.......
	local potential_positions = {}
	local range = 80

	for p in players.iterate do
		if not p.heist then continue end
		if not FangsHeist.isPlayerAlive(p) then continue end
		if p.heist.exiting then
			local exit = FangsHeist.Net.exit
			P_SetOrigin(p.mo, exit.x, exit.y, exit.z)
			p.mo.flags2 = $|MF2_DONTDRAW
			p.mo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOTHINK
			p.mo.state = S_PLAY_STND
			p.camerascale = FU*3
			continue
		end

		if not FangsHeist.isPlayerAtGate(p) then
			if FangsHeist.Save.retakes then
				table.insert(potential_positions, {
					player = p
				})
			end

			continue
		end
		if HeistHook.runHook("PlayerExit", p) == true then
			continue
		end

		p.heist.exiting = true

		if FangsHeist.playerHasSign(p) then
			local team = FangsHeist.getTeam(p)

			team.had_sign = true

			FangsHeist.respawnSign(p)
		end
	end

	if not FangsHeist.Save.retakes then return end

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
				bomb.alpha = 0

				table.insert(bombs, bomb)
			end
		end
	end
end
return module