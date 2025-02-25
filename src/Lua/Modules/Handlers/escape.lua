local orig_plyr = FangsHeist.require"Modules/Variables/player"
local dialogue = FangsHeist.require"Modules/Handlers/dialogue"
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

local function module()
	if not FangsHeist.Net.escape then
		return
	end

	FangsHeist.Net.time_left = max(0, $-1)
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

	if FangsHeist.Net.hell_stage then
		local sec = FangsHeist.Net.hell_stage_teleport.sector
		local pos = FangsHeist.Net.hell_stage_teleport.pos

		for p in players.iterate do
			if (p and p.mo and p.mo.subsector.sector == sec) then
				P_SetOrigin(p.mo,
					pos.x,
					pos.y,
					pos.z
				)

				p.mo.angle = pos.a
				p.drawangle = pos.a

				S_StartSound(nil, sfx_mixup, p)
				P_InstaThrust(p.mo, p.mo.angle, FixedHypot(p.rmomx, p.rmomy))
			end
		end
	end


	local exit = FangsHeist.Net.exit
	exit.state = S_FH_EXIT_OPEN

	-- BOMBS FOR RETAKES.......
	local potential_positions = {}
	local range = 80

	for p in players.iterate do
		if not p.heist then continue end
		if not FangsHeist.isPlayerAlive(p) then continue end
		if p.heist.exiting then
			P_SetOrigin(p.mo, exit.x, exit.y, exit.z)
			p.mo.flags2 = $|MF2_DONTDRAW
			p.mo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOTHINK
			p.camerascale = FU*3
			continue
		end

		if not FangsHeist.isPlayerAtGate(p) then
			if FangsHeist.Save.retakes then
				table.insert(potential_positions, {
					x = p.mo.x + p.mo.momx*15 + P_RandomRange(-240, 240)*FU,
					y = p.mo.y + p.mo.momy*15 + P_RandomRange(-240, 240)*FU,
					player = p
				})
			end

			continue
		end
		
		p.heist.exiting = true

		if FangsHeist.playerHasSign(p) then
			p.heist.team.banked_sign = true
			p.heist.had_sign = true
			FangsHeist.respawnSign(p)
		end
	end

	if not FangsHeist.Save.retakes then return end

	local tics = max(3*TICRATE/FangsHeist.Save.retakes, 42)

	if #potential_positions
	and not (leveltime % tics) then
		for _,position in pairs(potential_positions) do
			local sector = R_PointInSubsectorOrNil(position.x, position.y)
	
			if not (sector and sector.valid) then
				continue
			end
	
			sector = sector.sector
	
			local scale = 1
			local z = min(position.player.mo.z+360*FU, sector.ceilingheight - mobjinfo[MT_FBOMB].height*scale)
	
			local bomb = P_SpawnMobj(position.x, position.y, z, MT_FBOMB)
			if bomb and bomb.valid then
				bomb.scale = $*scale
				bomb.spritexscale = $/scale
				bomb.spriteyscale = $/scale
				bomb.momz = -8*FU
				bomb.alpha = 0
				table.insert(bombs, bomb)
			end
		end
	end
end
return module