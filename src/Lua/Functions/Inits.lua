local files = {}
// Used internally to get modules from the mod.
function FangsHeist.require(path)
	if not (files[path]) then
		files[path] = dofile(path)
	end

	return files[path]
end

local copy = FangsHeist.require "Modules/Libraries/copy"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

local orig_net = FangsHeist.require "Modules/Variables/net"
local orig_save = FangsHeist.require "Modules/Variables/save"
local orig_plyr = FangsHeist.require "Modules/Variables/player"
local orig_hud = FangsHeist.require "Modules/Variables/hud"

// Initalize player.
function FangsHeist.initPlayer(p)
	p.heist = copy(orig_plyr)
	p.heist.spectator = FangsHeist.Net.escape
	p.heist.locked_skin = p.skin
	p.heist.team.players[p] = true
	p.heist.team.leader = p

	HeistHook.runHook("PlayerInit", p)
end

function FangsHeist.initMode(map)
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	FangsHeist.Net.gametype = tonumber(mapheaderinfo[map].fh_gametype) or 0
	FangsHeist.Net.is_boss = string.lower(mapheaderinfo[map].fh_boss or "") == "true"

	local info = mapheaderinfo[map]

	if info.fh_escapetheme then
		FangsHeist.Net.escape_theme = info.fh_escapetheme
	end
	if info.fh_escapehurryup then
		FangsHeist.Net.escape_hurryup = info.fh_escapehurryup:lower() == "true"
	end

	if info.fh_hellstage
	and info.fh_hellstage:lower() == "true" then
		FangsHeist.Net.hell_stage = true
	end
	if info.fh_lastmanstanding
	and info.fh_lastmanstanding:lower() == "true" then
		FangsHeist.Net.last_man_standing = true
	end

	local time = FangsHeist.Net.time_left
	if FangsHeist.Save.last_map == map
	and not (info.fh_disableretakes == "true") then
		FangsHeist.Save.retakes = $+1

		-- time = max(30*TICRATE, $-((TICRATE*60)*FangsHeist.Save.retakes))
	else
		FangsHeist.Save.retakes = 0
	end

	if info.fh_time then
		time = tonumber(info.fh_time)*TICRATE
	end

	if FangsHeist.CVars.escape_time.value then
		time = FangsHeist.CVars.escape_time.value*TICRATE
	end

	FangsHeist.Save.last_map = map
	FangsHeist.Net.time_left = time
	FangsHeist.Net.max_time_left = time

	FangsHeist.Net.escape_on_start = (info.fh_escapeonstart == "true")

	for p in players.iterate do
		p.camerascale = FU
		FangsHeist.initPlayer(p)
	end

	for _,obj in ipairs(FangsHeist.Objects) do
		local object = obj[2]

		if object.init then
			object.init()
		end
	end

	HeistHook.runHook("GameInit")

	if not multiplayer then
		FangsHeist.Net._inited = true
	end
end

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

function FangsHeist.loadMap()
	if not multiplayer
	and not FangsHeist.Net._inited then
		FangsHeist.initMode(gamemap)
	end
	FangsHeist.spawnSign()

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
			FangsHeist.Net.hell_stage_teleport.pos = {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(MT_PLAYER, thing, thing.x*FU, thing.y*FU),
				a = thing.angle*ANG1
			}
		end

		if thing.type == 3843 then
			FangsHeist.Net.hell_stage_teleport.sector = R_PointInSubsector(thing.x*FU, thing.y*FU).sector
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

	HeistHook.runHook("GameLoad")
end