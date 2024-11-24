local module = {}

local savedplyrs = {}

local SCORE_Y = 50*FU
local SCORE_X = 16*FU

function module.init()
end

function module.draw(v)
	for _,data in pairs(FangsHeist.Net.placements) do
		local placement = data.place
		local p = data.p

		if not (p and p.valid) then continue end

		local target_y = (10*FU)*(placement-1)

		if placement > 3 then continue end

		local life = v.getSprite2Patch(p.skin,
			SPR2_LIFE, false, A, 0)

		local scale = FU/2
		local profit = FangsHeist.returnProfit(p)

		v.drawScaled(SCORE_X+life.leftoffset*scale,
			SCORE_Y+target_y+life.topoffset*scale-(2*scale),
			scale,
			life,
			V_SNAPTOTOP|V_SNAPTOLEFT,
			v.getColormap(nil, p.skincolor))

		v.drawString(SCORE_X+10*FU,
			SCORE_Y+target_y,
			p.name,
			V_SNAPTOLEFT|V_SNAPTOTOP|(p == displayplayer and V_YELLOWMAP or 0),
			"thin-fixed")

		local str_width = v.stringWidth(p.name, 0, "thin")

		v.drawString(SCORE_X+12*FU+str_width*FU,
			SCORE_Y+target_y,
			profit,
			V_SNAPTOLEFT|V_SNAPTOTOP|V_GREENMAP,
			"thin-fixed")

		if not FangsHeist.playerHasSign(p) then continue end
		local str_width2 = v.stringWidth(tostring(profit), 0, "thin")

		v.drawString(SCORE_X+14*FU+str_width*FU+str_width2*FU,
			SCORE_Y+target_y,
			"SIGN",
			V_SNAPTOTOP|V_SNAPTOLEFT,
			"thin-fixed")
	end
end

return module