local module = {}

-- TODO: rework heavily

local SCORE_Y = 8*FU

function module.init()
end

local function get_place(num) --Updated with Place, Color, And Additive Blend (as Boolean)
	if num == 1 then
		return "1st",V_YELLOWMAP,true
	end

	if num == 2 then
		return "2nd",0,false
	end

	if num == 3 then
		return "3rd",V_BROWNMAP,false
	end

	return tostring(num).."th",0,false
end

local function draw_p(v, team, placement, actualPlacement)
	actualPlacement = actualPlacement or placement
	local FH = FangsHeist
	
	if not (team[1] and team[1].valid) then return end
	local SCORE_X = 8*FU
	local target_y = (10*FU)*(placement-1)

	local scale = FU/2
	local profit = team.profit
	local str,color,additive = get_place(actualPlacement)
	local flags = V_SNAPTOLEFT|V_SNAPTOTOP
	if additive == true then
		flags = $|V_ADD
	end
	FH.DrawString(v,SCORE_X,SCORE_Y+target_y,FU,
		str,"FHTXT",nil,flags,
		v.getStringColormap(color))

	SCORE_X = $+2*FU+FH.GetStringWidth(v,str,FU,"FHTXT")

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
			v.getColormap(p.heist.locked_skin, p.skincolor))

		SCORE_X = $+2*FU+life.width*scale
	end

	local name = team[1].name
	if #team >= 2 then
		name = "Team "..$
	end
	local namecolor = (displayplayer.heist and displayplayer.heist:isPartOfTeam(team[1])) and V_YELLOWMAP or nil
	FH.DrawString(v,SCORE_X,SCORE_Y+target_y,FU,
		name,"FHTXT",nil,V_SNAPTOLEFT|V_SNAPTOTOP,
		namecolor and v.getStringColormap(namecolor))

	local str_width = FH.GetStringWidth(v,name,FU,"FHTXT")
	local profittotal = tostring(profit)
	FH.DrawString(v,SCORE_X+2*FU+str_width,SCORE_Y+target_y,FU,
		profittotal,"FHTXT",nil,V_SNAPTOLEFT|V_SNAPTOTOP,
		v.getStringColormap(V_GREENMAP))

	local sign = false
	for _,sp in ipairs(team) do
		if sp
		and sp.valid
		and sp.heist
		and sp.heist:isAlive()
		and sp.heist:hasSign() then
			sign = true
			break
		end
	end

	if not sign then return end

	local signwidth = 4*FU+str_width+FH.GetStringWidth(v,profittotal,FU,"FHTXT")
	local blink = (leveltime/2%4) >= 2 and V_REDMAP or V_GRAYMAP
	FH.DrawString(v,SCORE_X+signwidth,SCORE_Y+target_y,FU,
		"SIGN","FHTXT",nil,V_SNAPTOLEFT|V_SNAPTOTOP,
		v.getStringColormap(blink))
end

local function tag_team(v)
	if not FangsHeist.Net.hskins then return end

	local SCORE_X = 12*FU
	local x = SCORE_X

	v.drawString(SCORE_X, SCORE_Y, "TAG TEAM", V_SNAPTOLEFT|V_SNAPTOTOP, "thin-fixed")

	for i = 1, #FangsHeist.Net.hskins do
		local skin = FangsHeist.Net.hskins[i]
		local color = v.getColormap(TC_RAINBOW, SKINCOLOR_GREY)
		local scale = skins[skin.skin].highresscale/2
		local patch = v.getSprite2Patch(skin.skin,
			SPR2_LIFE, false, A, 0)

		if (skin.plyr
		and skin.plyr.valid
		and skin.plyr.heist
		and not skin.plyr.heist.spectator) then
			color = v.getColormap(skin.skin, skin.plyr.skincolor)
		end

		v.drawScaled(x + patch.leftoffset*scale,
			SCORE_Y + 10*FU + patch.topoffset*scale,
			scale,
			patch,
			V_SNAPTOTOP|V_SNAPTOLEFT,
			color)

		x = $ + patch.width*scale
	end
end

local function escape(v)
	local drawedSelf = false
	local self = displayplayer.heist:getTeam()

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

function module.draw(v)
	if FangsHeist.Net.pregame then return end
	if not multiplayer then return end
	if not (displayplayer and displayplayer.valid) then return end

	if FangsHeist.getGamemode().index == FangsHeist.TagTeam then
		tag_team(v)
		return
	end

	escape(v)
end

return module