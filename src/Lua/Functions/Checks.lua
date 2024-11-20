function FangsHeist.isMode()
	return gametype == GT_FANGSHEIST
end

function FangsHeist.isPlayerAlive(p)
	return p and p.mo and p.mo.health and p.heist and not p.heist.spectator
end

function FangsHeist.isPlayerAtGate(p)
	local exit = FangsHeist.Net.exit

	local dist = R_PointToDist2(p.mo.x, p.mo.y, exit.x, exit.y)
	local heightdist = abs(p.mo.z-exit.z)

	if dist < 128*FU
	and heightdist < 200*FU then
		return true
	end
	
	return false
end