return function(p)
	if p.heist.spectator then
		p.heist.treasure_time = 0
		return
	end

	p.heist.treasure_time = max(0, $-1)

	if leveltime % TICRATE*5 == 0
	and not p.heist.exiting then
		local count = #p.heist.treasures

		p.heist.generated_profit = min(500, $+12*count)
	end
end