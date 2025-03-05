local function sort(a, b)
	return a.profit > b.profit
end

return function()
	if FangsHeist.Net.pregame then return end

	local teams = {}
	local profit = 0

	for _,team in ipairs(FangsHeist.Net.teams) do
		table.insert(teams, team)
		profit = $+team.profit
	end

	if profit ~= FangsHeist.Net.last_profit then
		table.sort(teams, sort)
		FangsHeist.Net.placements = teams
	end
end