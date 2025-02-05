local module = {}

local SCORE_Y = 50*FU

function module.init()
end

function module.draw(v)
	for _,data in pairs(FangsHeist.Net.placements) do
		local placement = data.place
		local p = data.p
		local SCORE_X = 16*FU

		if not (p and p.valid) then continue end

		local target_y = (10*FU)*(placement-1)

		if placement > 3 then continue end

		local scale = FU/2
		local profit = FangsHeist.returnProfit(p)

		for p,_ in pairs(p.heist.team.players) do
			if not (p and p.valid) then continue end
			local life = v.getSprite2Patch(p.skin,
				SPR2_LIFE, false, A, 0)
	
			v.drawScaled(SCORE_X+life.leftoffset*scale,
				SCORE_Y+target_y+life.topoffset*scale-(2*scale),
				scale,
				life,
				V_SNAPTOTOP|V_SNAPTOLEFT,
				v.getColormap(nil, p.skincolor))
	
			SCORE_X = $+2*FU+life.width*scale
		end

		local name = p.name
		if FangsHeist.getTeamLength(p) then
			name = "TEAM "..$
		end

		v.drawString(SCORE_X,
			SCORE_Y+target_y,
			name,
			V_SNAPTOLEFT|V_SNAPTOTOP|(displayplayer.heist and FangsHeist.partOfTeam(displayplayer, p) and V_YELLOWMAP or 0),
			"thin-fixed")

		local str_width = v.stringWidth(name, 0, "thin")

		v.drawString(SCORE_X+2*FU+str_width*FU,
			SCORE_Y+target_y,
			profit,
			V_SNAPTOLEFT|V_SNAPTOTOP|V_GREENMAP,
			"thin-fixed")

		local sign = false
		for sp,_ in pairs(p.heist.team.players) do
			if not (sp and sp.valid) then continue end

			sign = FangsHeist.playerHasSign(sp)
			if sign then
				break
			end
		end

		if not sign then continue end
		local str_width2 = v.stringWidth(tostring(profit), 0, "thin")

		v.drawString(SCORE_X+4*FU+str_width*FU+str_width2*FU,
			SCORE_Y+target_y,
			"SIGN",
			V_SNAPTOTOP|V_SNAPTOLEFT,
			"thin-fixed")
	end
end

return module