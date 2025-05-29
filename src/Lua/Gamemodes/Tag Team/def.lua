local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Escape])

gamemode.name = "Tag Team"
gamemode.desc = "5 players form a tag team, while the rest of the server has to try and kill them!"
gamemode.id = "TAG"
gamemode.tol = TOL_HEIST
gamemode.spillallrings = true
gamemode.teams = false
gamemode.super = FangsHeist.Gamemodes[FangsHeist.Escape]

local function intangiblePlayer(p)
	local follow

	for sp in players.iterate do
		if not (sp
		and sp.heist
		and not sp.heist.spectator
		and not sp.heist.intangible
		and sp.mo
		and sp.mo.health
		and sp.heist:getTeam() == FangsHeist.Net.heisters) then
			continue
		end

		follow = sp
		break
	end

	p.mo.state = S_INVISIBLE
	p.mo.flags2 = $|MF2_DONTDRAW
	p.pflags = ($|PF_GODMODE|PF_INVIS|PF_NOCLIP|PF_FULLSTASIS) & ~PF_SPINNING|PF_JUMPED
	p.powers[pw_flashing] = 2

	p.mo.momx = follow.mo.momx
	p.mo.momy = follow.mo.momy
	p.mo.momz = follow.mo.momz

	if not (follow and follow.valid) then
		return
	end

	P_SetOrigin(p.mo, follow.mo.x, follow.mo.y, follow.mo.z)
	p.cmd.angleturn = follow.cmd.angleturn
end

local function respawnPlayer(p)
	p.pflags = $ & ~(PF_GODMODE|PF_INVIS|PF_NOCLIP)
	p.mo.flags2 = $ & ~MF2_DONTDRAW
	p.mo.state = S_PLAY_STND

	p.heist.intangible = false
end

local function endCheck()
	for i = 1, #FangsHeist.Net.heisters do
		 local plyr = FangsHeist.Net.heisters[i]

		if plyr
		and plyr.valid
		and plyr.heist
		and not plyr.heist.spectator
		and plyr ~= p then
			respawnPlayer(plyr)
			if #FangsHeist.Net.heisters <= 2 then
				FangsHeist.Net.last_team_member = true
			end

			return false
		end
	end

	FangsHeist.startIntermission(p)
	return true
end

function gamemode:queueTeleport(p)
	table.insert(FangsHeist.Net.queues, p)
end

function gamemode:init(map)
	self.super.init(self, map)

	FangsHeist.Net.last_team_member = false
	FangsHeist.Net.queues = {}
end

function gamemode:playerinit(p)
	self.super.playerinit(self, p)
	p.heist.intangible = false
	if FangsHeist.Net.pregame then return end

	p.heist.spectator = true
	p.spectator = true
end

function gamemode:playerdeath(p)
	if FangsHeist.Net.pregame then return end

	local team = p.heist:getTeam()

	if team == FangsHeist.Net.heisters then
		p.heist.spectator = true
		endCheck(p)
	end
end

function gamemode:playerthink(p)
	self.super.playerthink(self, p)

	if p.heist
	and p.mo
	and p.mo.valid
	and p.heist.intangible then
		intangiblePlayer(p)
	end
end

function gamemode:start()
	local team = FangsHeist.initTeamTable()
	local rest = FangsHeist.initTeamTable()

	local hskins = {} -- important

	for p in players.iterate do
		if p and p.heist then
			table.insert(rest, p)
		end
	end

	if #rest > 3 then
		for i = 1, max(3, #rest/3) do
			local i = P_RandomRange(1, #rest)
			local p = rest[i]

			table.remove(rest, i)
			table.insert(team, p)
			table.insert(hskins, {
				skin = p.skin,
				color = p.skincolor,
				plyr = p
			})
		end
	else
		team = rest
		rest = FangsHeist.initTeamTable()
	end

	FangsHeist.Net.officers = rest
	FangsHeist.Net.heisters = team
	FangsHeist.Net.hskins = hskins

	FangsHeist.Net.teams = {
		FangsHeist.Net.heisters,
		FangsHeist.Net.officers
	}

	for i = 2, #FangsHeist.Net.heisters do
		local p = FangsHeist.Net.heisters[i]

		if p and p.valid and p.heist then
			p.heist.intangible = true
		end
	end
end

function gamemode:update()
	self.super.update(self)

	if FangsHeist.Net.pregame then return end

	local playerFound = false
	for p in players.iterate do
		if p
		and p.heist
		and not p.heist.spectator
		and not p.heist.spectator_not_dead
		and p.heist:getTeam() == FangsHeist.Net.heisters then
			playerFound = true
			break
		end
	end

	if not playerFound then
		endCheck()
	end
end

function gamemode:sync(sync)
	self.super.sync(self, sync)

	FangsHeist.Net.officers = sync($)
	FangsHeist.Net.heisters = sync($)
	FangsHeist.Net.hskins = sync($)
	FangsHeist.Net.last_team_member = sync($)
	FangsHeist.Net.queues = sync($)
end

function gamemode:shouldend() end -- shouldnt end manually

function gamemode:playerexit(p)
	local team = p.heist:getTeam()

	if team == FangsHeist.Net.officers then
		return true
	end

	if team == FangsHeist.Net.heisters then
		for p in players.iterate do
			local team = p.heist and p.heist:getTeam()

			if team == FangsHeist.Net.officers then
				p.heist.spectator = true
			end
		end

		FangsHeist.startIntermission()
	end
end

function gamemode:music()
	local song, loop, vol = self.super.music(self)

	if song ~= "FHTUP"
	and FangsHeist.Net.last_team_member then
		return "BUAMO", true, vol
	end

	return song, loop, vol
end

local function blacklist(self, p)
	local team = p.heist:getTeam()

	return team == FangsHeist.Net.officers
end

gamemode.signblacklist = blacklist
gamemode.treasureblacklist = blacklist

addHook("PreThinkFrame", do
	if not FangsHeist.isMode() then return end
	if FangsHeist.Net.game_over then return end
	if FangsHeist.Net.pregame then return end

	local gamemode = FangsHeist.getGamemode()

	if gamemode.index ~= FangsHeist.TagTeam then return end

	for p in players.iterate do
		if p
		and p.heist
		and p.heist:isAlive()
		and p.heist.intangible then
			p.cmd.buttons = 0
			p.cmd.sidemove = 0
			p.cmd.forwardmove = 0
		end
	end
end)

addHook("ShouldDamage", function(t)
	if not FangsHeist.isMode() then return end
	if FangsHeist.Net.game_over then return end
	if FangsHeist.Net.pregame then return end

	local gamemode = FangsHeist.getGamemode()

	if gamemode.index ~= FangsHeist.TagTeam then return end

	if t
	and t.valid
	and t.player
	and t.player.valid
	and t.player.heist
	and t.player.heist.intangible then
		return false
	end
end, MT_PLAYER)

return FangsHeist.addGamemode(gamemode)