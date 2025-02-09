states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

return function(p)
	if p.mo
	and FangsHeist.Net.escape then
		if p.mo.state == S_PLAY_STND then
			p.mo.state = S_FH_PANIC
		end
		if p.mo.state == S_FH_PANIC then
			if FixedHypot(p.rmomx, p.rmomy) then
				p.mo.state = S_PLAY_WALK
			end
		end
	end
end