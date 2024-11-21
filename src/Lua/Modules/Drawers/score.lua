local module = {}

local text = FangsHeist.require "Modules/Libraries/text"

local _profit
local y

function module.init()
	_profit = 0
	y = 0
end

function module.draw(v, p)
	local profit = FangsHeist.returnProfit(p)

	y = ease.linear(FU/2, $, 0)

	if profit ~= _profit then
		y = -4*FU
		_profit = profit
	end

	local profit_patch = v.cachePatch("FH_PROFIT")

	local scale = (FU/3)*2
	v.drawScaled(10*FU, 10*FU, scale, profit_patch, V_SNAPTOLEFT|V_SNAPTOTOP)

	text.draw(v,
		10*FU + profit_patch.width*scale/2,
		10*FU + y - 9*FU,
		scale,
		"$"..tostring(profit),
		"PRTFT",
		"center",
		V_SNAPTOLEFT|V_SNAPTOTOP
	)
end

return module