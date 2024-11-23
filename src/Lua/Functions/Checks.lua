local orig = FangsHeist.require "Modules/Variables/net"

function FangsHeist.isMode()
	return gametype == GT_FANGSHEIST or (gamestate == GS_LEVEL and not multiplayer)
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

local HURRY_LENGTH = 2693

// Check if the time is in the "Hurry Up" segment.
function FangsHeist.isHurryUp()
	if not FangsHeist.Net.escape then
		return false
	end

	if (orig.time_left-FangsHeist.Net.time_left)*MUSICRATE/TICRATE > HURRY_LENGTH then
		return false
	end

	return true
end