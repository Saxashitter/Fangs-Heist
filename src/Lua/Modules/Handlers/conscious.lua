states[freeslot "S_FH_UNCONSCIOUS"] = {
	sprite = SPR_PLAY,
	frame = freeslot "SPR2_OOF_",
	tics = -1
}

return function(p)
	if p.heist.conscious_meter then return end
	if not p.mo.health then
		FangsHeist.makePlayerConscious(p)
		return
	end

	p.heist.conscious_meter_heal = max(0, $-1)
	p.mo.state = S_FH_UNCONSCIOUS

	if p.heist.buttons & BT_JUMP
	and not (p.heist.lastbuttons & BT_JUMP) then
		p.heist.conscious_meter_heal = max(0, $-p.heist.conscious_meter_reduce)
	end

	if not (p.heist.conscious_meter_heal) then
		FangsHeist.makePlayerConscious(p)
	end
end