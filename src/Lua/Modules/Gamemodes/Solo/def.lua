local gamemode = {
	name = "Solo",
	desc = "Get some profit, grab that signpost, and GO! GO! GO!",
	id = "SOLO",
	teamlimit = 1,
	tol = TOL_HEIST|TOL_HEISTROUND2,
	twoteamsleft = true,
	exitalwaysopen = false,
}
local path = "Modules/Gamemodes/Solo/"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

dofile(path.."freeslots.lua")
dofile(path.."commands.lua")

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
	self:startEscape(target)

	FangsHeist.playVoiceline(target, "escape")
	return true
end

function gamemode:init(map)
	local info = mapheaderinfo[map]

	FangsHeist.Net.escape = false
	FangsHeist.Net.escape_theme = "FH_ESC"
	FangsHeist.Net.round2_theme = "ROUND2"
	FangsHeist.Net.gogogo_theme = "NEOBRE"
	FangsHeist.Net.twoteamsleft_theme = "EXTERM"
	FangsHeist.Net.escape_hurryup = true
	FangsHeist.Net.escape_opengoal = 80*TICRATE
	FangsHeist.Net.escape_on_start = false

	FangsHeist.Net.last_man_standing = false
	FangsHeist.Net.two_teams_left = false
	FangsHeist.Net.go_go_go = false

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
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU) + 50*FU,
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
		local z = spawnpos.getThingSpawnHeight(MT_PLAYER, exit, x, y) + 50*FU
		local a = FixedAngle(exit.angle*FU)

		local exit = P_SpawnMobj(x, y, z, MT_THOK)
		exit.fuse = -1
		exit.tics = -1
		exit.state = S_FH_GOALPORTAL
		exit.angle = a
		exit.height = 48*FU
		exit.flags = (MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP)
		self:manageRing(exit, not self:canExit(), true)
	
		FangsHeist.Net.exit = exit
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

		-- TODO: clean this up
		if self.twoteamsleft
		and not FangsHeist.Net.two_teams_left
		and not self:isHurryUp()
		and FangsHeist.Net.time_left then
			local counted_teams = 0
			local first_team
			local second_team

			for k, team in ipairs(FangsHeist.Net.teams) do
				local exiting = 0
				local count = 0

				for _, p in ipairs(team) do
					if not (p and p.valid and p.heist) then continue end

					count = $+1

					if p.heist.spectator then exiting = $+1; continue end
					if p.heist.exiting then exiting = $+1; continue end
				end
				if exiting == count then continue end

				if not first_team then
					first_team = team
				elseif not second_team then
					second_team = team
				end

				counted_teams = $+1
			end

			if counted_teams <= 2 then
				local orig_song = FangsHeist.Net.twoteamsleft_theme
				local song = FangsHeist.runHook("2TeamsLeft", first_team, second_team)
					or orig_song

				FangsHeist.Net.twoteamsleft_theme = song

				FangsHeist.Net.two_teams_left = true
				FangsHeist.Net.time_left = 180*TICRATE
				FangsHeist.Net.max_time_left = 180*TICRATE
				FangsHeist.Net.escape_hurryup = false

				FangsHeist.Net.go_go_go = false
				FangsHeist.doTTLHUD()
			end
		end
	end

	self:manageRing(FangsHeist.Net.exit, not self:canExit())

	if FangsHeist.Net.round_2 then
		self:manageRing(FangsHeist.Net.round_2_mobj, not FangsHeist.Net.escape)
	end

	-- exiting
	self:manageExiting()
end

function gamemode:trackplayer(p)
	local lp = displayplayer
	local args = {}

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
	-- time
	self:manageTime()

	-- hell stage tp
	self:round2Check()
end

function gamemode:manageRing(portal, unavailable, instant)
	if not portal then return end
	if not portal.valid then return end

	local min_scale = FU/2
	local min_alpha = FU/5
	local max_scale = 2*FU
	local max_alpha = FU

	-- TODO: probably make use of actual tweens

	if unavailable then
		if instant then
			portal.scale = min_scale
			portal.alpha = min_alpha
			return
		end

		portal.scale = ease.linear(FU/12, $, min_scale)
		portal.alpha = ease.linear(FU/12, $, min_alpha)

		return
	end

	if instant then
		portal.scale = max_scale
		portal.alpha = max_alpha
	end

	portal.scale = ease.linear(FU/12, $, max_scale)
	portal.alpha = ease.linear(FU/12, $, max_alpha)
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

	if FangsHeist.Net.two_teams_left then
		return FangsHeist.Net.twoteamsleft_theme, true, volume
	end

	if FangsHeist.Net.go_go_go then
		return FangsHeist.Net.gogogo_theme, true, volume
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

	local counted_teams = 0
end

function gamemode:manageTime()
	if not FangsHeist.Net.time_left then return end

	FangsHeist.Net.time_left = $-1
	FangsHeist.setTimerTime(FangsHeist.Net.time_left, FangsHeist.Net.max_time_left)

	local counted_teams = 0

	for k, team in ipairs(FangsHeist.Net.teams) do
		local exiting = 0
		local count = 0

		for _, p in ipairs(team) do
			if not (p and p.valid and p.heist) then continue end

			count = $+1
			if p.heist.spectator then exiting = $+1; continue end
			if p.heist.exiting then exiting = $+1; continue end
		end
		if exiting == count then continue end

		counted_teams = $+1
	end

	if FangsHeist.Net.two_teams_left
	and counted_teams <= 1
	and FangsHeist.Net.escape_opengoal
	and FangsHeist.Net.time_left > FangsHeist.Net.escape_opengoal then
		FangsHeist.Net.time_left = FangsHeist.Net.escape_opengoal
	end

	if FangsHeist.Net.time_left <= 30*TICRATE
	and not FangsHeist.Net.hurry_up then
		// dialogue.startFangPreset("hurryup")
		FangsHeist.Net.hurry_up = true
	end

	if FangsHeist.Net.escape_opengoal
	and FangsHeist.Net.time_left == FangsHeist.Net.escape_opengoal then
		S_StartSound(nil, sfx_gogogo)
		FangsHeist.doGoHUD()
		FangsHeist.Net.go_go_go = true
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

		if not p.heist.exiting then
			if not self:canExit() then
				continue
			end
	
			if not p.heist:isAtGate() then
				continue
			end
	
			if FangsHeist.runHook("PlayerExit", p) == true then
				continue
			end

			if self.playerexit
			and self:playerexit(p) then
				continue
			end

			if p.heist:hasSign() then
				local team = p.heist:getTeam()
	
				team.had_sign = true
			end
	
			for i = #p.heist.pickup_list, 1, -1 do
				local v = p.heist.pickup_list[i]
	
				FangsHeist.Carriables.RespawnCarriable(v.mobj)
				table.remove(p.heist.pickup_list, i)
			end
		end

		P_SetOrigin(p.mo, exit.x, exit.y, exit.z)
		p.mo.flags2 = $|MF2_DONTDRAW
		p.mo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOTHINK
		p.mo.state = S_PLAY_STND
		p.camerascale = FU*3

		p.heist.exiting = true
	end
end

function gamemode:canExit()
	if not FangsHeist.Net.escape then return false end

	local counted_teams = 0

	for k, team in ipairs(FangsHeist.Net.teams) do
		local exiting = 0
		local count = 0

		for _, p in ipairs(team) do
			if not (p and p.valid and p.heist) then continue end

			count = $+1
			if p.heist.spectator then exiting = $+1; continue end
			if p.heist.exiting then exiting = $+1; continue end
		end
		if exiting == count then continue end

		counted_teams = $+1
	end

	if counted_teams >= 2
	and FangsHeist.Net.escape_opengoal
	and FangsHeist.Net.time_left > FangsHeist.Net.escape_opengoal then
		return false
	end


	return true
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

	if not FangsHeist.Net.escape_opengoal then
		S_StartSound(nil, sfx_gogogo)
		FangsHeist.doGoHUD()
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

function gamemode:info()
	local info = {
		{"Basics",
			"In order to win, you must collect the most Profit.",
			"Profit comes from rings, enemies, treasures and the sign.",
			"Treasures are very valuable, but they reveal your location.",
			"Players can fight you for your treasures, so do your best to avoid combat."},
		{"Escape",
			"Grab the Sign to start the escape sequence.",
			"The Sign doubles the Profit you get, but slows you down.",
			"It is extremely valuable, so keep ahold of it and escape with it in your grasp."}
	}	
	if FangsHeist.Net.round_2 then
		table.insert(info, {"Round 2",
			"This map requires you to run through 2 segments to finish.",
			"Run into the portal at the start once the escape sequence begins."
		})
	end

	return info
end

local PATH = "Modules/Gamemodes/Solo/%s.lua"

loadAndInherit(gamemode, PATH:format("sign"))
loadAndInherit(gamemode, PATH:format("treasure"))
loadAndInherit(gamemode, PATH:format("round"))

return FangsHeist.addGamemode(gamemode)
