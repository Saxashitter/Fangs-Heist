local gamemode = {
	name = "Solo",
	desc = "Get some profit, grab that signpost, and GO! GO! GO!",
	id = "SOLO",
	teamlimit = 1,
	tol = TOL_HEIST|TOL_HEISTROUND2
}
local path = "Modules/Gamemodes/Solo/"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

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

local function loadAndInherit(self, path)
	local file = dofile(path)

	for k,v in pairs(file) do
		self[k] = $ or v
	end
end

gamemode.signThings = {
	[501] = true
}

function gamemode:spawnEggman(type)
	local pos = self:getSignSpawn()
	local eggman = P_SpawnMobj(pos[1], pos[2], pos[3], MT_FH_EGGMAN)

	FangsHeist.Net.eggman = eggman

	if type == "pt" then
		eggman.state = S_FH_EGGMAN_COOLDOWN
	end

	return false
end

function gamemode:signcapture(target, stolen)
	if FangsHeist.Net.escape then return end

	S_StartSound(nil, sfx_lvpass)
	self:startEscape()

	FangsHeist.playVoiceline(target, "escape")
	return true
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
			self:spawnRound2Portal(pos)
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

	for i = 1, #treasure_spawns do
		local thing = treasure_spawns[i]

		self:spawnTreasure(thing)
	end

	self:initSignPosition()
	self:spawnSign()
end

function gamemode:update()
	if FangsHeist.Net.escape then
		self:manageEscape()
	end

	self:manageRound2Portal()
end

function gamemode:trackplayer(p)
	local lp = displayplayer
	local args = {}

	-- TO-DO: treasure track

	if p.heist:hasSign() then
		table.insert(args, "SIGN")
	end
	if p.heist:hasTreasure() then
		table.insert(args, "TREASURE")
	end
	if p.heist:isPartOfTeam(lp) then
		table.insert(args, "TEAM")
	end

	return args
end

function gamemode:manageEscape()
	-- exiting
	self:manageExiting()

	-- time
	self:manageTime()

	-- hell stage tp
	self:round2Check()
end

function gamemode:music()
	if not FangsHeist.Net.escape then
		return
	end

	local p = displayplayer

	if not FangsHeist.Net.time_left then
		return "FHTUP", true
	end

	local t = max(0, min(FixedDiv((5*TICRATE)-FangsHeist.Net.time_left, 5*TICRATE), FU))
	local volume = ease.linear(t, 255, 0)

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

	-- TODO: make compatible with new carriable system
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
	--[[
	TODO: re-add when v2 comes around as an option
	if FangsHeist.Net.escape then
		local tics = leveltime - FangsHeist.Net.time_escape_started
		local time = TICRATE * 7
		local turn = 7
		local angle = FixedAngle(360*FixedDiv(tics % time, time))

		p.viewrollangle = FixedAngle(turn*sin(angle))
	end]]
	if not (p.mo and p.mo.health) then return end

	local char = FangsHeist.Characters[p.mo.skin]

	if char.panicState ~= false
	and FangsHeist.Net.escape then
		if p.mo.state == S_PLAY_STND then
			p.mo.state = char.panicState
		end

		if p.mo.state == char.panicState then
			if p.speed then
				p.mo.state = S_PLAY_WALK
			end
		end
	end
end

function gamemode:playerdeath(p, i, s)
	if not FangsHeist.Net.escape then return end

	p.heist.spectator = true
end

function gamemode:manageTime()
	if not FangsHeist.Net.time_left then return end

	FangsHeist.Net.time_left = $-1
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

		if not (FangsHeist.Net.eggman and FangsHeist.Net.eggman.valid) then
			self:spawnEggman("doom")
		else
			FangsHeist.Net.eggman.state = S_FH_EGGMAN_DOOMCHASE
		end

		FangsHeist.runHook("TimeUp")
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
		and FangsHeist.runHook("PlayerExit", p) == true then
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
		end

		for i = #p.heist.pickup_list, 1, -1 do
			local v = p.heist.pickup_list[i]

			FangsHeist.Carriables.RespawnCarriable(v.mobj)
			table.remove(p.heist.pickup_list, i)
		end

		p.heist.exiting = true
	end
end

function gamemode:startEscape(p)
	if FangsHeist.Net.escape
	or FangsHeist.runHook("EscapeStart", p) == true then
		return
	end

	FangsHeist.Net.escape = true
	FangsHeist.Net.time_escape_started = leveltime

	local data = mapheaderinfo[gamemap]
	if data.fh_escapelinedef then
		P_LinedefExecute(tonumber(data.fh_escapelinedef))
	end

	S_StartSound(nil, sfx_gogogo)
	FangsHeist.doGoHUD()
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

function gamemode:info()
	local info = {
		{"Basics",
			"In order to win, you must collect the most Profit.",
			"Profit comes from rings, enemies, and treasures.",
			"Treasures reveal your location, but pretty valuable.",
			"Players can fight you for your treasures."},
		{"Escape",
			"Grab the signpost to start the escape sequence.",
			"The sign also happens to Double the Multiply.",
			"It is Very, VERY valuable, so Keep Holding!"
		}
	}	
	if FangsHeist.Net.round_2 then
		table.insert(info, {"Round 2",
			"This map requires you to run through 2 segments to win.",
			"Run into the portal at spawn once the escape starts."
		})
	end

	return info
end

local PATH = "Modules/Gamemodes/Solo/%s.lua"

loadAndInherit(gamemode, PATH:format("sign"))
loadAndInherit(gamemode, PATH:format("treasure"))
loadAndInherit(gamemode, PATH:format("round"))

return FangsHeist.addGamemode(gamemode)