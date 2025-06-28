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

	if p == consoleplayer then
		S_StartSound(nil, sfx_wepchg)
	end
end

local function ConfirmVote(p)
	local selected = p.heist.selected

	local maps = FangsHeist.Net.map_choices
	local map = maps[selected]

	map.votes = $+1
	p.heist.voted = true

	if p == consoleplayer then
		S_StartSound(nil, sfx_s221)
	end
end

local function DeconfirmVote(p)
	local selected = p.heist.selected

	local maps = FangsHeist.Net.map_choices
	local map = maps[selected]

	map.votes = $-1
	p.heist.voted = false

	if p == consoleplayer then
		S_StartSound(nil, sfx_alart)
	end
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

	if voted
	and press & BT_SPIN then
		DeconfirmVote(p)
	end

	if voted then
		return
	end

	if abs(sidemove) >= DEADZONE
	and abs(lastside) < DEADZONE then
		SwitchVote(p, sidemove > 0 and 1 or -1)
	end

	if press & BT_JUMP then
		ConfirmVote(p)
	end
end