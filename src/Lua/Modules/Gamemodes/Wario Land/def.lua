local copy = FangsHeist.require "Modules/Libraries/copy"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Escape])

gamemode.name = "Wario Land 4"
gamemode.desc = "Get as much treasure as you can, then hit the Frog Switch and prepare to H-H-H-HURRY UP!!!"
gamemode.id = "WL4GBA"
gamemode.tol = TOL_HEIST
gamemode.teams = false
gamemode.super = FangsHeist.Gamemodes[FangsHeist.Escape]
gamemode.dontdivprofit = true

-- customvar that determines how much treasure is lost per hit
-- make sure this is a multiple of 10!! Or itll be truncated to
-- the nearest mult of 10
gamemode.treasuredrop = 400

-- how much treasure each enemy is worth
-- lazycopied from IHTKchars ignoring any rebalancing it needs
gamemode.enemytotreasure = {
	[MT_BLUECRAWLA] = 20,
	[MT_REDCRAWLA] = 50,
	[MT_GFZFISH] = 20,
	[MT_GOLDBUZZ] = 40,
	[MT_REDBUZZ] = 80,
	[MT_JETTBOMBER] = 100,
	[MT_JETTGUNNER] = 100,
	[MT_CRAWLACOMMANDER] = 300,
	[MT_DETON] = 20,
	[MT_SKIM] = 40,
	[MT_POPUPTURRET] = 40,
	[MT_SPINCUSHION] = 50,
	[MT_CRUSHSTACEAN] = 50,
	[MT_BANPYURA] = 50,
	[MT_JETJAW] = 20,
	[MT_SNAILER] = 50,
	[MT_VULTURE] = 50,
	[MT_SPRINGSHELL] = 30,
	[MT_YELLOWSHELL] = 30,
	[MT_ROBOHOOD] = 50,
	[MT_FACESTABBER] = 300,
	[MT_UNIDUS] = 50,
	[MT_POINTY] = 40,
	[MT_CANARIVORE] = 30,
	[MT_PYREFLY] = 20,
	[MT_DRAGONBOMBER] = 50,
	[MT_EGGMOBILE] = 1000,
	[MT_EGGMOBILE2] = 1000,
	[MT_EGGMOBILE3] = 1000,
	[MT_EGGMOBILE4] = 1000,
	[MT_FANG] = 1000,
	[MT_CYBRAKDEMON] = 1000,
	[MT_METALSONIC_BATTLE] = 1000,
	[MT_GOOMBA] = 20,
	[MT_BLUEGOOMBA] = 20
}

-- table keyed via G_BuildMapTitle(gamemap)
-- valuesa can be int32 or table with {time, iswar}
-- time is an int32 where its value is the time to escape in seconds
-- (actual time to escape can vary depending on player treasure, however)
-- iswar should normally go unused if all maps are heist-only
-- but if ever activated, forces leveltime to 0
-- (and preferably the only way forward is blocked by the Frog Switch)
gamemode.keroTimers = {
	["greenflower zone 1"] = {time = 110},
	["greenflower zone 2"] = {time = 110},
	["techno hill zone 1"] = {time = 155},
	["techno hill zone 2"] = {time = 130},
	["deep sea zone 1"] = {time = 180},
	["deep sea zone 2"] = {time = 240},
	["castle eggman zone 1"] = {time = 280},
	["castle eggman zone 2"] = {time = 340},
	["arid canyon zone 1"] = {time = 125},
	["arid canyon zone 2"] = {time = 155},
	["red volcano zone 1"] = {time = 265},
	["egg rock zone 1"] = {time = 180},
	["egg rock zone 2"] = {time = 135},
	["black core zone 1"] = {time = 160},
	["aerial garden zone"] = {time = 240},
	["frozen hillside zone"] = {time = 50},
	["haunted heights zone"] = {time = 120},
	["neo palmtree zone"] = {time = 180},
	["pipe towers zone"] = {time = 240},
	["641 crumbling collab zone"] = {time = 195},
	["alcudia port"] = {time = 140},
	["uptown"] = {time = 165},
	["final demo zone"] = {time = 1820/2, iswar = true},
}

local SWAP_TIME = 30*TICRATE

-- Hack!! probably but atleast it synchs with Escape/def/gamemode.signThings
-- Saxa your API is like stinky and stuff
local whatSigns = FangsHeist.GametypeIDs[_G["GT_FANGSHEISTESCAPE"]].signThings

-- mobj_t mo
-- int32 count
-- returns the remainder (usually 0 in perfect circumstances)
local function WL_SpawnCoins(mo, count)
	while count > 0 do
		local coin = nil

		if count >= 500 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND500COIN)
			count = $ - 500
		elseif count >= 100 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND100COIN)
			count = $ - 100
		elseif count >= 50 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND50COIN)
			count = $ - 50
		elseif count >= 10 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND10COIN)
			count = $ - 10
		else
			-- If less than 10 left, break out to avoid infinite loop
			break
		end

		if coin then
			coin.angle = FixedAngle(P_RandomRange(0, 360)*FRACUNIT)
		end
	end
	
	return count
end

local function intangiblePlayer(p)
	local follow

	p.mo.state = S_INVISIBLE
	p.mo.flags2 = $|MF2_DONTDRAW
	p.pflags = ($|PF_INVIS|PF_NOCLIP) & ~PF_SPINNING|PF_JUMPED
	p.powers[pw_flashing] = 3
	p.powers[pw_underwater] = 6*TICRATE
	p.powers[pw_spacetime] = 6*TICRATE
	p.mo.momx = 0
	p.mo.momy = 0
	p.mo.momz = 0
end

local function respawnPlayer(p)
	p.pflags = $ & ~(PF_INVIS|PF_NOCLIP)
	p.mo.flags2 = $ & ~MF2_DONTDRAW
	p.mo.state = S_PLAY_STND

	p.heist.intangible = false
	p.powers[pw_flashing] = 2*TICRATE

	gamemode:playerspawn(p)
end

local function endCheck()
	for i = 1, #FangsHeist.Net.heisters do
		 local plyr = FangsHeist.Net.heisters[i]

		if plyr
		and plyr.valid
		and plyr.heist
		and not plyr.heist.spectator then
			respawnPlayer(plyr)

			FangsHeist.Net.swap_runner = SWAP_TIME
			FangsHeist.Net.headstart = 2*TICRATE
			FangsHeist.Net.current_runner = plyr
			FangsHeist.Net.exit_deb = 5
			
			if #FangsHeist.Net.heisters <= 2 then
				FangsHeist.Net.last_team_member = true
			end

			return false
		end
	end

	FangsHeist.startIntermission(p)
	return true
end

function gamemode:init(map)
	local info = mapheaderinfo[map]

	FangsHeist.Net.escape = false
	FangsHeist.Net.escape_theme = "HRRYUP"
	FangsHeist.Net.round2_theme = "EFPYRA"
	FangsHeist.Net.escape_hurryup = true
	FangsHeist.Net.escape_on_start = false

	FangsHeist.Net.last_man_standing = false

	FangsHeist.Net.round_2 = false
	FangsHeist.Net.round_2_teleport = {}

	FangsHeist.Net.hurry_up = false

	-- Your custom escape themes are powerless against the unfettered might of Wario.
	/*
	if info.fh_escapetheme then
		FangsHeist.Net.escape_theme = info.fh_escapetheme
	end
	if info.fh_round2theme then
		FangsHeist.Net.round2_theme = info.fh_round2theme
	end
	*/
	if info.fh_escapehurryup then
		FangsHeist.Net.escape_hurryup = info.fh_escapehurryup:lower() == "true"
	end

	-- don't get paid enough to figure out what these do
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

		-- Round 2 portal would conflict with the actual escape portal in design, so that means no
		-- Final Demo zones for you
		-- (really I don't want more things to port from Gamemodes/Escape)

		if whatSigns[thing.type] then
		
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

function gamemode:playerinit(p)
	self.super.playerinit(self, p)
	p.heist.treasure = 0
end

function gamemode:playerspawn(p)
	if not FangsHeist.Net.escape then return end

	local pos = FangsHeist.Net.signpos

	p.treasure = 0
end

function gamemode:playerdeath(p)
	if FangsHeist.Net.pregame then return end

	WL_SpawnCoins(p.mo, p.heist.treasure)
end

function gamemode:playerthink(p)
	self.super.playerthink(self, p)

	if p.heist
	and p.mo
	and p.mo.valid
	and p.heist.intangible then
		intangiblePlayer(p)
	end
end

function gamemode:start()
	local team = FangsHeist.initTeamTable()
	local rest = FangsHeist.initTeamTable()

	local hskins = {} -- important

	for p in players.iterate do
		if p and p.heist then
			table.insert(rest, p)
		end
	end

	if #rest > 3 then
		for i = 1, max(3, #rest/3) do
			local i = P_RandomRange(1, #rest)
			local p = rest[i]

			table.remove(rest, i)
			table.insert(team, p)
		end
	else
		team = rest
		rest = FangsHeist.initTeamTable()
	end

	for i = 1, #team do
		local p = team[i]

		table.insert(hskins, {
			skin = p.skin,
			color = p.skincolor,
			plyr = p
		})
	end

	FangsHeist.Net.officers = rest
	FangsHeist.Net.heisters = team
	FangsHeist.Net.hskins = hskins

	FangsHeist.Net.teams = {
		FangsHeist.Net.heisters,
		FangsHeist.Net.officers
	}

	for i = 2, #FangsHeist.Net.heisters do
		local p = FangsHeist.Net.heisters[i]

		if p and p.valid and p.heist then
			p.heist.intangible = true
		end
	end

	FangsHeist.Net.current_runner = FangsHeist.Net.heisters[1]
end

function gamemode:update()
	self.super.update(self)

	if FangsHeist.Net.pregame then return end
	FangsHeist.Net.exit_deb = max(0, $-1)
	FangsHeist.Net.headstart = max(0, $-1)

	local player = FangsHeist.Net.current_runner

	if not (player and player.valid and player.heist and player.heist:isAlive())
	and endCheck() then
		return
	end

	if FangsHeist.Net.swap_runner
	and #FangsHeist.Net.heisters >= 2 then
		FangsHeist.Net.swap_runner = $-1

		if not FangsHeist.Net.swap_runner then
			local ableToSwapTo = {}
			local swapFrom = FangsHeist.Net.current_runner
			local swapTo

			for _,p in ipairs(FangsHeist.Net.heisters) do
				if not (p
				and p.valid
				and p.heist
				and p.mo
				and p.mo.valid) then
					continue
				end

				if p.heist.intangible then
					table.insert(ableToSwapTo, p)
				end
			end

			if #ableToSwapTo then
				swapTo = ableToSwapTo[P_RandomRange(1, #ableToSwapTo)]
			end

			if swapFrom and swapTo then
				respawnPlayer(swapTo)

				P_SetOrigin(swapTo.mo,
					swapFrom.mo.x,
					swapFrom.mo.y,
					swapFrom.mo.z)
				swapFrom.mo.momx = swapTo.mo.momx
				swapFrom.mo.momy = swapTo.mo.momy
				swapFrom.mo.momz = swapTo.mo.momz
		
				swapTo.drawangle = swapFrom.drawangle
				swapTo.mo.angle = swapFrom.mo.angle
		
				if swapFrom.heist:hasSign() then
					FangsHeist.giveSignTo(swapTo)
				end
	
				for i = #swapFrom.heist.treasures, 1, -1 do
					local tres = swapFrom.heist.treasures[i]
		
					table.remove(swapFrom.heist.treasures, i)
					table.insert(swapTo.heist.treasures, tres)

					tres.mobj.target = swapTo.mo
					tres.mobj.index = #swapTo.heist.treasures
				end
	
				FangsHeist.Net.current_runner = swapTo
				FangsHeist.Net.exit_deb = 5
				swapFrom.heist.intangible = true
			end
	
			FangsHeist.Net.swap_runner = SWAP_TIME
		end
	end
end

function gamemode:trackplayer(p)
	if p.heist.intangible then
		return {}
	end

	local lp = displayplayer
	local team = lp.heist:getTeam()
	local args = {}

	if p == FangsHeist.Net.current_runner then
		table.insert(args, "RUNNER")
	end

	return args
end

function gamemode:sync(sync)
	self.super.sync(self, sync)

	FangsHeist.Net.officers = sync($)
	FangsHeist.Net.heisters = sync($)
	FangsHeist.Net.hskins = sync($)
	FangsHeist.Net.last_team_member = sync($)
	FangsHeist.Net.queues = sync($)
	FangsHeist.Net.headstart = sync($)
	FangsHeist.Net.swap_runner = sync($)
	FangsHeist.Net.current_runner = sync($)
	FangsHeist.Net.exit_deb = sync($)
	FangsHeist.Net.profit_quota = sync($)
end

function gamemode:shouldend() end -- shouldnt end manually

function gamemode:shouldinstakill(p, sp)
	return sp.heist.health <= 1
end

function gamemode:playerdamage(p)
	p.heist.health = max(1, $-1)
end

function gamemode:playerexit(p)
	if FangsHeist.Net.exit_deb then
		return true
	end
	if FangsHeist.Net.heisters.profit < FangsHeist.Net.profit_quota then
		return true
	end

	local team = p.heist:getTeam()

	if team == FangsHeist.Net.officers then
		return true
	end

	if team == FangsHeist.Net.heisters then
		for p in players.iterate do
			local team = p.heist and p.heist:getTeam()

			if team == FangsHeist.Net.officers then
				p.heist.spectator = true
			end
		end

		FangsHeist.startIntermission()
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
		for _, p in ipairs(FangsHeist.Net.heisters) do
			if p
			and p.valid
			and p.heist then
				p.heist.spectator = true
			end
		end

		FangsHeist.startIntermission()
		HeistHook.runHook("TimeUp")
	end
end

function gamemode:music()
	local song, loop, vol = self.super.music(self)

	if song ~= "FHTUP"
	and FangsHeist.Net.last_team_member then
		return "LARUST", true, vol
	end

	return song, loop, vol
end

local function blacklist(self, p)
	local team = p.heist:getTeam()

	return team == FangsHeist.Net.officers
end

gamemode.signblacklist = blacklist
gamemode.treasureblacklist = blacklist

addHook("ShouldDamage", function(t)
	if not FangsHeist.isMode() then return end
	if FangsHeist.Net.game_over then return end
	if FangsHeist.Net.pregame then return end

	local gamemode = FangsHeist.getGamemode()

	if gamemode.index ~= FangsHeist.TagTeam then return end

	if t
	and t.valid
	and t.player
	and t.player.valid
	and t.player.heist
	and t.player.heist.intangible then
		return false
	end
end, MT_PLAYER)
addHook("ShouldDamage", function(_,_,t)
	if not FangsHeist.isMode() then return end
	if FangsHeist.Net.game_over then return end
	if FangsHeist.Net.pregame then return end

	local gamemode = FangsHeist.getGamemode()

	if gamemode.index ~= FangsHeist.TagTeam then return end

	if t
	and t.valid
	and t.player
	and t.player.valid
	and t.player.heist
	and t.player.heist.intangible then
		return false
	end
end)

return FangsHeist.addGamemode(gamemode)