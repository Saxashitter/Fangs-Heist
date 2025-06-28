-- haha empty
function FH:GetPressDirection(p)
	local sidemove = p.heist.sidemove
	local forwardmove = p.heist.forwardmove

	local last_sidemove = p.heist.lastside
	local last_forwardmove = p.heist.lastforw

	local x = 0
	local y = 0

	if sidemove >= DEADZONE
	and last_sidemove < DEADZONE then
		x = 1
	end

	if sidemove <= -DEADZONE
	and last_sidemove > -DEADZONE then
		x = -1
	end

	if forwardmove >= DEADZONE
	and last_forwardmove < DEADZONE then
		y = -1
	end

	if forwardmove <= -DEADZONE
	and last_forwardmove > -DEADZONE then
		y = 1
	end

	return x, y
end

function FH:GetState(p)
	return STATES[p.heist.pregame_state]
end