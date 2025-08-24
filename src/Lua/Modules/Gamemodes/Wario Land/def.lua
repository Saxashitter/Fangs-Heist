local copy = FangsHeist.require "Modules/Libraries/copy"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Escape])

local function printTable(data, prefix)
	prefix = prefix or ""
	if type(data) == "table"
		for k, v in pairs(data or {}) do
			local key = prefix .. k
			if type(v) == "table" then
				print("key " .. key .. " = a table:")
				printTable(v, key .. ".")
			else
				print("key " .. key .. " = " .. tostring(v))
			end
		end
	else
		print(data)
	end
end

local path = "Modules/Gamemodes/Wario Land/"
dofile(path.."freeslots.lua")

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
-- values can be int32 or table with {time, iswar}
-- time is an int32 where its value is the time to escape in seconds
-- usually calculated via (timetoescapelevel) + 60
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

-- FIXME: **PLEASE** make this automatically steal from Gamemodes/Escape's preexisting sign defintions in the future!
local whatSigns = {
	[501] = true
}

-- Hack!! probably but atleast it synchs with Escape/def/gamemode.signThings
-- Saxa your API is like stinky and stuff

-- SAXA: hey,,, did you know you copied all the values from escape
-- think of it as a github fork
local whatSigns = gamemode.signThings

-- mobj_t mo
-- int32 count
-- int32? maxdrop (optional, limits total spawned to <= count)
-- returns the remainder (count - actually spawned)
local function WL_SpawnCoins(mo, count, maxdrop)
	if not (mo and count) then return count end
	
	-- Restrict total drop if maxdrop is given
	local tospawn = count
	if maxdrop and maxdrop < tospawn then
		tospawn = maxdrop
	end
	
	local remaining = tospawn
	
	while remaining > 0 do
		local coin = nil
		
		if remaining >= 500 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND500COIN)
			remaining = $ - 500
		elseif remaining >= 100 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND100COIN)
			remaining = $ - 100
		elseif remaining >= 50 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND50COIN)
			remaining = $ - 50
		elseif remaining >= 10 then
			coin = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WARIOLAND10COIN)
			remaining = $ - 10
		else
			-- less than 10 left, break to avoid endless loop
			break
		end
		
		if coin then
			coin.angle = FixedAngle(P_RandomRange(0, 360)*FRACUNIT)
		end
	end
	
	-- Return what wasn't spawned
	-- If maxdrop was given, that's (count - maxdrop) + remaining
	-- Else just the leftover from count
	return (count - tospawn) + remaining
end

function gamemode:init(map)
	local info = mapheaderinfo[map]

	FangsHeist.Net.escape = false
	FangsHeist.Net.escape_theme = "HRRYUP"
	FangsHeist.Net.round2_theme = "EFPYRA"
	FangsHeist.Net.escape_hurryup = true
	FangsHeist.Net.escape_on_start = false
	FangsHeist.Net.keroAnimClock = 0

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
	-- SAXA: vro this is th code to enable rlund 2
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
	elseif gamemode.keroTimers[G_BuildMapTitle(map)] then
		time = gamemode.keroTimers[G_BuildMapTitle(map)]
	end

	-- Does Wario Land 4 reaaaallly need this
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
		if thing.type == 3844 then
			exit = thing
		end

	-- Round 2 portal would conflict with the actual escape portal in design, so that means no Final Demo zones for you
	-- (really I don't want more things to port from Gamemodes/Escape)

		-- holy shit takis reference
		if whatSigns[thing.type] then
			local x = thing.x*FRACUNIT
			local y = thing.y*FRACUNIT
			local whatSec = R_PointInSubsector(x, y).sector
			local z = thing.z * FRACUNIT + whatSec.floorheight
			if not thing.mobj then
				print("Shit fucked up! No mobj for current sign!! Saxa you're no longer invited to my birthday party >:(")
			end
			P_SpawnMobj(x, y, z, MT_KOMBIFROGSWITCH)
			if (thing.mobj and thing.mobj.valid) P_RemoveMobj(thing.mobj) end
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

	printTable(FangsHeist.Carriables.FindCarriables)
	for k, v in ipairs(FangsHeist.Carriables.FindCarriables("Sign")) do
		print(v.profit)
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

	p.heist.treasure = 0
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
			p.heist.treasure = 0
		end
	end
end

function gamemode:update()
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

function gamemode:shouldend() end -- shouldnt end manually

function gamemode:shouldinstakill(p, sp)
	return sp.heist.health <= 1
end

function gamemode:playerdamage(p)
	WL_SpawnCoins(p.mo, p.heist.treasure, gamemode.treasuredrop)
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
		FangsHeist.Net.wl4_coin_loss = true
		local linedef = tonumber(mapheaderinfo[gamemap].fh_timeuplinedef)

		if linedef ~= nil then
			P_LinedefExecute(linedef)
		end

		HeistHook.runHook("TimeUp")
	end
end

function gamemode:music()
	local song, loop, vol = self.super.music(self)

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

-- We probably don't even need this
rawset(_G, 'L_DecimalFixed', function(str)
	if str == nil return nil end
	local dec_offset = string.find(str,'%.')
	if dec_offset == nil
		return (tonumber(str) or 0)*FRACUNIT
	end
	local whole = tonumber(string.sub(str,0,dec_offset-1)) or 0
	local decstr = string.sub(str,dec_offset+1)
	local decimal = tonumber(decstr) or 0

	if(decimal==0)
		decstr = "0"
	end

	whole = $ * FRACUNIT
	local dec_len = string.len(decstr)
	decimal = $ * FRACUNIT / (10^dec_len)
	return whole + decimal
end)

local pressanimframes = TICRATE/3
local pause = TICRATE
local unpressanimframes = TICRATE
local pauseby = 8 -- real game pauses after 14@60FPS.
local letgoby = 125 -- TODO: What kinda fraction am i expected to just. GUESS to make 125.41666666667 with TICRATE = 35?? Use the raw form for now (which WILL break if someone raises TICRATE for whatever reason)
local presstotalmovement = FRACUNIT*12
local unpresstotalmovement = FRACUNIT*16
local clockspin = FixedAngle(L_DecimalFixed("13.125"))
local hurryuptimermoveoffset = 24

-- Hooks for the Frog Switch and its animator objects
-- MT_KOMBIFROGSWITCH is the thinker
-- MT_FROGSWITCHANIMATOR is the animator
-- Yes I am still gonna call them that in-code and you aren't gonna stop me...
-- Think of it as a signature of sorts...

-- Frog Switch's eye color remappers
-- Expected to be a table with 4 items because I'm stupid
local frogSwitchEyeRemaps = {
	SKINCOLOR_KOMBI_FROGSWITCH,
	SKINCOLOR_KOMBI_FROGSWITCH,
	SKINCOLOR_RED,
	SKINCOLOR_YELLOW,
}

addHook("MobjSpawn", function(switch)
	for i = 1, 3 do
		local part = P_SpawnMobjFromMobj(switch, 0, 0, 0, MT_FROGSWITCHANIMATOR)
		part.tracer = switch
		part.frame = i
		part.dispoffset = 5-i
	end
	switch.alpha = 0
end, MT_KOMBIFROGSWITCH)

addHook("MobjCollide", function(switch, mo)
	if FangsHeist.Net.escape return end
	if not mo or not mo.valid return end
	if mo.type ~= MT_PLAYER return end
	local relzpos = mo.z - switch.z
	if relzpos == 74*FRACUNIT or relzpos == mo.height + 74*FRACUNIT -- TODO: Make these checks better.
		if abs(mo.momz) <= 2*FRACUNIT
			K_PunchFrogSwitch(0, switch.escapetype, switch.portal) -- PASSES: (Time Defecit, Escape Type, Portals to Open)
		end
	end
end, MT_KOMBIFROGSWITCH)

--- Pauses the player.
--- @param player table The player to pause.
--- @return nil
local function K_PauseMomentum(player) -- stop the player
	if not player.paused
		player.oldvel = {x = player.mo.momx, y = player.mo.momy, z = player.mo.momz, angle = player.drawangle}
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.paused = true
		player.freezeframe = player.mo.frame
		player.freezesprite2 = player.mo.sprite2
	end
end

--- Resumes the player.
--- This assumes you have ran K_PauseMomentum previously.
--- @param player table The player to resume.
--- @return nil
local function K_ResumeMomentum(player)
	if player.paused
		if player.oldvel
			player.mo.momx = player.oldvel.x
			player.mo.momy = player.oldvel.y
			player.mo.momz = player.oldvel.z
		end
		player.paused = false
	else
		error("Call to K_ResumeMomentum to an unpaused player!", 1)
	end
end

addHook("ThinkFrame", function()
	if not FangsHeist.Net.escape then FangsHeist.Net.keroAnimClock = 0 return end
	FangsHeist.Net.keroAnimClock = $ + 1
	local clock = FangsHeist.Net.keroAnimClock
	if clock <= pauseby
		for player in players.iterate do
			if clock == pauseby
				K_PauseMomentum(player)
			else
				if player.wl4kombitime then player.wl4kombitime = $ - 1 end
			end
		end
	end
	if clock == letgoby then
		for player in players.iterate do
			K_ResumeMomentum(player)
		end
	end
end)

addHook("MobjThinker", function(mobj)
	if not mobj.corrected then
		mobj.scale = $*2
		mobj.corrected = true
	end
	if mobj.spawnpoint and not mobj.escapetype
		mobj.escapetype = mobj.spawnpoint.args[0] or mobj.spawnpoint.extrainfo
		mobj.portal = mobj.spawnpoint.tag
	end
	local clock = FangsHeist.Net.keroAnimClock
	if clock - pause == pressanimframes
		local part = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_FROGSWITCHANIMATOR)
		part.corrected = true
		part.tracer = mobj
		part.frame = E
		part.dispoffset = 1
	end
end, MT_KOMBIFROGSWITCH)

addHook("MobjThinker", function(mobj)
	if not mobj.corrected then
		mobj.scale = $*2
		mobj.corrected = true
	end
	local frame = mobj.frame
	if frame == D return end

	local mainbody = mobj.tracer
	if not mainbody return end

	local animClock = FangsHeist.Net.keroAnimClock
	local isPressing = animClock < pressanimframes
	local isUnpressing = (animClock - pause) >= pressanimframes and (animClock - pause) <= (pressanimframes + unpressanimframes)
	local inPost = (animClock - pause) > (pressanimframes + unpressanimframes)

	if frame == B and not inPost
		mobj.color = SKINCOLOR_KOMBI_FROGSWITCH
	end

	if isPressing
		if frame ~= B return end
		local t = FixedDiv(animClock, pressanimframes)
		if (mobj.eflags & MFE_VERTICALFLIP) ~= 0
			mobj.z = mainbody.z + ease.outback(t, 0, presstotalmovement)
		else
			mobj.z = mainbody.z - ease.outback(t, 0, presstotalmovement)
		end
	elseif isUnpressing
		if frame > C return end
		local t = FixedDiv(animClock - pressanimframes - pause, unpressanimframes)
		if (mobj.eflags & MFE_VERTICALFLIP) ~= 0
			mobj.z = mainbody.z - ease.linear(t, 0, unpresstotalmovement)
			if frame == B
				mobj.z = mobj.z + presstotalmovement
			end
		else
			mobj.z = mainbody.z + ease.linear(t, 0, unpresstotalmovement)
			if frame == B
				mobj.z = mobj.z - presstotalmovement
			end
		end
	elseif frame == B and inPost
		mobj.color = frogSwitchEyeRemaps[(((animClock-pause-pressanimframes-unpressanimframes) / 4) % 4) + 1]
	end
end, MT_FROGSWITCHANIMATOR)

local coinLossTreasureWaitTics = 5

-- HUDs in ohio bro what is this
--[[
	local clocktype = CV_FindVar("timerres") -- Get the ConVar
	local offset = 8
	local center = 160 - offset
	local wltimeclr = SKINCOLOR_WHITE

	-- Function to determine timer color
	local function getTimeColor(ourtime)
		if ourtime <= 11 * TICRATE then
			return SKINCOLOR_RED
		elseif ourtime <= 31 * TICRATE then
			return SKINCOLOR_YELLOW
		else
			return SKINCOLOR_WHITE
		end
	end

	local function getClockSize(time)
		local internalScale
		if time < letgoby - hurryuptimermoveoffset then
			local freq = 10 * FRACUNIT
			local angle = FixedAngle(time * freq)
			local scaleOsc = abs(FixedMul(sin(angle), FRACUNIT/2))
			internalScale = FRACUNIT/2 + scaleOsc
			internalScale = min(internalScale, FRACUNIT)
		else
			internalScale = FRACUNIT
		end
		return internalScale
	end

	-- Draw Treasure Digit
	local function drawCoinDigit(v, xpos, ypos, scale, digit, flags, color)
		local patch = v.cachePatch("WLCOIN" .. digit)
		if patch then
			v.drawScaled(xpos, ypos, scale, patch, flags | V_SNAPTOTOP | V_PERPLAYER, v.getColormap(nil, color))
		end
	end

	-- Function to draw a digit at a given position
	-- Preferably, you SHOULDN'T use this! Use drawTimerDigits instead.
	local function drawDigit(v, xpos, ypos, scale, digit, color, flags, translation, forcescale)
		local patch = v.cachePatch("WLTIME" .. digit)
		if not patch then return 0 end

		local internalScale = forcescale or getClockSize(FangsHeist.Net.keroAnimClock)

		local trueScale = FixedMul(scale * FRACUNIT, internalScale)

		v.drawScaled(xpos, ypos, trueScale, patch, flags, v.getColormap(nil, color, translation))

		local patchWidth = patch.width or 8 -- fallback if width isn't defined
		local offset = FixedMul(patchWidth*FRACUNIT, trueScale)
		return offset, internalScale
	end

	-- Function to draw the escape clock digits
	local function drawTimerDigits(v, xpos, ypos, timeValue, color, size, flags, translation, forcescale)
		local xpos = xpos < FRACUNIT and xpos * FRACUNIT or xpos
		local ypos = ypos < FRACUNIT and ypos * FRACUNIT or ypos
		local timeStr = tostring(timeValue)
		local curFlags = flags or (V_SNAPTOTOP|V_PERPLAYER)
		local offset
		local finalSize
		for i = 1, #timeStr do
			local char = timeStr:sub(i, i)
			offset, finalSize = drawDigit(v, xpos, ypos, size, char, color, curFlags, translation, forcescale)
			xpos = $ + offset
		end
		return xpos, finalSize
	end

	-- Function to draw the clock animation
	local function drawClockAnimation(v, xpos, ypos, frame)
		local patch = v.getSpritePatch(SPR_WL4STOPWATCH, frame, 0, 0)
		if patch then
			v.draw(xpos, ypos, patch, V_SNAPTOTOP | V_PERPLAYER)
		end
	end

	-- Function to handle different timer display modes
	local function WL4HUD_KeroClock(v, player)
		if not player.mo then return end
		local mapOK = FangsHeist.Net.escape
		if not mapOK then return end

		local centerX, baseY = center - 8, hudinfo[HUD_SCORE].y * FRACUNIT
		local coinTics = kombi.coinlossticks or 0
		-- If coin-loss animation active, just draw the stopwatch:
		if coinTics > coinLossTreasureWaitTics - 1 then
			drawClockAnimation(v, centerX - 8, (baseY / FRACUNIT) + 8, ((player.wl4kombitime) / 3) % 6 or 0)
			return
		end

		local clockScale = getClockSize(FangsHeist.Net.keroAnimClock)

		local yoffset = 0
		if FangsHeist.Net.wl4_coin_loss then
			yoffset = coinTics * -7 * FRACUNIT
		elseif FangsHeist.Net.keroAnimClock >= letgoby - hurryuptimermoveoffset
			yoffset = ease.linear(min(FixedDiv(FangsHeist.Net.keroAnimClock - (letgoby - hurryuptimermoveoffset), hurryuptimermoveoffset), FRACUNIT), ((100 - 8) * FRACUNIT) - baseY, 0)
		else
			yoffset = ((100 * FRACUNIT) - baseY) + (-8 * clockScale)
		end
		local frame   = ((player.wl4kombitime) / 3) % 6 or 0
		local mode    = clocktype.value
		local clr     = getTimeColor(kombi.disptime)

		-- build the two strings to draw:
		local bigDigits, smallDigits = "", ""
		if mode == 3 then
			-- Tics mode: just render the precomputed display time
			bigDigits = tostring(kombi.disptime)
		else
			-- Mania/CD or Classic mode
			local mins = kombi.timeleftmins
			local secs = kombi.timeleftsecs
			local cents = kombi.timeleftcents
			local overflow = mins > 9
			local drawDots = kombi.disptime % 35 < 18

			-- big part: MM:SS (or M:SS if no overflow)
			if overflow then
				bigDigits = string.format("%02d", mins)
			else
				bigDigits = string.format("%1d", mins % 10)
			end

			if not overflow then
				if drawDots then
					bigDigits = $ .. "C"
				else
					bigDigits = $ .. " "
				end
			end

			bigDigits = $ .. string.format("%02d", secs)

			-- the small centiseconds only in mania/CD modes:
			if mode == 1 or mode == 2 then
				if drawDots then
					smallDigits = "D"
				else
					smallDigits = " "
				end
				smallDigits = $ .. string.format("%02d", cents)
			end
		end

		-- now draw everything in one go:
		-- big digits at scale 2
		local xPos = ((centerX + (#bigDigits * 8)) * FRACUNIT) - #bigDigits * 8 * clockScale
		local xadd = drawTimerDigits(v, xPos, baseY + yoffset, bigDigits, clr, 2)

		-- small digits at scale 1, offset under the big ones
		if #smallDigits > 0 then
			-- push them right so they line up under the seconds
			local smallX = xadd -- centerX + (#bigDigits) * offset
			local smallY = baseY + (15 * clockScale) + yoffset
			drawTimerDigits(v, smallX, smallY, smallDigits, clr, 1)
		end

		-- finally, draw the clock animation
		drawClockAnimation(v, centerX - 8, (baseY / FRACUNIT) + 8, frame)
	end

	-- Function to handle treasure display
	local function WL4HUD_Treasure(v, player)
		local mapinfo = mapheaderinfo[gamemap]
		if not mapinfo then return end

		local alpha = 0

		local coinlossticks = max((FangsHeist.Net.keroCoinLossTicks or 0) - coinLossTreasureWaitTics, 0)
		local flags = coinlossticks < 1 and V_SNAPTORIGHT or 0
		local xoffset = coinlossticks > 7 and -46*FRACUNIT or coinlossticks * -7*FRACUNIT
		local size = coinlossticks > 7 and FRACUNIT*2 or FRACUNIT

		local xpos = (320 * FRACUNIT) + xoffset - ((offset * size) * 8) - size
		local ypos = (hudinfo[HUD_SCORE].y + 2) * FRACUNIT

		v.drawScaled(xpos, ypos, size, v.cachePatch("WLCOIN$"), alpha | V_SNAPTOTOP | V_PERPLAYER | flags)

		for i = 0, 5 do
			local frame = (player.heist.treasure or 0) / (10 ^ i) % 10
			drawCoinDigit(v, (320 * FRACUNIT) + xoffset - ((offset * size) * (2 + i)), ypos, size, frame, alpha | flags, SKINCOLOR_WHITE)
		end
	end

hud.add(WL4HUD_KeroClock)
hud.add(WL4HUD_Treasure)]]

return FangsHeist.addGamemode(gamemode)