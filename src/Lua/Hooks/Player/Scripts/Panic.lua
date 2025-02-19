return function(p)
	if not (p.mo and p.mo.health) then return end

	local char = FangsHeist.Characters[p.mo.skin]
	if char.panicState ~= false
	and FangsHeist.Net.escape then
		if p.mo.state == S_PLAY_STND then
			p.mo.state = char.panicState
		end

		if p.mo.state == char.panicState then
			if FixedHypot(p.rmomx, p.rmomy) then
				p.mo.state = S_PLAY_WALK
			end
		end
	end
end