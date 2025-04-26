local module = {}

local SCORE_Y = (12+14*2)*FU

function module.init()
end

local function get_place(num)
	if num == 1 then
		return "1st"
	end

	if num == 2 then
		return "2nd"
	end

	if num == 3 then
		return "3rd"
	end

	return tostring(num).."th"
end

local function draw_p(v, team, placement, actualPlacement)
	actualPlacement = actualPlacement or placement

	if not (team[1] and team[1].valid) then return end

	local SCORE_X = 12*FU
	local target_y = (10*FU)*(placement-1)

	local scale = FU/2
	local profit = team.profit

	v.drawString(SCORE_X,
		SCORE_Y+target_y,
		get_place(actualPlacement),
		V_SNAPTOLEFT|V_SNAPTOTOP|V_ALLOWLOWERCASE,
		"thin-fixed")

	SCORE_X = $+2*FU+v.stringWidth(get_place(actualPlacement), V_ALLOWLOWERCASE, "thin")*FU

	for _,p in ipairs(team) do
		if not (p and p.valid) then continue end
		local life
		if skins[p.skin].sprites[SPR2_LIFE].numframes then 
			life = v.getSprite2Patch(p.skin,
				SPR2_LIFE, false, A, 0)
			scale = skins[p.skin].highresscale/2
		else
			life = v.cachePatch("CONTINS")
		end
		
		v.drawScaled(SCORE_X+life.leftoffset*scale,
			SCORE_Y+target_y+life.topoffset*scale-(2*scale),
			scale,
			life,
			V_SNAPTOTOP|V_SNAPTOLEFT,
			v.getColormap(skins[p.skin].name, p.skincolor))

		SCORE_X = $+2*FU+life.width*scale
	end

	local name = team[1].name
	if #team >= 2 then
		name = "Team "..$
	end

	v.drawString(SCORE_X,
		SCORE_Y+target_y,
		name,
		V_SNAPTOLEFT|V_SNAPTOTOP|(displayplayer.heist and FangsHeist.isPartOfTeam(displayplayer, team[1]) and V_YELLOWMAP or 0),
		"thin-fixed")

	local str_width = v.stringWidth(name, 0, "thin")

	v.drawString(SCORE_X+2*FU+str_width*FU,
		SCORE_Y+target_y,
		profit,
		V_SNAPTOLEFT|V_SNAPTOTOP|V_GREENMAP,
		"thin-fixed")

	local sign = false
	for _,sp in ipairs(team) do
		if sp
		and sp.valid
		and FangsHeist.isPlayerAlive(sp)
		and FangsHeist.playerHasSign(sp) then
			sign = true
			break
		end
	end

	if not sign then return end

	local str_width2 = v.stringWidth(tostring(profit), 0, "thin")

	v.drawString(SCORE_X+4*FU+str_width*FU+str_width2*FU,
		SCORE_Y+target_y,
		"SIGN",
		V_SNAPTOTOP|V_SNAPTOLEFT,
		"thin-fixed")
end

function module.draw(v)
	if FangsHeist.Net.pregame then return end
	if not multiplayer then return end
	if not (displayplayer and displayplayer.valid) then return end

	local drawedSelf = false
	local self = FangsHeist.getTeam(displayplayer)

	for i = 1,3 do
		local p = FangsHeist.Net.placements[i]

		if not p then continue end

		drawedSelf = $ or p == self
		draw_p(v, p, i, i)
	end

	if drawedSelf then return end
	if not self then return end

	local selfPlace = 0
	for place,team in ipairs(FangsHeist.Net.placements) do
		if team == self then
			selfPlace = place
			break
		end
	end

	draw_p(v, self, 4, selfPlace)
end

return module