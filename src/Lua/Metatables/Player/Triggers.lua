local mt = (...)

function mt:gainProfitMultiplied(gain, dontDiv, specialSound)
	local team = self:getTeam()
	local gamemode = FangsHeist.getGamemode()
	local multiplier = self:getMultiplier()

	self:gainProfit(gain*multiplier, dontDiv, specialSound)
end

function mt:gainProfit(gain, dontDiv, specialSound)
	local div = 0
	local team = self:getTeam()
	local gamemode = FangsHeist.getGamemode()

	if not team then
		return
	end

	div = not dontDiv and #team or 1
	if gamemode.dontdivprofit then
		div = 1
	end

	team.profit = max(0, $+(gain/div))
end

function mt:addIntoTeam(sp)
	local team = self:getTeam()

	if team
	and self:isPartOfTeam(sp) then
		return
	end

	local otherteam = sp.heist:getTeam()
	if otherteam then
		for i = #otherteam, 1, -1 do
			local plyr = otherteam[i]

			if plyr == sp then
				table.remove(otherteam, i)
				break
			end
		end
	end

	table.insert(team, sp)
end