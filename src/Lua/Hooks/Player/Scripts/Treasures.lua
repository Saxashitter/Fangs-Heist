return function(p)
	if p.heist.spectator then
		p.heist.treasure_time = 0
		return
	end

	p.heist.treasure_time = max(0, $-1)

	if p.heist.team.leader ~= p then return end
	if leveltime % TICRATE*5 == 0
	and not FangsHeist.Net.game_over then
		local count = 0

		for p,_ in pairs(p.heist.team.players) do
			if not (p and p.valid and p.heist and FangsHeist.isPlayerAlive(p)) then
				continue
			end
	
			count = $+#p.heist.treasures
		end

		local maxprofit = 120*count

		if p.heist.team.generated_profit < maxprofit then
			p.heist.team.generated_profit = min(maxprofit, $+15)
		else
			p.heist.team.generated_profit = max(maxprofit, $-15)
		end
	end
end