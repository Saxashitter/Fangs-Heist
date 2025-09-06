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

	for i, p in ipairs(team) do
		if not p
		or not p.valid then
			continue
		end

		local skin = skins[p.heist.locked_skin]
		local icon, null = GetSkinIcon(v, skin.name)
		local scale = GetPatchScale(icon, height, false)

		v.drawScaled(x*FU, y*FU, scale, icon, flags, v.getColormap(skin.name, p.skincolor))
		x = $ + height + 4
	end

	x = $ + 4

	local ty = y*FU + (height*FU-7*FU)/2
	FH.DrawString(v,x*FU,ty,FU,leader.name,"FHTXT",nil,flags)

	FH.DrawString(v,x*FU + FH.GetStringWidth(v,leader.name,FU,"FHTXT")+2*FU,ty,FU,"$"..team.profit,"FHTXT",nil,flags,v.getStringColormap(V_GREENMAP))
	v.drawScaled(70*FU + FH.GetStringWidth(v,"$"..team.profit,FU,"FHTXT")+2*FU,ty,FU,v.cachePatch("FHSTAT3"),V_SNAPTOTOP|V_SNAPTORIGHT)	
	FH.DrawString(v,90*FU + FH.GetStringWidth(v,"$"..team.profit,FU,"FHTXT")+2*FU,ty,FU,"$"..team.treasurestat,"FHTXT",nil,V_SNAPTOTOP|V_SNAPTORIGHT,v.getStringColormap(V_YELLOWMAP))
	for p in players.iterate
		if p.heist:hasSign()
			v.drawScaled(128*FU + FH.GetStringWidth(v,"$"..team.profit,FU,"FHTXT")+2*FU,ty,FU,v.cachePatch("FHSTAT4"),V_SNAPTOTOP|V_SNAPTORIGHT)	
		end
	end
	return true
end

function module.init()
end

function module.draw(v)
	local sw = v.width() / v.dupx()
	local sh = v.height() / v.dupy()
	local gamemode = FangsHeist.getGamemode()

	DrawRect(v, 0, TOPLINE_Y, sw, 1, V_SNAPTOTOP|V_SNAPTOLEFT, v.getColormap(TC_ALLWHITE,nil))
	FangsHeist.DrawString(v,MODE_X*FU, MODE_Y*FU,FU,  
	gamemode.name,"FHTXT",nil, V_SNAPTOTOP|V_SNAPTOLEFT, 
	v.getStringColormap(V_PURPLEMAP))

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

		DrawTeam(v, x, y, height, team, V_SNAPTOTOP)
	end
end

return module, "scores"
