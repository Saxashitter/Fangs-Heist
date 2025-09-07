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
					treasures = $+#p.heist.pickup_list

					if signGot then treasures = max(0, $-1) end
				end
			end
		end
	
		if #team < 1 then
			table.remove(FangsHeist.Net.teams, i)
			continue
		end

		team.added_sign = signGot
		team.treasures = treasures
	end
end