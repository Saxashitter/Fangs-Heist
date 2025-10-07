local module = {}

--[[local X = 12 + 3
local Y = 12
local FLAGS = V_SNAPTOLEFT|V_SNAPTOTOP

local TEXT_X = 12 + 16 + 4
local TEXT_Y = 1

function module.init() end
function module.draw(v, p)
	if FangsHeist.Net.pregame
	or FangsHeist.Net.game_over then
		return
	end
	local profit = 0
	local team = p.heist:getTeam()

	if team then
		profit = team.profit
	end

	local patch = v.cachePatch("FH_PROFIT_SIGN")

	v.draw(X, Y, patch, FLAGS)

	local string = tostring(profit)
	local x = 0

	for i = 1,#string do
		local num = string:sub(i,i)
		local patch = v.cachePatch("FH_PROFIT_NUM"..num)

		v.draw(TEXT_X+x, Y+TEXT_Y, patch, FLAGS)
		x = $ + 1 + patch.width
	end
end]]

return module