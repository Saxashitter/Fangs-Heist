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

	FangsHeist.initTeam(p)

	local gamemode = FangsHeist.getGamemode()
	gamemode:playerinit(p)

	HeistHook.runHook("PlayerInit", p)
end

function FangsHeist.initMode(map)
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	FangsHeist.Net.gamemode = 1

	local info = mapheaderinfo[map]
	local gamemode = FangsHeist.getGamemode()

	if info.fh_stagetype then
		local stageTypes = {}
		local isCompatible = false

		for type in info.fh_stagetype:gmatch("[^,]+") do
			local type = type:gsub("%s+", "")
	
			table.insert(stageTypes, type)
	
			if type == gamemode.name then
				isCompatible = true
			end
		end

		if #stageTypes
		and not isCompatible then
			local foundMode = 0
			local setMode = stageTypes[1]

			for i,gt in ipairs(FangsHeist.Gamemodes) do
				if gt.name == setMode then
					foundMode = i
					break
				end
			end
	
			if foundMode then
				FangsHeist.Net.gamemode = foundMode
				gamemode = FangsHeist.getGamemode()
			end
		end
	end

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