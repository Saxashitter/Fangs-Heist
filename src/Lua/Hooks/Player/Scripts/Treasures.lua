return function(p)
	if p.heist.spectator then
		p.heist.treasure_time = 0
	end

	p.heist.treasure_time = max(0, $-1)

	if p ~= displayplayer then return end
	if not (p.heist and p.heist:isAlive()) then return end

	local team = p.heist:getTeam()
	if not team then return end

	for _,sp in ipairs(team) do
		if not (sp ~= p and sp.valid and sp.heist and sp.heist:isAlive()) then
			continue
		end

		P_SpawnLockOn(p, sp.mo, S_LOCKON1)
	end
end