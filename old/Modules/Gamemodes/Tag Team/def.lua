local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Escape])

gamemode.name = "Tag Team"
gamemode.desc = "5 players form a tag team, while the rest of the server has to try and kill them!"
gamemode.id = "TAG"
gamemode.tol = TOL_HEIST
gamemode.spillallrings = true
gamemode.teams = false
gamemode.super = FangsHeist.Gamemodes[FangsHeist.Escape]
gamemode.dontdivprofit = true

local SWAP_TIME = 30*TICRATE

local function intangiblePlayer(p)
	local follow

	p.mo.state = S_INVISIBLE
	p.mo.flags2 = $|MF2_DONTDRAW
	p.pflags = ($|PF_INVIS|PF_NOCLIP) & ~PF_SPINNING|PF_JUMPED
	p.powers[pw_flashing] = 3
	p.powers[pw_underwater] = 6*TICRATE
	p.powers[pw_spacetime] = 6*TICRATE
	p.mo.momx = 0
	p.mo.momy = 0
	p.mo.momz = 0
end

local function respawnPlayer(p)
	p.pflags = $ & ~(PF_INVIS|PF_NOCLIP)
	p.mo.flags2 = $ & ~MF2_DONTDRAW
	p.mo.state = S_PLAY_STND

	p.heist.intangible = false
	p.powers[pw_flashing] = 2*TICRATE

	gamemode:playerspawn(p)
end

local function endCheck()
	for i = 1, #FangsHeist.Net.heisters do
		 local plyr = FangsHeist.Net.heisters[i]

		if plyr
		and plyr.valid
		and plyr.heist
		and not plyr.heist.spectator then
			respawnPlayer(plyr)

			FangsHeist.Net.swap_runner = SWAP_TIME
			FangsHeist.Net.headstart = 2*TICRATE
			FangsHeist.Net.current_runner = plyr
			FangsHeist.Net.exit_deb = 5
			
			if #FangsHeist.Net.heisters <= 2 then
				FangsHeist.Net.last_team_member = true
			end

			return false
		end
	end

	FangsHeist.startIntermission(p)
	return true
end

function gamemode:init(map)
	self.super.init(self, map)

	FangsHeist.Net.last_team_member = false
	FangsHeist.Net.queues = {}

	FangsHeist.Net.exit_deb = 0
	FangsHeist.Net.headstart = 5*TICRATE
	FangsHeist.Net.swap_runner = SWAP_TIME
	FangsHeist.Net.profit_quota = 1500
end

function gamemode:playerinit(p)
	self.super.playerinit(self, p)
	p.heist.intangible = false
	p.heist.health = 10
	p.heist.maxhealth = 10

	if FangsHeist.Net.pregame then return end

	p.heist.spectator = true
	p.spectator = true
end

function gamemode:preplayerthink(p)
	if FangsHeist.Net.pregame then return end
	if p.heist.intangible
	or (FangsHeist.Net.headstart
	and p.heist:getTeam() == FangsHeist.Net.officers) then
		p.cmd.forwardmove = 0
		p.cmd.sidemove = 0
		p.cmd.buttons = 0
	end
end

function gamemode:playerspawn(p)
	if not FangsHeist.Net.escape then return end

	local pos = FangsHeist.Net.signpos

	if p.heist.reached_second
	and FangsHeist.Net.round_2_teleport
	and FangsHeist.Net.round_2_teleport.pos then
		pos = FangsHeist.Net.round_2_teleport.pos
	end

	P_SetOrigin(p.mo, pos[1], pos[2], pos[3])
	p.mo.angle = pos[4]
	p.drawangle = pos[4]
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
		end
	else
		team = rest
		rest = FangsHeist.initTeamTable()
	end

	for i = 1, #team do
		local p = team[i]

		table.insert(hskins, {
			skin = p.skin,
			color = p.skincolor,
			plyr = p
		})
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

	FangsHeist.Net.current_runner = FangsHeist.Net.heisters[1]
end

function gamemode:update()
	self.super.update(self)

	if FangsHeist.Net.pregame then return end
	FangsHeist.Net.exit_deb = max(0, $-1)
	FangsHeist.Net.headstart = max(0, $-1)

	local player = FangsHeist.Net.current_runner

	if not (player and player.valid and player.heist and player.heist:isAlive())
	and endCheck() then
		return
	end

	if FangsHeist.Net.swap_runner
	and #FangsHeist.Net.heisters >= 2 then
		FangsHeist.Net.swap_runner = $-1

		if not FangsHeist.Net.swap_runner then
			local ableToSwapTo = {}
			local swapFrom = FangsHeist.Net.current_runner
			local swapTo

			for _,p in ipairs(FangsHeist.Net.heisters) do
				if not (p
				and p.valid
				and p.heist
				and p.mo
				and p.mo.valid) then
					continue
				end

				if p.heist.intangible then
					table.insert(ableToSwapTo, p)
				end
			end

			if #ableToSwapTo then
				swapTo = ableToSwapTo[P_RandomRange(1, #ableToSwapTo)]
			end

			if swapFrom and swapTo then
				respawnPlayer(swapTo)

				P_SetOrigin(swapTo.mo,
					swapFrom.mo.x,
					swapFrom.mo.y,
					swapFrom.mo.z)
				swapFrom.mo.momx = swapTo.mo.momx
				swapFrom.mo.momy = swapTo.mo.momy
				swapFrom.mo.momz = swapTo.mo.momz
		
				swapTo.drawangle = swapFrom.drawangle
				swapTo.mo.angle = swapFrom.mo.angle
		
				if swapFrom.heist:hasSign() then
					FangsHeist.giveSignTo(swapTo)
				end
	
				for i = #swapFrom.heist.treasures, 1, -1 do
					local tres = swapFrom.heist.treasures[i]
		
					table.remove(swapFrom.heist.treasures, i)
					table.insert(swapTo.heist.treasures, tres)

					tres.mobj.target = swapTo.mo
					tres.mobj.index = #swapTo.heist.treasures
				end
	
				FangsHeist.Net.current_runner = swapTo
				FangsHeist.Net.exit_deb = 5
				swapFrom.heist.intangible = true
			end
	
			FangsHeist.Net.swap_runner = SWAP_TIME
		end
	end
end

function gamemode:trackplayer(p)
	if p.heist.intangible then
		return {}
	end

	local lp = displayplayer
	local team = lp.heist:getTeam()
	local args = {}

	if p == FangsHeist.Net.current_runner then
		table.insert(args, "RUNNER")
	end

	return args
end

function gamemode:sync(sync)
	self.super.sync(self, sync)

	FangsHeist.Net.officers = sync($)
	FangsHeist.Net.heisters = sync($)
	FangsHeist.Net.hskins = sync($)
	FangsHeist.Net.last_team_member = sync($)
	FangsHeist.Net.queues = sync($)
	FangsHeist.Net.headstart = sync($)
	FangsHeist.Net.swap_runner = sync($)
	FangsHeist.Net.current_runner = sync($)
	FangsHeist.Net.exit_deb = sync($)
	FangsHeist.Net.profit_quota = sync($)
end

function gamemode:shouldend() end -- shouldnt end manually

function gamemode:shouldinstakill(p, sp)
	return sp.heist.health <= 1
end

function gamemode:playerdamage(p)
	p.heist.health = max(1, $-1)
end

function gamemode:playerexit(p)
	if FangsHeist.Net.exit_deb then
		return true
	end
	if FangsHeist.Net.heisters.profit < FangsHeist.Net.profit_quota then
		return true
	end

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

function gamemode:manageTime()
	if not FangsHeist.Net.time_left then return end

	FangsHeist.Net.time_left = max(0, $-1)
	FangsHeist.setTimerTime(FangsHeist.Net.time_left, FangsHeist.Net.max_time_left)

	if FangsHeist.Net.time_left <= 30*TICRATE
	and not FangsHeist.Net.hurry_up then
		// dialogue.startFangPreset("hurryup")
		FangsHeist.Net.hurry_up = true
	end

	if FangsHeist.Net.time_left <= 10*TICRATE
	and FangsHeist.Net.time_left % TICRATE == 0 then
		if FangsHeist.Net.time_left == 0 then
			S_StartSound(nil, sfx_fhuhoh)
		else
			S_StartSound(nil, sfx_fhtick)
		end
	end

	if not FangsHeist.Net.time_left then
		for _, p in ipairs(FangsHeist.Net.heisters) do
			if p
			and p.valid
			and p.heist then
				p.heist.spectator = true
			end
		end

		FangsHeist.startIntermission()
		HeistHook.runHook("TimeUp")
	end
end

function gamemode:music()
	local song, loop, vol = self.super.music(self)

	if song ~= "FHTUP"
	and FangsHeist.Net.last_team_member then
		return "LARUST", true, vol
	end

	return song, loop, vol
end

local function blacklist(self, p)
	local team = p.heist:getTeam()

	return team == FangsHeist.Net.officers
end

gamemode.signblacklist = blacklist
gamemode.treasureblacklist = blacklist

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
addHook("ShouldDamage", function(_,_,t)
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
end)

return FangsHeist.addGamemode(gamemode)