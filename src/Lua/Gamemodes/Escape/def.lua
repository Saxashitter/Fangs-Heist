local gamemode = {
	name = "Escape",
	desc = "Get some profit, grab that signpost, and GO! GO! GO!",
	id = "ESCAPE",
	tol = TOL_HEIST
}
local path = "Gamemodes/Escape/"

dofile(path.."freeslots.lua")

local treasure_things = {
	[312] = true
}
local bean_things = {
	[402] = true,
	[408] = true,
	[409] = true
}
local replace_types = {
	[MT_1UP_BOX] = MT_RING_BOX
}
local delete_types = { -- why wasnt this a table like the rest before? -pac
	[MT_ATTRACT_BOX] = true,
	[MT_INVULN_BOX] = true,
	[MT_STARPOST] = true
}
gamemode.signThings = {
	[501] = true
}

local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

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

function gamemode:canEggmanSpawn()
	if not (FangsHeist.Net.time_left) then
		return true
	end

	if FangsHeist.Save.retakes > 1 then
		return true
	end

	return false
end

function gamemode:handleEggman()
	if not self:canEggmanSpawn() then return end

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

function gamemode:initSignPosition()
	local signpost_pos

	for thing in mapthings.iterate do
		if self.signThings[thing.type] then
			if thing and thing.mobj and thing.mobj.valid then
				P_RemoveMobj(thing.mobj)
			end

			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_FH_SIGN, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			signpost_pos = {x, y, z, a}
			break
		end
	end

	if not (signpost_pos) then return false end

	FangsHeist.Net.signpos = signpost_pos
	return signpost_pos
end

function gamemode:getSignSpawn()
	local pos = FangsHeist.Net.signpos

	if FangsHeist.Net.round_2
	and FangsHeist.Net.escape then
		local pos2 = FangsHeist.Net.round_2_teleport.pos

		local count = 0
		local secondCount = 0

		for p in players.iterate do
			if not (p.heist and p.heist:isAlive() and not p.heist.exiting) then continue end

			count = $+1
			if p.heist.reached_second then
				secondCount = $+1
			end
		end

		if (count > 1
		and secondCount >= count/2)
		or (count <= 1
		and secondCount == count) then
			pos = pos2
		end
	end

	return pos
end

function gamemode:spawnSign()
	return FangsHeist.spawnSign(self:getSignSpawn())
end

function gamemode:respawnSign()
	return FangsHeist.respawnSign(self:getSignSpawn())
end

function gamemode:signcapture(stolen)
	if FangsHeist.Net.escape then return end

	self:startEscape()
end

function gamemode:init(map)
	local info = mapheaderinfo[map]

	FangsHeist.Net.escape = false
	FangsHeist.Net.escape_theme = "FH_ESC"
	FangsHeist.Net.round2_theme = "ROUND2"
	FangsHeist.Net.escape_hurryup = true
	FangsHeist.Net.escape_on_start = false

	FangsHeist.Net.last_man_standing = false

	FangsHeist.Net.round_2 = false
	FangsHeist.Net.round_2_teleport = {}

	FangsHeist.Net.hurry_up = false
	FangsHeist.Net.signpos = {0,0,0,0}

	if info.fh_escapetheme then
		FangsHeist.Net.escape_theme = info.fh_escapetheme
	end
	if info.fh_round2theme then
		FangsHeist.Net.round2_theme = info.fh_round2theme
	end
	if info.fh_escapehurryup then
		FangsHeist.Net.escape_hurryup = info.fh_escapehurryup:lower() == "true"
	end

	if info.fh_hellstage
	and info.fh_hellstage:lower() == "true" then
		FangsHeist.Net.round_2 = true
	end

	if info.fh_lastmanstanding
	and info.fh_lastmanstanding:lower() == "true" then
		FangsHeist.Net.last_man_standing = true
	end

	local time = 3*(TICRATE*60)

	if info.fh_time then
		time = tonumber(info.fh_time)*TICRATE
	end

	if FangsHeist.CVars.escape_time.value then
		time = FangsHeist.CVars.escape_time.value*TICRATE
	end

	FangsHeist.Net.time_left = time
	FangsHeist.Net.max_time_left = time

	FangsHeist.Net.escape_on_start = (info.fh_escapeonstart == "true")
end

function gamemode:load()
	local exit
	local treasure_spawns = {}

	for thing in mapthings.iterate do
		if thing.mobj
		and thing.mobj.valid then
			if replace_types[thing.mobj.type] ~= nil then
				local newtype = replace_types[thing.mobj.type]
				P_RemoveMobj(thing.mobj)
				
				local mo = P_SpawnMobj(thing.x*FU, thing.y*FU, spawnpos.getThingSpawnHeight(newtype, thing, thing.x*FU, thing.y*FU), newtype)
				if (thing.options & MTF_OBJECTFLIP) then
					thing.flags2 = $^^MF2_OBJECTFLIP
				end
			elseif delete_types[thing.mobj.type] then
				P_RemoveMobj(thing.mobj)
			end
		end

		if thing.type == 3844 then
			exit = thing
		end

		if thing.type == 3842 then
			FangsHeist.Net.round_2 = true
			local pos = {
				thing.x*FU,
				thing.y*FU,
				spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU),
				thing.angle*ANG1
			}

			FangsHeist.Net.round_2_teleport.pos = pos
		end

		if thing.type == 3843 then
			FangsHeist.Net.round_2 = true
	
			local pos = {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU),
				a = thing.angle*ANG1
			}
	
			local mobj = P_SpawnMobj(pos.x, pos.y, pos.z, MT_THOK)
			mobj.angle = pos.a
			mobj.state = S_FH_ROUNDPORTAL
			mobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOTHINK|MF_NOGRAVITY
			mobj.scale = tofixed("1.3")

			FangsHeist.Net.round_2_mobj = mobj
		end

		if treasure_things[thing.type] then
			table.insert(treasure_spawns, {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU)
			})

			if thing.mobj
			and thing.mobj.valid then
				P_RemoveMobj(thing.mobj)
			end
		end

		if thing.type == 1
		and exit == nil then
			exit = thing
		end
	end

	if exit then
		local x = exit.x*FU
		local y = exit.y*FU
		local z = spawnpos.getThingSpawnHeight(MT_PLAYER, exit, x, y)
		local a = FixedAngle(exit.angle*FU)

		FangsHeist.defineExit(x, y, z, a)
	end

	for i = 1,5 do
		if not (#treasure_spawns) then
			break
		end

		local choice = P_RandomRange(1, #treasure_spawns)
		local thing = treasure_spawns[choice]

		FangsHeist.defineTreasure(thing.x, thing.y, thing.z)
		table.remove(treasure_spawns, choice)
	end

	self:initSignPosition()
	self:spawnSign()
end

function gamemode:update()
	if FangsHeist.Net.escape then
		self:manageEscape()
	end

	-- yay rounr portal
	local round = FangsHeist.Net.round_2_mobj

	if round and round.valid then
		round.spriteroll = $ + FixedAngle(360*FU/120)
		round.spriteyoffset = 8*sin(round.spriteroll)
	end

	FangsHeist.manageTreasures()
	FangsHeist.teleportSign()
end

function gamemode:trackplayer(p)
	local lp = displayplayer
	local args = {}

	if #p.heist.treasures then
		table.insert(args, "TREASURE")
	end
	if p.heist:hasSign() then
		table.insert(args, "SIGN")
	end
	if p.heist:isPartOfTeam(lp) then
		table.insert(args, "TEAM")
	end

	return args
end

function gamemode:manageEscape()
	-- sign
	self:manageSign()

	-- time
	self:manageTime()

	-- exiting
	self:manageExiting()

	-- hell stage tp
	self:round2Check()

	-- BOMBS FOR RETAKES.......
	self:manageBombs()

	-- eggman
	self:handleEggman()
end

function gamemode:sync(sync)
	FangsHeist.Net.escape = sync($)
	FangsHeist.Net.escape_theme = sync($)
	FangsHeist.Net.round2_theme = sync($)
	FangsHeist.Net.escape_hurryup = sync($)
	FangsHeist.Net.escape_on_start = sync($)

	FangsHeist.Net.last_man_standing = sync($)

	FangsHeist.Net.round_2 = sync($)
	FangsHeist.Net.round_2_teleport = sync($)

	FangsHeist.Net.time_left = sync($)
	FangsHeist.Net.max_time_left = sync($)
	FangsHeist.Net.hurry_up = sync($)

	FangsHeist.Net.escape_on_start = sync($)
	FangsHeist.Net.signpos = sync($)

	FangsHeist.Net.sign = sync($)
	FangsHeist.Net.exit = sync($)
	FangsHeist.Net.round_2_mobj = sync($)
	FangsHeist.Net.eggman = sync($)
end

function gamemode:music()
	if not FangsHeist.Net.escape then
		if FangsHeist.Save.retakes then
			return "WILFOR", true
		end

		return
	end

	local p = displayplayer

	if not FangsHeist.Net.time_left then
		return "FHTUP", true
	end

	local t = max(0, min(FixedDiv((5*TICRATE)-FangsHeist.Net.time_left, 5*TICRATE), FU))
	local volume = ease.linear(t, 255, 0)

	if FangsHeist.Save.retakes then
		return FangsHeist.Save.retakes > 1 and "THCUAG" or "THECUR", true, volume
	end

	if self:isHurryUp() then
		return "HURRUP", false
	end

	if (p and p.valid and p.heist and p.heist.reached_second) then
		return FangsHeist.Net.round2_theme, true, volume
	end

	return FangsHeist.Net.escape_theme, true, volume
end

function gamemode:start()
	local randPlyrs = {}

	for p in players.iterate do
		if p.heist
		and p.heist:isAlive()
		and p.heist:isTeamLeader() then
			table.insert(randPlyrs, p)
		end
	end

	if #randPlyrs
	and FangsHeist.Net.escape_on_start then
		local p = randPlyrs[P_RandomRange(1, #randPlyrs)]

		FangsHeist.giveSignTo(p)
		self:startEscape(p)
	end
end

function gamemode:shouldend()
	local count = FangsHeist.playerCount()

	return (count.alive == 0
	or (not count.exiting and count.team == 1 and FangsHeist.Net.last_man_standing))
	and FangsHeist.Net.escape
end

function gamemode:finish()
end

function gamemode:playerinit(p)
	if FangsHeist.Net.escape then
		p.heist.spectator = true
		p.spectator = true
	end
end

function gamemode:playerthink(p)
end

function gamemode:playerdeath(p, i, s)
	if not FangsHeist.Net.escape then return end

	p.heist.spectator = true
end

function gamemode:manageSign()
	if not (FangsHeist.Net.sign
		and FangsHeist.Net.sign.valid) then
			self:spawnSign()
	end
end

function gamemode:manageTime()
	if not FangsHeist.Net.time_left then return end

	FangsHeist.Net.time_left = max(0, $-1)
	FangsHeist.setTimerTime(FangsHeist.Net.time_left, FangsHeist.Net.max_time_left)

	if FangsHeist.Net.time_left <= 30*TICRATE
	and not FangsHeist.Net.hurry_up then
		// dialogue.startFangPreset("hurryup")
		FangsHeist.Net.hurry_up = true
	end

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

function gamemode:round2Check()
	if not FangsHeist.Net.round_2 then
		return
	end

	local mobj = FangsHeist.Net.round_2_mobj

	for p in players.iterate do
		if not (p.heist and p.heist:isAlive()) then continue end
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

		self:doRound2(p)
	end
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

function gamemode:manageExiting()
	local exit = FangsHeist.Net.exit

	for p in players.iterate do
		if not p.heist then continue end
		if not p.heist:isAlive() then continue end

		if not p.heist:isAtGate()
		and not p.heist.exiting then
			continue
		end

		if not p.heist.exiting
		and HeistHook.runHook("PlayerExit", p) == true then
			continue
		end

		if self.playerexit
		and self:playerexit(p) then
			continue
		end

		P_SetOrigin(p.mo, exit.x, exit.y, exit.z)
		p.mo.flags2 = $|MF2_DONTDRAW
		p.mo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOTHINK
		p.mo.state = S_PLAY_STND
		p.camerascale = FU*3

		if p.heist:hasSign()
		and not p.heist.exiting then
			local team = p.heist:getTeam()

			team.had_sign = true
			self:respawnSign()
		end

		p.heist.exiting = true
	end
end

function gamemode:doRound2(p)
	if not FangsHeist.Net.round_2 then return end
	if p.heist.reached_second then return end
	if HeistHook.runHook("Round2", p) then return end

	local pos = FangsHeist.Net.round_2_teleport.pos

	P_SetOrigin(p.mo,
		pos[1],
		pos[2],
		pos[3]
	)
	
	p.mo.angle = pos[4]
	p.drawangle = pos[4]
	
	p.heist.reached_second = true
	
	S_StartSound(nil, sfx_mixup, p)
	P_InstaThrust(p.mo, p.mo.angle, FixedHypot(p.rmomx, p.rmomy))
	
	local linedef = tonumber(mapheaderinfo[gamemap].fh_round2linedef)
	
	if linedef ~= nil then
		P_LinedefExecute(linedef)
	end
end

function gamemode:startEscape(p)
	if FangsHeist.Net.escape
	or HeistHook.runHook("EscapeStart", p) == true then
		return
	end

	FangsHeist.Net.escape = true
	if FangsHeist.Net.round_2 then
		local mo = FangsHeist.Net.round_2_mobj
		local ind = P_SpawnMobj(mo.x, mo.y, mo.z + 90*FU, MT_FH_ROUNDINDICATOR)
		ind.target = mo
	end
	S_StartSound(nil, sfx_gogogo)

	local data = mapheaderinfo[gamemap]
	if data.fh_escapelinedef then
		P_LinedefExecute(tonumber(data.fh_escapelinedef))
	end
end

local HURRY_LENGTH = 2693

function gamemode:isHurryUp()
	if not FangsHeist.Net.escape then
		return false
	end

	if not FangsHeist.Net.escape_hurryup then
		return false
	end

	if (FangsHeist.Net.max_time_left-FangsHeist.Net.time_left)*MUSICRATE/TICRATE > HURRY_LENGTH then
		return false
	end

	return true
end


return FangsHeist.addGamemode(gamemode)