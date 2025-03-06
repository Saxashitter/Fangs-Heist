return function(p)
	if p.heist.spectator then
		p.heist.treasure_time = 0
	end

	p.heist.treasure_time = max(0, $-1)

	if p ~= displayplayer then return end
	if not FangsHeist.isPlayerAlive(p) then return end

	local team = FangsHeist.getTeam(p)
	if not team then return end

	for _,sp in ipairs(team) do
		if not (sp ~= p and sp.valid and FangsHeist.isPlayerAlive(sp)) then
			continue
		end

		P_SpawnLockOn(p, sp.mo, S_LOCKON1)
	end
end