return function()
	-- manage teams
	if not #FangsHeist.Net.teams then return end

	for i = #FangsHeist.Net.teams, 1, -1 do
		local team = FangsHeist.Net.teams[i]
		local signGot = team.had_sign
		local treasures = 0

		if #team then
			for k = #team, 1, -1 do
				local p = team[k]
	
				if not (p and p.valid and p.heist and p.heist:isAbleToTeam()) then
					table.remove(team, k)
					continue
				end

				if p.heist:isAlive() then
					signGot = $ or p.heist:hasSign()
					treasures = $+#p.heist.treasures
				end
			end
		end
	
		if #team < 1 then
			table.remove(FangsHeist.Net.teams, i)
			continue
		end

		if signGot
		and not team.added_sign then
			team.profit = max(0, $+1200)
		end

		if not signGot
		and team.added_sign then
			team.profit = max(0, $-1200)
		end

		team.added_sign = signGot

		if treasures ~= team.treasures then
			local gain = treasures - team.treasures
	
			team.profit = max(0, $+(120*gain))
		end

		team.treasures = treasures
	end
end