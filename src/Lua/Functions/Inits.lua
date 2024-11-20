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
local orig_hud = FangsHeist.require "Modules/Variables/hud"

// Initalize player.
function FangsHeist.initPlayer(p)
	p.heist = {}
	p.heist.scraps = 0
	p.heist.spectator = false
end

function FangsHeist.initMode()
	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	for p in players.iterate do
		FangsHeist.initPlayer()
	end
end

function FangsHeist.loadMap()
	local signpost = false

	for thing in mapthings.iterate do
		if thing.type == 501
		and not signpost then
			signpost = true

			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_THOK, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			local sign = P_SpawnMobj(x, y, z, MT_FH_SIGN)
			sign.fuse = -1
			sign.tics = -1
			sign.state = S_SIGN
			sign.angle = a

			print "Spawned sign!"
		end
	end
end