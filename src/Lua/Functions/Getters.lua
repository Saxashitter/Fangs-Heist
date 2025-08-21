// Get players nearby, mainly used for pickup-ables.
function FangsHeist.getNearbyPlayers(mobj, distscale, blacklist)
	if not (distscale) then distscale = FU*3/2 end

	local nearby = {}

	for p in players.iterate do
		if not (p.heist and p.heist:isAlive()) then
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

-- Returns skin name that thr player's mobj should use
function FangsHeist.getRealSkin(p)
	if p.heist.alt_skin < 2 then
		return p.heist.locked_skin, p.heist.alt_skin == 1
	end

	local val = p.heist.alt_skin % 2
	local index = p.heist.alt_skin / 2
	local name = p.heist.locked_skin

	return name..index, val == 1
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

		if not (p.heist
		and p.heist:isAlive()) then
			count.dead = $+1
			continue
		end

		if p.heist.exiting then
			count.exiting = $+1
			continue
		end

		if p.heist:isTeamLeader() then
			count.team = $+1
		end

		count.alive = $+1
	end

	return count
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