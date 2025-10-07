return function(p)
	if p.heist.spectator then
		p.heist.treasure_time = 0
	end

	p.heist.treasure_time = max(0, $-1)

	if p ~= displayplayer then return end
	if not (p.heist and p.heist:isAlive()) then return end

	local team = p.heist:getTeam()
	local gamemode = FangsHeist.getGamemode()
	if not team then return end

	for sp in players.iterate do
		if not (sp
		and sp.valid
		and sp.heist
		and sp.mo
		and sp.mo.valid
		and sp ~= p) then
			continue
		end
	end
end