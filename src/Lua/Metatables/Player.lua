local mt = {}

function mt:hasSign()
	for k,v in ipairs(self.pickup_list) do
		if v.id == "Sign" then
			return true
		end
	end

	return false
end

function mt:isAtGate()
	local exit = FangsHeist.Net.exit

	local dist = R_PointToDist2(self.player.mo.x, self.player.mo.y, exit.x, exit.y)

	if dist <= self.player.mo.radius+32*FU
	and self.player.mo.z <= exit.z+48*FU
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
	local result = HeistHook.runHook("IsPlayerNerfed", p)
	if result ~= nil then
		return result
	end
	--[[local gamemode = FangsHeist.getGamemode()

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

function mt:getTeam()
	for _,team in ipairs(FangsHeist.Net.teams) do
		for _,player in ipairs(team) do
			if player == self.player then
				return team
			end
		end
	end

	return false
end

function mt:gainProfitMultiplied(gain, dontDiv, specialSound)
	local team = self:getTeam()
	local gamemode = FangsHeist.getGamemode()
	local multiplier = 1

	for _, p in ipairs(team) do
		if not (p and p.valid and p.heist) then
			continue
		end

		for k,v in ipairs(p.heist.pickup_list) do
			multiplier = max($, v.multiplier)
		end
	end

	self:gainProfit(gain*multiplier, dontDiv, specialSound)
end

function mt:gainProfit(gain, dontDiv, specialSound)
	local div = 0
	local team = self:getTeam()
	local gamemode = FangsHeist.getGamemode()

	if not team then
		return
	end

	div = not dontDiv and #team or 1
	if gamemode.dontdivprofit then
		div = 1
	end

	team.profit = max(0, $+(gain/div))
end

function mt:damagePlayers(friendlyfire, damage)
	local gamemode = FangsHeist.getGamemode()

	if friendlyfire == nil then
		friendlyfire = (gamemode.friendlyfire)
	end
	if damage == nil then
		damage = FH_BLOCKDEPLETION
	end

	local p = self.player
	local gamemode = FangsHeist.getGamemode()

	for sp in players.iterate do
		if not (sp and sp.mo and sp.mo.health and sp.heist) then
			continue
		end
		if sp == p then continue end

		local distXY = FixedHypot(p.mo.x-sp.mo.x, p.mo.y-sp.mo.y)
	
		local char1 = FangsHeist.Characters[p.mo.skin]
		local char2 = FangsHeist.Characters[sp.mo.skin]
	
		local radius1 = fixmul(p.mo.radius, char1.attackRange)
		local radius2 = fixmul(sp.mo.radius, char2.damageRange)
	
		if distXY > radius1+radius2 then continue end
	
		local height1 = fixmul(p.mo.height, char1.attackZRange)
		local height2 = fixmul(sp.mo.height, char2.damageZRange)
	
		local z = abs((p.mo.z+p.mo.height/2)-(sp.mo.z+sp.mo.height/2))
	
		if z > max(height1, height2) then continue end

		if self:isPartOfTeam(sp)
		and not friendlyfire then
			continue
		end

		if char2:isAttacking(sp) then
			FangsHeist.clashPlayers(p, sp)

			S_StartSound(p.mo, sfx_s3k7b)
			S_StartSound(sp.mo, sfx_s3k7b)

			return sp, false
		end

		local speed = FixedHypot(p.mo.momx, p.mo.momy)-FixedHypot(sp.mo.momx, sp.mo.momy)
		local dt
		if gamemode:shouldinstakill(p, sp) then
			dt = DMG_INSTAKILL
		end

		if P_DamageMobj(sp.mo, p.mo, p.mo, 1, dt) then
			char1:onHit(p, sp)

			sp.mo.momx = p.mo.momx
			sp.mo.momy = p.mo.momy

			HeistHook.runHook("PlayerDamage", p, sp)

			return sp, speed
		end

		if sp.heist:isGuarding()
		and sp.heist.parry_time then
			sp.mo.state = S_PLAY_WALK
			sp.heist.parry_cooldown = 0
			sp.heist.parry_time = 0
			sp.mo.translation = nil
			p.heist.attack_time = 0

			local sound = P_RandomRange(sfx_parry1, sfx_parry2)
			S_StartSound(sp.mo, sound)
			S_StartSound(p.mo, sound, p)

			return sp, speed, true
		end
	end
end

function mt:isGuarding()
	return false
end

function mt:addIntoTeam(sp)
	local team = self:getTeam()

	if team
	and self:isPartOfTeam(sp) then
		return
	end

	local otherteam = sp.heist:getTeam()
	if otherteam then
		for i = #otherteam, 1, -1 do
			local plyr = otherteam[i]

			if plyr == sp then
				table.remove(otherteam, i)
				break
			end
		end
	end

	table.insert(team, sp)
end

local _netTable = {
	__index = function(self, key)
		if mt[key] then
			return mt[key]
		end
	end
}

FangsHeist.PlayerMT = _netTable
registerMetatable(FangsHeist.PlayerMT)