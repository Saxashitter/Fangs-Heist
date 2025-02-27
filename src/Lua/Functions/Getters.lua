local orig = FangsHeist.require "Modules/Variables/net"

function FangsHeist.getTypeData()
	if FangsHeist.GameTypes[FangsHeist.Net.gametype] then
		return FangsHeist.GameTypes[FangsHeist.Net.gametype]
	end

	return FangsHeist.GameTypes[0]
end

// Get players nearby, mainly used for pickup-ables.
function FangsHeist.getNearbyPlayers(mobj, distscale, blacklist)
	if not (distscale) then distscale = FU*3/2 end

	local nearby = {}

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then
			continue
		end

		local dist = R_PointToDist2(p.mo.x, p.mo.y, mobj.x, mobj.y)
		local heightdist = abs(p.mo.z-mobj.z)

		if dist > FixedMul(p.mo.radius+mobj.radius, distscale) then
			continue
		end

		if heightdist > FixedMul(max(mobj.height, p.mo.height), distscale) then
			continue
		end

		if blacklist
		and blacklist(p) then
			continue
		end

		table.insert(nearby, p)
	end

	return nearby
end

function FangsHeist.playerHasSign(p)
	return (FangsHeist.Net.sign
		and FangsHeist.Net.sign.valid
		and p
		and p.mo
		and p.mo.valid
		and FangsHeist.Net.sign.holder == p.mo)
end

function FangsHeist.partOfTeam(p, sp)
	return p and p.heist and p.heist.team.players[sp]
end

function FangsHeist.getTeamLength(p)
	if not (p and p.heist) then return 0 end

	local length = 0

	for sp,_ in pairs(p.heist.team.players) do
		if sp ~= p then
			length = $+1
		end
	end

	return length
end

function FangsHeist.returnProfit(p, personal)
	if not (p and p.heist) then return 0 end
	
	if not FangsHeist.isPlayerAlive(p) then
		return 0
	end
	
	local profit = 0
	
	if FangsHeist.playerHasSign(p)
	or p.heist.had_sign then
		profit = $+1500
	end
	
	local div = 1
	local length = FangsHeist.getTeamLength(p)
	if length then
		for i = 1,length do
			div = $+1
		end
	end

	profit = $+(28*p.heist.hitplayers/div)
	profit = $+(50*p.heist.deadplayers/div)
	profit = $+(12*p.heist.monitors/div)
	profit = $+(35*p.heist.enemies/div)
	profit = $+p.heist.team.generated_profit -- TODO: work on a way to cap treasures while teaming
	profit = $+(8*p.rings/div)

	if not personal then
		for sp,k in pairs(p.heist.team.players) do
			if p == sp then continue end
			if not (sp and sp.valid) then continue end

			profit = $+FangsHeist.returnProfit(sp, true)
		end
	end

	return profit
end

function FangsHeist.playerCount()
	local count = {
		total = 0,
		alive = 0,
		exiting = 0,
		dead = 0
	}

	for p in players.iterate do
		count.total = $+1

		if not (FangsHeist.isPlayerAlive(p)
		and p.heist
		and not p.heist.spectator) then
			count.dead = $+1
			continue
		end

		if p.heist.exiting then
			count.exiting = $+1
			continue
		end

		count.alive = $+1
	end

	return count
end

local function score_sort(a, b)
	local score1 = FangsHeist.returnProfit(a)
	local score2 = FangsHeist.returnProfit(b)

	return score1 > score2
end

// Returns -1 if the player isn't placed anywhere.
function FangsHeist.getPlayerPlacement(p)
	local placement = 1
	placement = FangsHeist.Net.placements[#p]

	if not (FangsHeist.isPlayerAlive(p) and placement) then
		return -1
	end

	return placement.place
end

// Used for loading colors from files.
function FangsHeist.getColorByName(name)
	for i = 1,#skincolors do
		if skincolors[i] and skincolors[i].name == name then
			return i-1
		end
	end

	return SKINCOLOR_BLUE
end