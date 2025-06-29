local mt = (...)

function mt:getTeam()
	for _,team in ipairs(FangsHeist.Net.teams) do
		for _,player in ipairs(team) do
			if player == self.player then
				return team
			end
		end
	end

	return false
end