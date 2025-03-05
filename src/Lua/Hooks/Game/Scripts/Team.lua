return function()
	-- manage teams
	if not #FangsHeist.Net.teams then return end

	for i = #FangsHeist.Net.teams, 1, -1 do
		local team = FangsHeist.Net.teams[i]
		local signGot = false
		local hadSign = false

		if #team then
			for k = #team, 1, -1 do
				local p = team[k]
	
				if not (p and p.valid and p.heist and not p.heist.spectator) then
					table.remove(team, k)
					continue
				end

				if FangsHeist.isPlayerAlive(p) then
					signGot = $ or FangsHeist.playerHasSign(p)
					hadSign = $ or p.heist.had_sign
				end
			end
		end
	
		if #team <= 1 then
			local p = team[1]

			if FangsHeist.isPlayerAlive(p) then
				p.heist.sign_got = signGot
				p.heist.had_sign = hadSign
			end

			table.remove(FangsHeist.Net.teams, i)
			continue
		end

		if (signGot or hadSign)
		and not team.sign then
			FangsHeist.gainProfit(team[1], 1200, true)
		end

		if not (signGot or hadSign)
		and team.sign then
			FangsHeist.gainProfit(team[1], -1200, true)
		end

		team.sign = (signGot or hadSign)
	end
end