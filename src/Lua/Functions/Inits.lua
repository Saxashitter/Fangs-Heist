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
	p.heist.team[p] = true
	p.heist.team.leader = p
end

function FangsHeist.initMode(map)
	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	FangsHeist.Net.gametype = tonumber(mapheaderinfo[map].fh_gametype) or 0
	FangsHeist.Net.is_boss = string.lower(mapheaderinfo[map].fh_boss or "") == "true"

	if FangsHeist.Net.is_boss then
		FangsHeist.Net.time_left = ((2*60)*TICRATE)+(20*TICRATE)
		FangsHeist.Net.max_time_left = ((2*60)*TICRATE)+(20*TICRATE)
	end

	local data = FangsHeist.getTypeData()
	if data.start_timer then
		local choice = P_RandomRange(1, #FangsHeist.escapeThemes)

		while FangsHeist.Save.escape == FangsHeist.escapeThemes[choice] do
			choice = P_RandomRange(1, #FangsHeist.escapeThemes)
		end
		FangsHeist.Save.escape = FangsHeist.escapeThemes[choice]
		FangsHeist.Net.escape_theme = FangsHeist.escapeThemes[choice]
		FangsHeist.Net.escape_choice = choice
	end

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
end

local treasure_things = {
	[312] = true
}
local bean_things = {
	[402] = true,
	[408] = true,
	[409] = true
}

function FangsHeist.loadMap()
	local data = FangsHeist.getTypeData()

	if data.escape then
		FangsHeist.spawnSign()
	end

	local exit = false
	local treasure_spawns = {}

	for thing in mapthings.iterate do
		if thing.mobj
		and thing.mobj.valid
		and (thing.mobj.type == MT_ATTRACT_BOX
		or thing.mobj.type == MT_1UP_BOX
		or thing.mobj.type == MT_INVULN_BOX) then
			P_RemoveMobj(thing.mobj)
		end

		if treasure_things[thing.type] then
			table.insert(treasure_spawns, {
				x = thing.x*FU,
				y = thing.y*FU,
				z = spawnpos.getThingSpawnHeight(thing.type, thing, thing.x*FU, thing.y*FU)
			})
		end

		if thing.type == 1
		and not exit then
			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_FH_SIGN, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			FangsHeist.defineExit(x, y, z, a)
			exit = true
		end
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
end