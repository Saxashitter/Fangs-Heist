local orig = FangsHeist.require "Modules/Variables/net"

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
		and FangsHeist.Net.sign.holder == p.mo)
end

function FangsHeist.getTeam(p)
	for _,team in ipairs(FangsHeist.Net.teams) do
		for _,player in ipairs(team) do
			if player == p then
				return team
			end
		end
	end

	--[[if not team
	and FangsHeist.isAbleToTeam(p) then
		team = FangsHeist.initTeam(p)
	end]]

	return false
end

function FangsHeist.getTeamLength(p)
	if not (p and p.heist) then return 0 end

	local team = FangsHeist.getTeam(p)

	return #team-1
end

function FangsHeist.playerCount()
	local count = {
		total = 0,
		alive = 0,
		team = 0,
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

		if FangsHeist.isTeamLeader(p) then
			count.team = $+1
		end

		count.alive = $+1
	end

	return count
end

// Returns -1 if the player isn't placed anywhere.
function FangsHeist.getPlayerPlacement(p)
	for i,team in ipairs(FangsHeist.Net.placements) do
		for _,sp in ipairs(team) do
			if sp == p then
				return i
			end
		end
	end

	return -1
end

// Used for loading colors from files.
function FangsHeist.getColorByName(name)
	for i = 1,#skincolors-1 do
		if skincolors[i] and skincolors[i].name == name then
			return i
		end
	end

	return SKINCOLOR_BLUE
end