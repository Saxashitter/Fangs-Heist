return function()
	-- manage teams
	if not #FangsHeist.Net.teams then return end

	for i = #FangsHeist.Net.teams, 1, -1 do
		local team = FangsHeist.Net.teams[i]

		if #team then
			for k = #team, 1, -1 do
				local plyr = team[k]
	
				if not (plyr and plyr.valid and plyr.heist and not plyr.heist.spectator) then
					table.remove(team, k)
				end
			end
		end
	
		if #team <= 1 then
			table.remove(FangsHeist.Net.teams, i)
			continue
		end
	end
end