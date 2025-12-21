local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Solo])

local path = "Modules/Gamemodes/Juggernaut/"
local super = FangsHeist.Gamemodes[FangsHeist.Solo]

gamemode.super = super
gamemode.name = "Juggernaut"
gamemode.desc = "Bleeeeh."
gamemode.id = "JUGGERNAUT"
gamemode.teamlimit = 1
gamemode.pregametheme = "FH_PG2"
gamemode.preferredhud = {
	pos = super.preferredhud.pos,
	rank = {
		enabled = true,
		string = function(profit)
			return ("Stun: "):format(FangsHeist.Net.juggernaut_awakening*FU/TICRATE)
		end
	},
	rings = super.preferredhud.rings,
	profit = super.preferredhud.profit,
	timer = super.preferredhud.timer
}

function gamemode:giveWinToTeam(team)
	local loser = team == FangsHeist.Net.coop_team and FangsHeist.Net.juggernaut_team or FangsHeist.Net.coop_team

	for _, p in ipairs(loser) do
		if not (p and p.valid and p.heist and not p.heist.spectator) then
			continue
		end

		p.heist.spectator = true
		if p.mo and p.mo.health then
			P_DamageMobj(p.mo, nil, nil, 999, DMG_INSTAKILL)
		end
	end

	FangsHeist.startIntermission()
end

function gamemode:init(map)
	super.init(self, map)

	if FangsHeist.Net.escape_theme == "FH_ESC" then
		FangsHeist.Net.escape_theme = "WCKEXP"
	end

	FangsHeist.Net.juggernaut_awakening = 10*TICRATE
end

function gamemode:start()
	super.start(self)

	local singular_team = FangsHeist.initTeamTable()
	for p in players.iterate do
		if not p.heist then continue end

		table.insert(singular_team, p)
	end

	if #singular_team < 2 then
		FangsHeist.startIntermission()
		return
	end

	FangsHeist.Net.teams = {}

	local juggernaut_team = FangsHeist.initTeamTable()
	local juggernaut_key = P_RandomRange(1, #singular_team)
	local juggernaut = singular_team[juggernaut_key]

	juggernaut_team[1] = juggernaut
	table.remove(singular_team, juggernaut_key)

	FangsHeist.Net.coop_team = singular_team
	FangsHeist.Net.juggernaut_team = juggernaut_team

	local mobj = P_SpawnMobj(juggernaut.mo.x,
		juggernaut.mo.y,
		juggernaut.mo.z + juggernaut.mo.height,
		MT_THOK)
	mobj.flags = MF_NOTHINK
	mobj.state = S_TTAG
	FangsHeist.Net.tracker = mobj

	FangsHeist.initTeam(singular_team)
	FangsHeist.initTeam(juggernaut_team)

	local spawn = self:getSignSpawn()

	P_SetOrigin(juggernaut.mo,
		spawn[1],
		spawn[2],
		spawn[3])
	juggernaut.drawangle = spawn[4]
	juggernaut.mo.angle = spawn[4]

	FangsHeist.Net.one_player_left = #singular_team >= 2
end

function gamemode:onTimeUp()
	self:giveWinToTeam(FangsHeist.Net.juggernaut_team)
end

function gamemode:onSignBank()
	self:giveWinToTeam(FangsHeist.Net.coop_team)
end

function gamemode:update()
	super.update(self)

	if FangsHeist.Net.game_over then
		return
	end

	if #FangsHeist.Net.juggernaut_team == 0 then
		self:giveWinToTeam(FangsHeist.Net.coop_team)
		return
	end

	if #FangsHeist.Net.coop_team == 0 then
		self:giveWinToTeam(FangsHeist.Net.juggernaut_team)
		return
	end

	local j = FangsHeist.Net.juggernaut_team[1]

	if not (j and j.valid and j.mo and j.heist and j.heist:isAlive()) then
		FangsHeist.startIntermission()
		return
	end

	local t = FangsHeist.Net.tracker
	local z = j.mo.z + j.mo.height

	if j.mo.eflags & MFE_VERTICALFLIP then
		t.eflags = $|MFE_VERTICALFLIP
		z = j.mo.z - t.height
	else
		t.eflags = $ & ~MFE_VERTICALFLIP
	end

	P_MoveOrigin(t,
		j.mo.x,
		j.mo.y,
		z)

	if #FangsHeist.Net.coop_team <= 1
	and FangsHeist.Net.escape
	and not self:isHurryUp()
	and not FangsHeist.Net.two_teams_left
	and FangsHeist.Net.one_player_left then
		self:twoTeamsLeft(FangsHeist.Net.coop_team, FangsHeist.Net.juggernaut_team, "One player left.", "It's all or nothing!")
	end

	if FangsHeist.Net.juggernaut_awakening then
		if FangsHeist.Net.escape then
			FangsHeist.Net.juggernaut_awakening = $-1
		end

		if not FangsHeist.Net.juggernaut_awakening then
			if P_IsObjectOnGround(j.mo) then
				P_DoJump(j)
			else
				j.mo.state = S_PLAY_FALL
			end
		else
			j.mo.state = S_FH_JUGGERNAUTSLEEP
		end
	end
end

function gamemode:prethink()
	super.prethink(self)

	if FangsHeist.Net.game_over then return end

	if #FangsHeist.Net.juggernaut_team == 0
	or #FangsHeist.Net.coop_team == 0 then
		return
	end

	local j = FangsHeist.Net.juggernaut_team[1]

	if not (j and j.valid and j.mo and j.heist and j.heist:isAlive()) then
		return
	end

	if FangsHeist.Net.juggernaut_awakening then
		j.cmd.sidemove = 0
		j.cmd.forwardmove = 0
		j.cmd.buttons = 0
		j.powers[pw_flashing] = TICRATE
	end
end

function gamemode:signblacklist(p)
	if #FangsHeist.Net.juggernaut_team == 0
	or #FangsHeist.Net.coop_team == 0 then
		return
	end

	local j = FangsHeist.Net.juggernaut_team[1]

	if not (j and j.valid and j.mo and j.heist and j.heist:isAlive()) then
		return
	end

	return j == p
end

function gamemode:playerexit(p)
	return not p.heist:hasSign()
end

function gamemode:canExit()
	if not FangsHeist.Net.escape then return false end

	if not FangsHeist.Net.go_go_go then
		return false
	end

	return true
end

function gamemode:playerthink(p)
	super.playerthink(self, p)

	if FangsHeist.Net.game_over then return end
	if FangsHeist.Net.pregame then return end

	if not p.heist:isAlive() then return end

	local team, i = p.heist:getTeam()

	if team == FangsHeist.Net.coop_team
	or team == FangsHeist.Net.juggernaut_team then
		return
	end

	for k, v in ipairs(team) do
		if v == p then
			table.remove(team, k)
		end
	end

	if #team == 0 then
		table.remove(FangsHeist.Net.teams, i)
	end

	table.insert(FangsHeist.Net.coop_team, p)

	local has_team = false

	for k, v in ipairs(FangsHeist.Net.teams) do
		if v == FangsHeist.Net.coop_team then
			has_team = true
			break
		end
	end

	if not has_team then
		FangsHeist.initTeam(FangsHeist.Net.coop_team)
	end
end

function gamemode:startEscape(p)
	super.startEscape(self, p)
end

dofile(path.."juggernaut.lua")

return FangsHeist.addGamemode(gamemode)