local function sort(a, b)
	return a.heist.profit > b.heist.profit
end

return function()
	if FangsHeist.Net.pregame then return end

	local plyrs = {}
	local profit = 0

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then continue end
		if not FangsHeist.isTeamLeader(p) then continue end

		table.insert(plyrs, p)
		profit = $+p.heist.profit
	end

	if profit ~= FangsHeist.Net.last_profit then
		table.sort(plyrs, sort)
		FangsHeist.Net.placements = plyrs
	end
end