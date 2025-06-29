local files = {}
// Used internally to get modules from the mod.
function FangsHeist.require(path)
	if not (files[path]) then
		files[path] = dofile(path)
	end

	return files[path]
end

local copy = FangsHeist.require "Modules/Libraries/copy"

local orig_net = FangsHeist.require "Modules/Variables/net"
local orig_save = FangsHeist.require "Modules/Variables/save"
local orig_plyr = FangsHeist.require "Modules/Variables/player"

// Initalize player.

function FangsHeist.initTeamTable()
	-- for use within gamemodes to force teams
	local team = {}

	team.profit = 0
	team.added_sign = false
	team.treasures = 0

	return team
end

function FangsHeist.initTeam(p)
	if not p.heist:isAbleToTeam() then
		return
	end

	local team = FangsHeist.initTeamTable()
	team[1] = p

	table.insert(FangsHeist.Net.teams, team)
	return team
end

function FangsHeist.initPlayer(p)
	local heist = copy(orig_plyr)

	heist.locked_skin = p.skin
	heist.player = p

	setmetatable(heist, FangsHeist.PlayerMT)
	p.heist = heist

	if not p.heist:isPartOfTeam() then
		FangsHeist.initTeam(p)
	end

	local gamemode = FangsHeist.getGamemode()

	if FangsHeist.Net.pregame then
		heist.pregame_state = "character"
		FangsHeist.pregameStates["character"].enter(p)
	end

	gamemode:playerinit(p)

	HeistHook.runHook("PlayerInit", p)
end

function FangsHeist.initMode(map)
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.Net = copy(orig_net)
	FangsHeist.Net.gamemode = 1

	local info = mapheaderinfo[map]
	local gamemode = FangsHeist.getGamemode()

	if FangsHeist.Save.last_map == map
	and not (info.fh_disableretakes == "true") then
		FangsHeist.Save.retakes = $+1
	else
		FangsHeist.Save.retakes = 0
	end

	FangsHeist.Save.last_map = map

	if info.fh_pregamecamx
	and info.fh_pregamecamy
	and info.fh_pregamecamz then
		local x = tonumber(info.fh_pregamecamx)*FU
		local y = tonumber(info.fh_pregamecamy)*FU
		local z = tonumber(info.fh_pregamecamz)*FU

		print(info.fh_pregamecamx)
		print(info.fh_pregamecamy)
		print(info.fh_pregamecamz)
		print(info.fh_pregamecamdist)

		local angle = FixedAngle((tonumber(info.fh_pregamecamangle) or 0)*FU)
		local dist = (tonumber(info.fh_pregamecamdist) or 0)*FU

		FangsHeist.Net.pregame_cam = {
			enabled = true,
			x = x,
			y = y,
			z = z,
			angle = angle,
			dist = dist
		}
	end

	gamemode:init(map)

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

function FangsHeist.loadMap()
	if not multiplayer
	and not FangsHeist.Net._inited then
		FangsHeist.initMode(gamemap)
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:load()

	HeistHook.runHook("GameLoad")
end