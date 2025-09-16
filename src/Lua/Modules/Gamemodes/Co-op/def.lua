local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Solo])

local path = "Modules/Gamemodes/Co-op/"
local super = FangsHeist.Gamemodes[FangsHeist.Solo]

gamemode.super = super
gamemode.name = "Co-op"
gamemode.desc = "Work together."
gamemode.id = "COOP"
gamemode.teamlimit = 1
gamemode.twoteamsleft = false
gamemode.preferredhud = {
	pos = super.preferredhud.pos,
	profit = {
		enabled = true,
		string = function(profit)
			if not FangsHeist.Net.escape then
				return string.char(1) .. " " .. profit
			end

			local format = string.char(1).." %d/%s%d"
			local col = "[c:red]"
			local quota = FangsHeist.Net.profit_quota

			if profit >= quota then
				col = "[c:green]"
			end
	
			return format:format(profit, col, quota)
		end
	},
	rings = super.preferredhud.rings,
	rank = super.preferredhud.rank,
	timer = super.preferredhud.timer
}

function gamemode:start()
	super.start(self)

	FangsHeist.Net.teams = {}
	local singular_team = FangsHeist.initTeamTable()

	for p in players.iterate do
		if not p.heist then continue end

		table.insert(singular_team, p)
	end

	FangsHeist.Net.coop_team = singular_team
	FangsHeist.initTeam(singular_team)
end

function gamemode:playerthink(p)
	super.playerthink(self, p)

	if FangsHeist.Net.pregame then return end
	if not p.heist:isAlive() then return end

	local team, i = p.heist:getTeam()

	if team == FangsHeist.Net.coop_team then
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
end

function gamemode:startEscape(p)
	super.startEscape(self, p)

	local team = p.heist:getTeam()

	-- TODO: determine a profit quota
	local rings = 0
	local monitors = 0
	local enemies = 0
	local leniency = tofixed("0.75")

	for mo in mobjs.iterate() do
		if mo.type == MT_RING then
			rings = $+1
			continue
		end

		if mo.flags & MF_MONITOR then
			monitors = $+1

			if mo.type == MT_RING_BOX then
				rings = $+10
			end

			continue
		end

		if mo.flags & MF_ENEMY then
			enemies = $+1
			continue
		end
	end

	local profit = ((rings * FH_RINGPROFIT)
		+ (enemies * FH_ENEMYPROFIT)
		+ (monitors * FH_MONITORPROFIT)
		+ (FH_SIGNPROFIT * 2))
		* leniency / FU

	FangsHeist.Net.profit_quota = profit
end

function gamemode:playerexit(p)
	local team = p.heist:getTeam()

	if team.profit < FangsHeist.Net.profit_quota then
		return true
	end
end

return FangsHeist.addGamemode(gamemode)