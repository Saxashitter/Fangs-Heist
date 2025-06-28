local files = {}

function FH:Require(path)
	if not (files[path]) then
		files[path] = dofile(path)
	end

	return files[path]
end

local orig_net = FH:Require("modules/variables/net")
local orig_save = FH:Require("modules/variables/save")
local orig_plyr = FH:Require("modules/variables/player")

function FH:InitTeamData()
	local team = {}

	team.profit = 0
	team.added_sign = false
	team.treasures = 0

	return team
end

function FH:InitTeam(p)
	if not p.heist:IsAbleToTeam() then
		return
	end

	local team = FH:InitTeamData()
	team[1] = p

	table.insert(FH_NET.teams, team)
	return team
end

function FH:InitPlayer(p)
	local heist = FH:CopyTable(orig_plyr)

	heist.locked_skin = p.skin
	heist.player = p

	setmetatable(heist, FH.PlayerMT)
	p.heist = heist

	if not p.heist:IsPartOfTeam() then
		FH:InitTeam(p)
	end

	local gamemode = FH:GetGamemode()

	if FH_NET.pregame then
		heist.pregame_state = "character"
		FH.PregameStates["character"].enter(p)
	end

	gamemode:PlayerInit(p)

	FH_API:RunHook("PlayerInit", p)
end

function FH:InitMode(map)
	if not FH:IsMode() then
		return
	end

	FH_NET = FH:CopyTable(orig_net)

	local info = mapheaderinfo[map]
	local gamemode = FH:GetGamemode()

	--[[if FangsHeist.Save.last_map == map
	and not (info.fh_disableretakes == "true") then
		FangsHeist.Save.retakes = $+1
	else
		FangsHeist.Save.retakes = 0
	end]]

	--FangsHeist.Save.last_map = map

	gamemode:Init(map)

	for p in players.iterate do
		p.camerascale = FU
		FH:InitPlayer(p)
	end

	for _,obj in ipairs(FH_HUD) do
		local object = obj[2]

		if object.init then
			object.init()
		end
	end

	FH_API:RunHook("GameInit")
end

function FH:LoadMap()
	local gamemode = FH:GetGamemode()
	gamemode:Load()

	FH_API:RunHook("GameLoad")
end