local mt = (...)

function mt:hasSign()
	for k,v in ipairs(self.pickup_list) do
		if v.id == "Sign" then
			return true
		end
	end

	return false
end

function mt:hasTreasure()
	for k,v in ipairs(self.pickup_list) do
		if v.id == "Treasure" then
			return true
		end
	end

	return false
end

function mt:isAtGate()
	local exit = FangsHeist.Net.exit

	local dist = R_PointToDist2(self.player.mo.x, self.player.mo.y, exit.x, exit.y)

	if dist <= self.player.mo.radius+32*exit.scale
	and self.player.mo.z <= exit.z+50*exit.scale
	and exit.z <= self.player.mo.z+self.player.mo.height then
		return true
	end
	
	return false
end

function mt:isAlive(p)
	local p = self.player
	return p and p.mo and p.mo.health and not self.spectator
end

function mt:isNerfed()
	--[[local result = FangsHeist.runHook("IsPlayerNerfed", p)
	if result ~= nil then
		return result
	end

	local gamemode = FangsHeist.getGamemode()

	if self:hasSign()
	and (gamemode.signnerf or FangsHeist.Save.retakes) then
		return true
	end

	if #self.treasures
	and FangsHeist.Save.retakes then
		return true
	end]]

	return false
end

function mt:isPartOfTeam(sp)
	local team = self:getTeam()

	if self.player == sp then
		return true
	end

	if not team then
		return false
	end

	for _,player in ipairs(team) do
		if sp == player then
			return true
		end
	end

	return false
end

function mt:isTeamLeader()
	local team = self:getTeam()

	if not team then
		return true
	end

	return team[1] == self.player
end

function mt:isAbleToTeam()
	return not self.player.heist.spectator
end

function mt:isEligibleForSign()
	local team = self:getTeam()
	local gamemode = FangsHeist.getGamemode()

	return self:isAlive()
	and not self.exiting
	and not (team and team.had_sign)
	and not gamemode:signblacklist(self.player)
end

function mt:isGuarding()
	return false
end