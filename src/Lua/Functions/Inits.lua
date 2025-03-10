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

function FangsHeist.initTeam(p)
	if not FangsHeist.isAbleToTeam(p) then
		return
	end

	local team = {p}

	team.profit = 0
	team.added_sign = false
	team.treasures = 0

	table.insert(FangsHeist.Net.teams, team)
	return team
end

function FangsHeist.initPlayer(p)
	p.heist = copy(orig_plyr)
	p.heist.locked_skin = p.skin

	local gamemode = FangsHeist.gametypes[FangsHeist.Net.gametype]
	if gamemode.onPlayerInit then
		gamemode:onPlayerInit(p)
	end

	FangsHeist.initTeam(p)

	HeistHook.runHook("PlayerInit", p)
end

function FangsHeist.initMode(map)
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	local gamemode = FangsHeist.gametypes[FangsHeist.Net.gametype]

	if FangsHeist.Save.last_map == map
	and not (info.fh_disableretakes == "true") then
		FangsHeist.Save.retakes = $+1
	else
		FangsHeist.Save.retakes = 0
	end

	FangsHeist.Save.last_map = map

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

	if gamemode.onInit then
		gamemode:onInit(map)
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

function FangsHeist.loadMap()
	if not multiplayer
	and not FangsHeist.Net._inited then
		FangsHeist.initMode(gamemap)
	end

	--[[local exit
	local treasure_spawns = {}

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
	end]]

	local gamemode = FangsHeist.gametypes[FangsHeist.Net.gametype]
	gamemode:onLoad()

	HeistHook.runHook("GameLoad")
end