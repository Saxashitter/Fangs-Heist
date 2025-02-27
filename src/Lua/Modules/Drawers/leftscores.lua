local module = {}

local SCORE_Y = 50*FU

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

local function draw_p(v, p, placement, actualPlacement)
	actualPlacement = actualPlacement or placement
	local SCORE_X = 16*FU
	local target_y = (10*FU)*placement-1

	local scale = FU/2
	local profit = FangsHeist.returnProfit(p)

	v.drawString(SCORE_X,
		SCORE_Y+target_y,
		get_place(actualPlacement),
		V_SNAPTOLEFT|V_SNAPTOTOP|V_ALLOWLOWERCASE,
		"thin-fixed")

	SCORE_X = $+2*FU+v.stringWidth(get_place(actualPlacement), V_ALLOWLOWERCASE, "thin")*FU

	for p,_ in pairs(p.heist.team.players) do
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

	if not sign then return end

	local str_width2 = v.stringWidth(tostring(profit), 0, "thin")

	v.drawString(SCORE_X+4*FU+str_width*FU+str_width2*FU,
		SCORE_Y+target_y,
		"SIGN",
		V_SNAPTOTOP|V_SNAPTOLEFT,
		"thin-fixed")
end

function module.draw(v)
	local drawedSelf = false
	local self

	for _,data in pairs(FangsHeist.Net.placements) do
		local p = data.p
		if not (p and p.valid) then continue end

		if p == displayplayer
		or (displayplayer
		and displayplayer.valid
		and displayplayer.heist
		and FangsHeist.partOfTeam(p, displayplayer)) then
			self = data
		end

		if data.place > 3 then continue end

		if p == displayplayer
		or (displayplayer
		and displayplayer.valid
		and displayplayer.heist
		and FangsHeist.partOfTeam(displayplayer, p)) then
			drawedSelf = true
		end

		draw_p(v, p, data.place, data.place)
	end

	if drawedSelf then return end
	if not self then return end

	draw_p(v, self.p, 4, self.place)
end

return module