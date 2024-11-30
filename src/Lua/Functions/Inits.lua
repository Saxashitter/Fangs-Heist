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
end

function FangsHeist.initMode()
	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

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
	FangsHeist.spawnSign()

	local exit = false
	local treasure_spawns = {}
	local bean_spawns = {}

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

		if bean_things[thing.type] then
			table.insert(bean_spawns, {
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

	if #bean_spawns then
		local choice = P_RandomRange(1, #bean_spawns)
		local thing = bean_spawns[choice]

		FangsHeist.defineBean(thing.x, thing.y, thing.z)
		print("WE SPAWNED BEAN")
	end
end