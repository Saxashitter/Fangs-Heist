return function(p)
	if FangsHeist.isPlayerAlive(p)
	and FangsHeist.playerHasSign(p) then
		if not p.heist.sign_got then
			FangsHeist.gainProfit(p, 1200, true)
			p.heist.sign_got = true
		end
	else
		if p.heist.sign_got then
			FangsHeist.gainProfit(p, -1200, false)
			p.heist.sign_got = false
		end
	end

	if p.heist.spectator then
		p.heist.treasure_time = 0
	end

	p.heist.treasure_time = max(0, $-1)

	if not FangsHeist.isTeamLeader(p) then return end

	local team = FangsHeist.isInTeam(p)
	local treasures = #p.heist.treasures
	local canIncrease = FangsHeist.isPlayerAlive(p) and not p.heist.exiting

	if team then
		for _,sp in ipairs(team) do
			if not (sp and sp.valid and FangsHeist.isPlayerAlive(sp)) then
				continue
			end

			treasures = $+#sp.heist.treasures
			if not sp.heist.exiting then
				canIncrease = true
			end
		end
	end

	local profit = 120

	if p.heist.treasures_collected ~= treasures
	and canIncrease then
		local gainAmount = treasures-p.heist.treasures_collected

		FangsHeist.gainProfit(p, profit*gainAmount, true)
		p.heist.treasures_collected = treasures
	end

	if team then
		for _,sp in ipairs(team) do
			if not (sp and sp.valid and FangsHeist.isPlayerAlive(sp)) then
				continue
			end

			sp.heist.treasures_collected = treasures
		end
	end
end