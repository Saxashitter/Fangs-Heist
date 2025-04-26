local module = {}

local text = FangsHeist.require "Modules/Libraries/text"

local _profit

function module.init()
	_profit = 0
end

function FangsHeist.drawProfit(v, x, y, scale, profit, flags, width)
	local patch = v.cachePatch("FH_PROFIT")

	v.drawScaled(x, y, scale, patch, flags)
	
	if width == nil then
		width = 80*scale
	end

	width = max(patch.width*scale, $)

	FangsHeist.DrawNumber(v, x+width, y, scale, profit, "STTNUM", flags)
end

function FangsHeist.getProfitWidth(v, profit, scale, width)
	local patch = v.cachePatch("FH_PROFIT")
	if width == nil then
		width = 80*scale
	end

	width = max(patch.width*scale, $)
	width = $ + FangsHeist.GetNumberWidth(v, profit, scale, "STTNUM")

	return width
end

function module.draw(v, p)
	if FangsHeist.Net.pregame then return end
	local profit = 0
	local team = FangsHeist.getTeam(p)

	if team then
		profit = team.profit
	end

	FangsHeist.drawProfit(v, 12*FU, 12*FU, FU, profit, V_SNAPTOLEFT|V_SNAPTOTOP)
end

return module