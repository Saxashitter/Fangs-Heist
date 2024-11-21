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
local orig_plyr = FangsHeist.require "Modules/Variables/player"
local orig_hud = FangsHeist.require "Modules/Variables/hud"

// Initalize player.
function FangsHeist.initPlayer(p)
	p.heist = copy(orig_plyr)
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

function FangsHeist.loadMap()
	local signpost = false
	local exit_gate = false

	for thing in mapthings.iterate do
		if thing.type == 501
		and not signpost then
			signpost = true

			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_FH_SIGN, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			local sign = P_SpawnMobj(x, y, z, MT_FH_SIGN)
			sign.angle = a

			FangsHeist.Net.sign = sign

			print "Spawned sign!"
		end

		if thing.type == 1
		and not exit_gate then
			exit_gate = true

			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_FH_SIGN, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			FangsHeist.defineExit(x, y, z, a)
			print "Spawned exit gate!"
		end
	end
end