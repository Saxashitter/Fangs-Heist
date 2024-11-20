function FangsHeist.isMode()
	return gametype == GT_FANGSHEIST
end

function FangsHeist.isPlayerAlive(p)
	return p and p.mo and p.mo.health and p.heist and not p.heist.spectator
end