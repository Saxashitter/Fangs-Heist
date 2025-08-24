local module = {}

local PROFITFORM = string.char(1) .. " %d"
local RINGSFORM = string.char(2) .. " %d"
local RANKFORM = "[c:red]R [c:white]%d"

local function DrawText(v, x, y, string, flags, align, color, rich)
	FangsHeist.DrawString(v,
		x*FU,
		y*FU,
		FU,
		string,
		"FHTXT",
		align,
		flags,
		color,
		rich)
end

function module.draw(v, p)
	if not FangsHeist.getGamemode().renderprofit then return end
	if FangsHeist.Net.pregame then return end
	if FangsHeist.Net.game_over then return end
	if not p.heist:isAlive() then return end
	
	local team = p.heist:getTeam()

	local rings = RINGSFORM:format(p.rings)
	local profit = PROFITFORM:format(team.profit)
	local rank = RANKFORM:format(team.place or 0)

	local multiplier = p.heist:getMultiplier()

	if multiplier > 1 then
		profit = $ .. " [c:yellow]"..multiplier.."x"
	end

	DrawText(v, 320 - 8, 8, rings, V_SNAPTORIGHT|V_SNAPTOTOP, "right")
	DrawText(v, 320 - 8, 19, profit, V_SNAPTORIGHT|V_SNAPTOTOP, "right", nil, true)
	DrawText(v, 320 - 8, 30, rank, V_SNAPTORIGHT|V_SNAPTOTOP, "right", nil, true)
end

return module