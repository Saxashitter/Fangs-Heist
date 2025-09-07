local module = {}

local rect

local TOPLINE_Y = 16

local MODE_X = 6
local MODE_Y = TOPLINE_Y - 10

local PLAYER_X = 4
local PLAYER_Y = TOPLINE_Y + 5
local PLAYER_HEIGHT = 16
local PLAYER_SMALLHEIGHT = 9

local function IsSpriteValid(skin, sprite, frame)
	local skin = skins[skin]
	local sprites = skin.sprites[sprite]
	local numframes = sprites.numframes

	if numframes
	and numframes > frame then -- B = 2 so, check if it has the B frame
		return true
	end

	return false
end

local function GetSkinIcon(v, skin)
	if IsSpriteValid(skin, SPR2_XTRA, A) then
		return v.getSprite2Patch(skin, SPR2_XTRA, false, A)
	end

	if IsSpriteValid(skin, SPR2_LIFE, A) then
		return v.getSprite2Patch(skin, SPR2_LIFE, false, A)
	end

	return v.cachePatch("CONTINS"), true
end

local function GetPatchScale(sprite, targRes, scaleBy)
	local scale = FU

	if scaleBy == true then
		-- Scale down by the sprite's height.
		scale = FixedDiv(targRes, sprite.height)
	else
		-- Scale down by the sprite's width.
		scale = FixedDiv(targRes, sprite.width)
	end

	return scale
end

local function DrawRect(v, x, y, width, height, flags, color)
	if not rect
	or not rect.valid then
		rect = v.cachePatch("FH_BLACK")
	end

	local xscale = FixedDiv(width, rect.width)
	local yscale = FixedDiv(height, rect.height)

	v.drawStretched(
		x*FU, y*FU, xscale, yscale, rect, flags, color
	)
end

local function DrawOutline(v, x, y, width, height, flags, color)
	DrawRect(v, x, y, width, 1, flags, color)
	DrawRect(v, x + width - 1, y, 1, height, flags, color)
	DrawRect(v, x, y + height - 1, width, 1, flags, color)
	DrawRect(v, x, y, 1, height, flags, color)
end

local function DrawTeam(v, x, y, height, team, flags)
	local leader = team[1]
	local FH = FangsHeist
	if not leader
	or not leader.valid then
		return
	end

	local treasures = team.treasures
	local sign = false

	for i, p in ipairs(team) do
		if not p
		or not p.valid then
			continue
		end

		if p.heist and p.heist:hasSign() then
			sign = true
		end

		local skin = skins[p.heist.locked_skin]
		local icon, null = GetSkinIcon(v, skin.name)
		local scale = GetPatchScale(icon, height, false)

		v.drawScaled(x, y, scale, icon, flags, v.getColormap(skin.name, p.skincolor))
		x = $ + height*FU + 4*FU
	end

	x = $ + 4*FU

	local ty = y + (height*FU-7*FU)/2

	FH.DrawString(v,x,ty,FU,string.char(1)..team.profit,"FHTXT",nil,flags,v.getStringColormap(V_GREENMAP))
	x = $ + FH.GetStringWidth(v,string.char(1)..team.profit,FU,"FHTXT") + 4*FU

	FH.DrawString(v,x,ty,FU,leader.name,"FHTXT",nil,flags)
	x = $ + FH.GetStringWidth(v,leader.name,FU,"FHTXT")+4*FU

	v.drawScaled(x,ty,FU,v.cachePatch("FHSTAT3"),flags)
	x = $ + v.cachePatch("FHSTAT3").width*FU + 2*FU

	FH.DrawString(v,x,ty,FU,tostring(treasures),"FHTXT",nil,flags,v.getStringColormap(V_YELLOWMAP))
	x = $ + FH.GetStringWidth(v,tostring(treasures),FU,"FHTXT") + 4*FU

	if team.added_sign then
		v.drawScaled(x, ty, FU, v.cachePatch("FHSTAT4"), flags)
	end

	--[[for p in players.iterate
		if p.heist:hasSign()
			v.drawScaled(128*FU + FH.GetStringWidth(v,"$"..team.profit,FU,"FHTXT")+2*FU,ty,FU,v.cachePatch("FHSTAT4"),V_SNAPTOTOP|V_SNAPTORIGHT)	
		end
	end]]
	return true
end

function module.init()
end

function module.draw(v)
	local sw = v.width() / v.dupx()
	local sh = v.height() / v.dupy()
	local gamemode = FangsHeist.getGamemode()

	local p = consoleplayer

	DrawRect(v, 0, TOPLINE_Y, sw, 1, V_SNAPTOTOP|V_SNAPTOLEFT, v.getColormap(TC_ALLWHITE,nil))
	FangsHeist.DrawString(v,MODE_X*FU, MODE_Y*FU,FU,  
	gamemode.name,"FHTXT",nil, V_SNAPTOTOP|V_SNAPTOLEFT, 
	v.getStringColormap(V_PURPLEMAP))

	local stat1 = v.cachePatch("FHSTAT1")
	local stat2 = v.cachePatch("FHSTAT2")
	local badniks = p.heist.enemies
	local hits = p.heist.hitplayers + p.heist.deadplayers
	local width = stat1.width*FU
		+ 2*FU
		+ FangsHeist.GetStringWidth(v, tostring(badniks), FU, "FHTXT")
		+ 6*FU
		+ stat2.width*FU
		+ 2*FU
		+ FangsHeist.GetStringWidth(v, tostring(hits), FU, "FHTXT")
	local sx = (320 - 8)*FU - width
	v.drawScaled(sx,5*FU,FU,stat1,V_SNAPTOTOP|V_SNAPTORIGHT)
	sx = $ + stat1.width*FU + 2*FU

	FangsHeist.DrawString(v,sx,6*FU,FU,tostring(badniks),"FHTXT",nil,V_SNAPTOTOP|V_SNAPTORIGHT)
	sx = $ + FangsHeist.GetStringWidth(v, tostring(badniks), FU, "FHTXT") + 6*FU

	v.drawScaled(sx,5*FU,FU, stat2,V_SNAPTOTOP|V_SNAPTORIGHT)
	sx = $ + stat2.width*FU + 2*FU

	FangsHeist.DrawString(v,sx,6*FU,FU,tostring(hits),"FHTXT",nil,V_SNAPTOTOP|V_SNAPTORIGHT)

	local height = PLAYER_HEIGHT
	if #FangsHeist.Net.placements > 8 then
		height = PLAYER_SMALLHEIGHT
	end

	for i, team in ipairs(FangsHeist.Net.placements) do
		local x = PLAYER_X
		local y = PLAYER_Y + height*(i-1)

		if i > 16 then
			x = 160
			y = PLAYER_Y + height*((i-1)-16)
		end

		DrawTeam(v, x*FU, y*FU, height, team, V_SNAPTOTOP)
	end
end

return module, "scores"
