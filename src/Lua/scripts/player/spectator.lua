return function(p)
	if p.heist.spectator or p.heist.spectator_not_dead then
		if p.mo then
			if p.mo.health then
				p.spectator = true
			end

			return
		end

		p.spectator = true
	end
end