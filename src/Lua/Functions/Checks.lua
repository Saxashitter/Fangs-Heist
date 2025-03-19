local orig = FangsHeist.require "Modules/Variables/net"

function FangsHeist.isMode()
	if not multiplayer then
		return not titlemapinaction
	end

	return gametype == GT_FANGSHEIST
end

function FangsHeist.isPlayerAlive(p)
	return p and p.mo and p.mo.health and p.heist and not p.heist.spectator
end

function FangsHeist.isServer()
	return isserver or isdedicatedserver
end

function FangsHeist.isPlayerAtGate(p)
	local exit = FangsHeist.Net.exit

	local dist = R_PointToDist2(p.mo.x, p.mo.y, exit.x, exit.y)

	if dist <= p.mo.radius+32*FU
	and p.mo.z <= exit.z+48*FU
	and exit.z <= p.mo.z+p.mo.height then
		return true
	end
	
	return false
end

function FangsHeist.canUseAbility(p)
	if not FangsHeist.isMode() then
		return true
	end

	if not (p and p.heist) then
		return true
	end

	if not FangsHeist.playerHasSign(p) then
		return true
	end

	return false
end

function FangsHeist.isPlayerNerfed(p)
	if not FangsHeist.isMode()
	or not p.heist then
		return false
	end

	local result = HeistHook.runHook("IsPlayerNerfed", p)
	if result ~= nil then
		return result
	end

	if FangsHeist.playerHasSign(p) then
		return true
	end

	if #p.heist.treasures
	and FangsHeist.Save.retakes then
		return true
	end

	return false
end

function FangsHeist.isPartOfTeam(p, sp)
	local team = FangsHeist.getTeam(p)

	if p == sp then
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

function FangsHeist.isTeamLeader(p)
	local team = FangsHeist.getTeam(p)

	if not team then
		return true
	end

	return team[1] == p
end

function FangsHeist.isAbleToTeam(p)
	return p and p.valid and p.heist and not p.heist.spectator
end