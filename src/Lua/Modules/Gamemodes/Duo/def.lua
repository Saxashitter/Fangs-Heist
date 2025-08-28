local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Solo])

local path = "Modules/Gamemodes/Duo/"

gamemode.name = "Duo"
gamemode.id = "DUO"
gamemode.teamlimit = 2
gamemode.super = FangsHeist.Gamemodes[FangsHeist.Solo]

local function transferTeams(player, team)
	local last_team, last_team_i = player.heist:getTeam()
	
	if last_team then
		table.remove(FangsHeist.Net.teams, last_team_i)
	end

	table.insert(team, player)
end

function gamemode:start()
	local unteamedPlayers = {}

	for p in players.iterate do
		if not p.heist then continue end

		local team = p.heist:getTeam()

		if team and #team >= self.teamlimit then continue end

		table.insert(unteamedPlayers, p)
	end

	if #unteamedPlayers < self.teamlimit then
		self.super.start(self)
		return
	end

	while #unteamedPlayers >= self.teamlimit do
		local team = FangsHeist.initTeamTable()

		local leader_i = P_RandomRange(1, #unteamedPlayers)
		local leader = unteamedPlayers[leader_i]

		transferTeams(leader, team)
		table.remove(unteamedPlayers, leader_i)

		for i = 1, self.teamlimit - 1 do
			if #unteamedPlayers == 0 then break end

			local member_i = P_RandomRange(1, #unteamedPlayers)
			local member = unteamedPlayers[member_i]

			transferTeams(member, team)
			table.remove(unteamedPlayers, member_i)
		end

		FangsHeist.initTeam(team)
		team = FangsHeist.initTeamTable()
	end

	self.super.start(self)
end

return FangsHeist.addGamemode(gamemode)