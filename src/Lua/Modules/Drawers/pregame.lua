local module = {}

function module.init() end

local function DrawBackground(v)
	local transparency = V_10TRANS * FangsHeist.Net.pregame_transparency
	local p = consoleplayer

	if not (p and p.valid) then
		v.drawFill()
		return
	end

	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()
	local char = FangsHeist.Characters[skins[p.skin].name]

	if char.customPregameBackground then
		char.customPregameBackground(v,consoleplayer)
		return
	end

	local patch = v.cachePatch(char.pregameBackground)
	local y = -patch.height*FU + (leveltime*FU/2) % (patch.height*FU)
	local x = -patch.width*FU + (leveltime*FU/2) % (patch.width*FU)

	while y < sh do
		local x = x

		while x < sw do
			v.drawScaled(x, y, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|transparency)
			x = $+patch.width*FU
		end
	
		y = $+patch.height*FU
	end
end

local function DrawState(v)
	local transparency = V_10TRANS * FangsHeist.Net.pregame_transparency

	if not consoleplayer
	or not consoleplayer.valid
	or not consoleplayer.heist then
		return
	end

	local state = FangsHeist.getPregameState(consoleplayer)

	if state.draw then
		state.draw(consoleplayer, v, c, transparency)
	end
	return state
end

local function ShouldDraw()
	if FangsHeist.Net.pregame then return true end
	if FangsHeist.Net.pregame_transparency < 10 then return true end

	return false
end

local function GetXYCoords(v, x, y)
	local sw = v.width() / v.dupx()
	local sh = v.height() / v.dupy()

	return x * sw, y * sh
end

function module.draw(v)
	if not ShouldDraw() then
		return
	end

	local transparency = V_10TRANS * FangsHeist.Net.pregame_transparency

	DrawBackground(v)
	local state = DrawState(v)

	local num = FangsHeist.Net.pregame_time/TICRATE
	local str = tostring(num)
	local x = 4*FU
	local y = 4*FU

	if state
	and state.time_x ~= nil
	and state.time_y ~= nil then
		x, y = GetXYCoords(v, state.time_x, state.time_y)
	end

	if state
	and state.time_ox then
		x = $ + state.time_ox
	end

	if state
	and state.time_oy then
		y = $ + state.time_oy
	end

	FangsHeist.DrawString(v,x,y,FU/2,str,"FHBFT",nil,V_SNAPTOTOP|V_SNAPTOLEFT|transparency,v.getColormap(TC_DEFAULT,SKINCOLOR_MAUVE))
end

return module, "gameandscores"

--[[local text = FangsHeist.require "Modules/Libraries/text"

local START_CHAR_X = 320*FU
local END_CHAR_X = 320*FU - 98*FU
local CHAR_TWEEN = 10

local CHAROVERLAY_START_RADIUS = 5*FU
local CHAROVERLAY_END_RADIUS = 40*FU
local CHAROVERLAY_TWEEN = 7

-- start x defined by text width
local TEXT_END_X = 8*FU
local TEXT_DELAY = 4
local TEXT_TWEEN = 12

local chartween = 0
local overlaytween = 0
local texttween = 0
local textdelay = 0
local lastskin = 0
local alpha = 0
local lastlockskin = 0

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

function module.init()
	chartween = 0
	overlaytween = 0
	lastskin = 0
	texttween = 0
	textdelay = 0
end

local function draw_rect(v, x, y, w, h, flags, color)
	local patch = v.cachePatch("FH_PINK_SCROLL")
	v.drawStretched(
		x, y,
		FixedDiv(w, patch.width*FU),
		FixedDiv(h, patch.height*FU),
		patch,
		flags,
		color and v.getColormap(TC_BLINK, color)
	)
end

local FONT_FORMAT = "%s%03d"
local PATCHES = {}

local function CachePatch(v, name)
	if not (PATCHES[name] and PATCHES[name].valid) then
		PATCHES[name] = v.cachePatch(name)
	end

	return PATCHES[name]
end

local function DrawWrappedString(v, x, y, string, limit, flags, align)
	local loops = max(1,#string/limit)

	for i = 1,loops+1 do
		local start = max(0, limit*(i-1))+1
		if limit*(i-1) > #string then
			return
		end

		local string = string:sub(start, min(limit*i, #string))
		v.drawString(x, y, string, flags, align)

		y = $+9
	end
end

local function draw_cs(v,p)
	v.drawString(160, 4, "CHARACTER SELECT", V_SNAPTOTOP|f, "center")
	local gamemode = FangsHeist.getGamemode()

	local skin = skins[p.heist.locked_skin]
	local char = FangsHeist.Characters[skin.name]

	local sw = v.width()*FU/v.dupx()
	local sh = v.height()*FU/v.dupy()
	local f = alpha*V_10TRANS

	-- icon underlay
	local limit = 17+1
	local oy = 16*FU

	local x = 160*FU
	local y = 4*FU + 11*FU + 2*FU
	local adds = 0

	local maxscale = FU*3/2
	local minscale = FU
	local width = ((16*minscale)*(#skins-1)) + 16*maxscale

	x = $ - width/2

	for i = 0,#skins-1 do
		if not (p and p.valid) then break end

		if (i+1)/limit > adds then
			x = 16*FU
			y = $+oy
			adds = (i+1)/limit
		end

		local patch
		local scale = minscale

		--Icon Tweening :p
		if i == p.heist.locked_skin then
			scale = ease.outquint(FixedDiv(chartween, CHAR_TWEEN),minscale,maxscale)
		end
		if i == p.heist.lastlockskin then
			scale = ease.outquint(FixedDiv(chartween, CHAR_TWEEN),maxscale,minscale)
		end

		if IsSpriteValid(i, SPR2_LIFE, A) then 
			patch = v.getSprite2Patch(i, SPR2_LIFE, false, A)
			scale = FixedMul($, skins[i].highresscale)
		else
			patch = v.cachePatch("CONTINS")
		end

		v.drawScaled(x + patch.leftoffset*scale,
			y + patch.topoffset*scale,
			scale,
			patch,
			V_SNAPTOTOP|f,
			v.getColormap(skins[i].name, skins[i].prefcolor))

		x = x + patch.width*scale
	end

	y = $+4*FU
	y = $+CHAROVERLAY_END_RADIUS

	-- character underlay
	local radius = ease.outquad(
		FixedDiv(overlaytween, CHAROVERLAY_TWEEN),
		CHAROVERLAY_START_RADIUS, CHAROVERLAY_END_RADIUS
	)

	local behindpatch = v.cachePatch("FH_PINK_SCROLL")

	draw_rect(v,
		0, y-radius/2,
		sw,
		radius,
		V_SNAPTOLEFT|V_SNAPTOTOP|f,
		skin.prefcolor
	)

	-- character
	local patch
	if IsSpriteValid(p.heist.locked_skin, SPR2_FHBN, A) then -- B = 2 so, check if it has the B frame
		patch = v.getSprite2Patch(p.heist.locked_skin, SPR2_FHBN, false, A)
	elseif IsSpriteValid(p.heist.locked_skin, SPR2_XTRA, B) then -- B = 2 so, check if it has the B frame
		patch = v.getSprite2Patch(p.heist.locked_skin, SPR2_XTRA, false, B)
	else
		patch = v.cachePatch("MISSING") -- what srb2 defaults to if XTRAB is missing
	end

	local scale = (FU/4)*3

	local x = ease.outquad(
		FixedDiv(chartween, CHAR_TWEEN),
		START_CHAR_X, END_CHAR_X
	)

	v.drawScaled(x+5*FU, y+5*FU - patch.height*scale/2, scale, patch, V_SNAPTORIGHT|V_SNAPTOTOP|f,
		v.getColormap(TC_BLINK, skin.prefcolor))
	v.drawScaled(x, y - patch.height*scale/2, scale, patch, V_SNAPTORIGHT|V_SNAPTOTOP|f)

	-- text

	local scale = FU
	local START_TEXT_X = -FangsHeist.GetStringWidth(v, skin.realname:upper(), scale, "CRFNT")
	local x = ease.outquad(
		FixedDiv(texttween, TEXT_TWEEN),
		START_TEXT_X, TEXT_END_X
	)

	FangsHeist.DrawString(v,
		x,
		y-(16*scale/2),
		scale,
		skin.realname:upper(),
		"CRFNT",
		"left",
		V_SNAPTOLEFT|V_SNAPTOTOP|f,
		v.getColormap(TC_RAINBOW, skin.prefcolor))

	local info = gamemode:info()
	if not (info and #info) then return end

	v.drawString(4, 110, "Round Info:", V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE|V_YELLOWMAP, "thin")

	local y = 110+10

	for _, tbl in ipairs(info) do
		for i, info in ipairs(tbl) do
			local x = 8
			local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE

			if i == 1 then
				x = 4
				f = ($|V_REDMAP) & ~V_ALLOWLOWERCASE
			end
	
			v.drawString(x, y, info, f, "thin")
			y = $+10
		end
	end
end

local function draw_menu(v,x,y,width,height,items,selected,dispoffset,flags)
	local black = v.cachePatch("FH_BLACK")
	local length = 8
	local i = dispoffset-length+1
	local iter = 0

	for i = i, i+length do
		local str = items[i]

		local y = y + height*iter

		local color = SKINCOLOR_CORNFLOWER
		if i == selected
		and #items then
			color = SKINCOLOR_SKY
		end

		draw_rect(v, x*FU, y*FU, width*FU, height*FU, flags, color)
		iter = $+1

		if not str
		or not #items then continue end

		if #str > 16 then
			str = string.sub($, 1, 16)
		end
		
		v.drawString(x+4, y+4, str, flags|V_ALLOWLOWERCASE, "thin")
	end

	if not #items then
		v.drawString(x+width/2, y+(height/2)-4, "No players!", flags, "thin-center")
	end
end

local function draw_team(v,p)
	local f = alpha*V_10TRANS

	v.drawString(160, 4, "TEAM SELECT", V_SNAPTOTOP|f, "center")

	// Players
	local length = 8
	local i = p.heist.hud_sel-length+1
	local iter = 0

	local boxheight = 16
	local boxwidth = 80

	local teamleng = max(0, FangsHeist.CVars.team_limit.value)

	local names = {}
	if p.heist.playersList then
		for _,p in ipairs(p.heist.playersList) do
			if not (p and p.valid) then continue end
			table.insert(names, p.name)
		end
	end

	local hud_sel = p.heist.hud_sel
	local cur_sel = p.heist.cur_sel

	if p.heist.cur_menu ~= -1 then
		cur_sel = 0
		hud_sel = 8
	end

	if p.heist:isTeamLeader()
	and #p.heist:getTeam() < teamleng then
		v.drawString(6, 24-8, "JOIN PLAYERS", V_SNAPTOLEFT|f, "thin")
		draw_menu(v, 6, 24, 80, 16, names, cur_sel, hud_sel, V_SNAPTOLEFT|f)
	end

	local hud_sel = p.heist.hud_sel
	local cur_sel = p.heist.cur_sel

	if p.heist.cur_menu ~= 1 then
		cur_sel = 0
		hud_sel = 8
	end

	local requests = {}

	if p.heist.invitesList then
		for _,sp in ipairs(p.heist.invitesList) do
			if sp and sp.valid then
				table.insert(requests, sp.name)
			end
		end
	end

	if p.heist:isTeamLeader()
	and #p.heist:getTeam() < teamleng then
		v.drawString(320-86, 24-8, "JOIN REQUESTS", V_SNAPTORIGHT|f, "thin")
		draw_menu(v, 320-86, 24, 80, 16, requests, cur_sel, hud_sel, V_SNAPTORIGHT|f)
	end

	// ready button
	local ready = v.cachePatch("FH_READYUNSELECT")
	local scale = FU
	local color

	if p.heist.cur_menu == 0 then
		ready = v.cachePatch("FH_READYSELECT")
		scale = tofixed("1.25")
	end

	v.drawScaled(
		160*FU - ready.width*scale/2,
		200*FU - 4*FU - ready.height*scale,
		scale,
		ready,
		V_SNAPTOBOTTOM|f,
		color)

	local i = 1
	local team = p.heist:getTeam()

	if team then
		v.drawString(160, 4+10, "Team:", V_SNAPTOTOP|V_ALLOWLOWERCASE|f, "center")
		for _,sp in ipairs(team) do
			if not (sp and sp.valid and sp.heist) then
				continue
			end
			
			local name = sp.name
			local f = f|V_SNAPTOTOP
	
			if sp.heist:isTeamLeader() then
				f = $|V_YELLOWMAP
			end
	
			if #name > 16 then
				name = string.sub(name, 1, 16)
			end
	
			v.drawString(160, 4+10 + (10*i), name, V_SNAPTOTOP|f, "thin-center")
			i = $+1
		end
	end
end

function module.draw(v,p)
	if not FangsHeist.Net.pregame then
		alpha = min($+1, 10)
		if alpha == 10 then module.init() return end
	else
		alpha = 0
	end

	local sw = v.width()*FU/v.dupx()
	local sh = v.height()*FU/v.dupy()
	local f = alpha*V_10TRANS

	local skin = consoleplayer
	and consoleplayer.heist
	and consoleplayer.heist.locked_skin or 0

	-- background
	if not FangsHeist.Net.pregame_cam.enabled then
		local char = FangsHeist.Characters[skins[skin].name]
		if not char.customPregameBackground then
			local patch = v.cachePatch(char.pregameBackground)
			local y = -patch.height*FU + (leveltime*FU/2) % (patch.height*FU)
			local x = -patch.width*FU + (leveltime*FU/2) % (patch.width*FU)
		
			while y < sh do
				local x = x
		
				while x < sw do
					v.drawScaled(x, y, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|f)
					x = $+patch.width*FU
				end
			
				y = $+patch.height*FU
			end
		else
			char.customPregameBackground(v,consoleplayer)
		end
	else
		v.fadeScreen(0xFF00, 31/3)
	end

	local num = FangsHeist.Net.pregame_time/TICRATE
	local str = tostring(num)
	local x = 4*FU

	FangsHeist.DrawNumber(v,x,0,FU/2,num,"FHBFT",V_SNAPTOTOP|V_SNAPTOLEFT|f,v.getColormap(TC_DEFAULT,SKINCOLOR_MAUVE))

	chartween = min($+1, CHAR_TWEEN)
	overlaytween = min($+1, CHAROVERLAY_TWEEN)
	textdelay = min($+1, TEXT_DELAY)
	if textdelay == TEXT_DELAY then
		texttween = min($+1, TEXT_TWEEN)
	end

	if not (consoleplayer and consoleplayer.heist) then return end

	local p = consoleplayer
	local skin = skins[p.heist.locked_skin]

	if lastskin ~= p.heist.locked_skin then
		lastskin = p.heist.locked_skin
		chartween = 0
		overlaytween = 0
		texttween = 0
		textdelay = 0
	end

	local gamemode = FangsHeist.getGamemode()

	if not p.heist.confirmed_skin then
		draw_cs(v,p)
		return
	end

	if not p.heist.locked_team
	and gamemode.teams then
		draw_team(v,p)
		return
	end

	v.drawString(160, 100, "Waiting for players...", V_ALLOWLOWERCASE|f, "center")
end]]