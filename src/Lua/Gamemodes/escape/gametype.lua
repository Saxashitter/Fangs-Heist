local gamemode = {}

function gamemode:onInit(map)
	local net = FangsHeist.Net
	local info = mapheaderinfo[map]

	net.escape = true
	net.escape_theme = "SPRHRO"
	net.round2_theme = "EXTERM"
	net.escape_hurryup = true
	net.escape_on_start = false
	net.last_man_standing = false
	net.round_2 = false
	net.round_2_pos = {}
	net.time_left = (FangsHeist.CVars.escape_time.value*TICRATE
		or tonumber(info.fh_time)*TICRATE
		or (3*60)*TICRATE)
	net.max_time_left = net.time_left
	net.hurry_up = false

	if info.fh_escapetheme then
		net.escape_theme = info.fh_escapetheme
	end
	if info.fh_round2theme then
		net.escape_theme.round2_theme = info.fh_round2theme
	end
	if info.fh_escapehurryup then
		net.escape_theme.escape_hurryup = info.fh_escapehurryup:lower() == "true"
	end

	if info.fh_lastmanstanding
	and info.fh_lastmanstanding:lower() == "true" then
		FangsHeist.Net.last_man_standing = true
	end

	FangsHeist.Net.escape_on_start = ((info.fh_escapeonstart or ""):lower() == "true")
end

function gamemode:onPlayerInit(p)
	p.heist.spectator = FangsHeist.Net.escape
	p.spectator = p.heist.spectator
end

local replace_types = {
	[MT_1UP_BOX] = MT_RING_BOX
}

local delete_types = { -- why wasnt this a table like the rest before? -pac
	[MT_ATTRACT_BOX] = true,
	[MT_INVULN_BOX] = true,
	[MT_STARPOST] = true
}

function gamemode:onLoad()
	for thing in mapthings.iterate do
		if thing.mobj
		and thing.mobj.valid then
			if delete_types[thing.mobj.type] then
				P_RemoveMobj(thing.mobj)
			end
		end

		if thing.type == 3842 then
			FangsHeist.Net.round_2 = true

			local pos = {
				x = thing.x*FU,
				y = thing.y*FU,
				z = FangsHeist.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU),
				a = thing.angle*ANG1
			}

			FangsHeist.Net.round_2_pos = pos
		end

		if thing.type == 3843 then
			FangsHeist.Net.round_2 = true
	
			local pos = {
				x = thing.x*FU,
				y = thing.y*FU,
				z = FangsHeist.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU),
				a = thing.angle*ANG1
			}
	
			local mobj = P_SpawnMobj(pos.x, pos.y, pos.z, MT_THOK)
			mobj.angle = pos.a
			mobj.state = S_FH_MARVQUEEN
			mobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOTHINK|MF_NOGRAVITY

			FangsHeist.Net.round_2_mobj = mobj
		end

		--[[if treasure_things[thing.type] then
			table.insert(treasure_spawns, {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU)
			})

			if thing.mobj
			and thing.mobj.valid then
				P_RemoveMobj(thing.mobj)
			end
		end]]
	end
end


function gamemode:onThink()
	if not (FangsHeist.Net.sign
	and FangsHeist.Net.sign.valid) then
		FangsHeist.spawnSign()
	end

	
end

function gamemode:timeTick()
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
end

function gamemode:canGoToRound2(p)
	if not FangsHeist.Net.round_2 then return false end
	local mobj = FangsHeist.Net.hell_stage_mobj

	if not FangsHeist.isPlayerAlive(p) then return false end
	if p.heist.reached_second then return false end

	if R_PointToDist2(p.mo.x,p.mo.y,mobj.x,mobj.y) > 32*FU+p.mo.radius then
		return false
	end
	if p.mo.z > mobj.z+48*FU then
		return false
	end
	if mobj.z > p.mo.z+p.mo.height then
		return false
	end

	return true
end

function gamemode:goToRound2(p)
	local pos = FangsHeist.Net.hell_stage_teleport.pos

	P_SetOrigin(p.mo,
		pos.x,
		pos.y,
		pos.z
	)
	
	p.mo.angle = pos.a
	p.drawangle = pos.a
	
	local anyoneReached = false
	for p in players.iterate do
		if (p and p.heist and p.reached_second) then
			anyoneReached = true
			break
		end
	end
	
	p.heist.reached_second = true
	S_StartSound(nil, sfx_mixup, p)
	P_InstaThrust(p.mo, p.mo.angle, FixedHypot(p.rmomx, p.rmomy))
	
	local linedef = tonumber(mapheaderinfo[gamemap].fh_round2linedef)
	
	if linedef ~= nil
	and not anyoneReached then
		P_LinedefExecute(linedef)
	end
end

function gamemode:escapeThink()
	
end

function gamemode:onSync(sync)
	local net = FangsHeist.Net

	net.escape = sync($)
	net.escape_theme = sync($)
	net.round2_theme = sync($)
	net.escape_hurryup = sync($)
	net.escape_on_start = sync($)
	net.last_man_standing = sync($)
	net.round_2 = sync($)
	net.round_2_pos = sync($)
	net.round_2_mobj = sync($)
	net.time_left = sync($)
	net.max_time_left = sync($)
	net.hurry_up = sync($)
end

function gamemode:onPlayerThink(p)
end

function gamemode:onPlayerDeath(p)
	
end

function gamemode:shouldEnd()
end

function gamemode:onEnd()
end

FH:addGametype(gamemode)