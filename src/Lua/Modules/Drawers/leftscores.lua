local module = {}

local savedplyrs = {}

local SCORE_Y = 58*FU
local SCORE_X = 16*FU

local function make_sort_object(p)
	return {
		y = 0,
		alpha = 0,
		plyr = p
	}
end

local function get_profit(p)
	if not (p.heist.exiting) then
		return FangsHeist.returnProfit(p)
	end

	return p.heist.saved_profit
end

local function score_sort(a, b)
	local score1 = get_profit(a.plyr)
	local score2 = get_profit(b.plyr)

	return score1 > score2
end

function module.init()
	savedplyrs = {}
end

function module.draw(v)
	for p in players.iterate do
		if FangsHeist.isPlayerAlive(p)
			and p.heist
			and not savedplyrs[p] then
				savedplyrs[p] = make_sort_object(p)
		end
	end

	local plyrs = {}

	for p,obj in pairs(savedplyrs) do
		if not (FangsHeist.isPlayerAlive(p)
			and p.heist) then
				savedplyrs[p] = nil
				continue
		end

		table.insert(plyrs, obj)
	end

	table.sort(plyrs, score_sort)

	for i,obj in pairs(plyrs) do
		local target_y = (10*FU)*(i-1)

		obj.y = ease.linear(FU/5, $, target_y)

		if i > 3 then
			obj.alpha = min($+1, 10)
		else
			obj.alpha = max(0, $-1)
		end

		local alpha = V_10TRANS*obj.alpha
		if obj.alpha == 10 then continue end

		local life = v.getSprite2Patch(obj.plyr.skin,
			SPR2_LIFE, false, A, 0)

		local scale = FU/2
		local profit = get_profit(obj.plyr)

		v.drawScaled(SCORE_X+life.leftoffset*scale,
			SCORE_Y+obj.y+life.topoffset*scale-(2*scale),
			scale,
			life,
			V_SNAPTOTOP|V_SNAPTOLEFT|alpha,
			v.getColormap(nil, obj.plyr.skincolor))

		v.drawString(SCORE_X+10*FU,
			SCORE_Y+obj.y,
			obj.plyr.name,
			V_SNAPTOLEFT|V_SNAPTOTOP|alpha|(obj.plyr == displayplayer and V_YELLOWMAP or 0),
			"thin-fixed")

		local str_width = v.stringWidth(obj.plyr.name, 0, "thin")

		v.drawString(SCORE_X+12*FU+str_width*FU,
			SCORE_Y+obj.y,
			profit,
			V_SNAPTOLEFT|V_SNAPTOTOP|V_GREENMAP|alpha,
			"thin-fixed")

		if not FangsHeist.playerHasSign(obj.plyr) then continue end
		local str_width2 = v.stringWidth(tostring(profit), 0, "thin")

		v.drawString(SCORE_X+14*FU+str_width*FU+str_width2*FU,
			SCORE_Y+obj.y,
			"SIGN",
			V_SNAPTOTOP|V_SNAPTOLEFT|alpha,
			"thin-fixed")
	end
end

return module