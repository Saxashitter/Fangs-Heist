local DEADZONE = 25

local function SwitchVote(p, i)
	local current = p.heist.selected

	i = current+$
	i = max(1, $)
	i = min($, #FangsHeist.Net.map_choices)

	if i == current then
		return
	end

	p.heist.selected = i
	print("switched")
end

return function(p)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.game_over then return end
	if not FangsHeist.isMapVote() then return end

	-- Handle inputs for Map Vote here.
	local voted = p.heist.voted

	local buttons = p.heist.buttons
	local press = buttons & ~p.heist.lastbuttons

	local sidemove = p.heist.sidemove
	local lastside = p.heist.lastside
	local switch = 0

	if abs(sidemove) >= DEADZONE
	and abs(lastside) < DEADZONE then
		SwitchVote(p, sidemove > 0 and 1 or -1)
	end
end