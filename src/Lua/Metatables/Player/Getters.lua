local mt = (...)

function mt:getTeam()
	for i,team in ipairs(FangsHeist.Net.teams) do
		for _,player in ipairs(team) do
			if player == self.player then
				return team
			end
		end
	end

	return false
end

function mt:getMultiplier()
	if not self:isAlive() then
		return 0
	end

	local team = self:getTeam()
	local multiplier = 1

	for _, p in ipairs(team) do
		if not (p and p.valid and p.heist) then
			continue
		end

		for k,v in ipairs(p.heist.pickup_list) do
			multiplier = max($, v.multiplier)
		end
	end

	return multiplier
end

function mt:getNearPlayers(p, range, zrange)
	local list = {}
	local search = function(mo, found)
		if not (found and found.valid and found.type == MT_PLAYER and found.player and found.player.valid) then return end
		if found.health <= 0 then return end

		local midz1 = mo.z + mo.height/2
		local midz2 = found.z + found.height/2
		local distance = R_PointToDist2(mo.x, mo.y, found.x, found.y)
		local z_distance = R_PointToDist2(0, midz1, distance, midz2)
	
		if distance > range then return end
		if z_distance > zrange or range then return end

		table.insert(list, found)
	end

	searchBlockmap("objects", search, p.mo, p.mo.x-range*2, p.mo.x+range*2, p.mo.y-range*2, p.mo.z+range*2)
	return list
end