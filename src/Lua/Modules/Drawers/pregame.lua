local module = {}

local text = FangsHeist.require "Modules/Libraries/text"

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

local function draw_cs(v,p)
	v.drawString(160, 4, "CHARACTER SELECT", V_SNAPTOTOP|f, "center")
	local skin = skins[p.heist.locked_skin]

	local sw = v.width()*FU/v.dupx()
	local sh = v.height()*FU/v.dupy()
	local f = alpha*V_10TRANS

	-- icon underlay
	local limit = 17+1
	local oy = 16*FU

	local x = 16*FU
	local y = 60*FU - oy*#skins/limit
	local adds = 0

	for i = 0,#skins-1 do
		if not (p and p.valid) then break end

		if (i+1)/limit > adds then
			x = 16*FU
			y = $+oy
			adds = (i+1)/limit
		end

		local patch
		local scale = FU
		if skins[i].sprites[SPR2_LIFE].numframes then 
			patch = v.getSprite2Patch(i, SPR2_LIFE, false, A)
			scale = skins[i].highresscale
		else
			patch = v.cachePatch("CONTINS")
		end
		--Icon Tweening :p
		if i == p.heist.locked_skin then
			scale = ease.outquint(FixedDiv(chartween, CHAR_TWEEN),$,3*$/2)
		end
		if i == p.heist.lastlockskin then
			scale = ease.outquint(FixedDiv(chartween, CHAR_TWEEN),3*$/2,$)
		end
		v.drawScaled(x + patch.leftoffset*scale,
			y + patch.topoffset*scale,
			scale,
			patch,
			V_SNAPTOLEFT|f,
			v.getColormap(skins[i].name, skins[i].prefcolor))

		x = x + patch.width*scale
	end

	-- character underlay
	local radius = ease.outquad(
		FixedDiv(overlaytween, CHAROVERLAY_TWEEN),
		CHAROVERLAY_START_RADIUS, CHAROVERLAY_END_RADIUS
	)

	local behindpatch = v.cachePatch("FH_PINK_SCROLL")

	draw_rect(v,
		0, 100*FU-radius/2,
		sw,
		radius,
		V_SNAPTOLEFT|f,
		skin.prefcolor
	)

	-- character
	local patch
	if skins[p.heist.locked_skin].sprites[SPR2_XTRA].numframes >= 2 then -- B = 2 so, check if it has the B frame
		patch = v.getSprite2Patch(p.heist.locked_skin, SPR2_XTRA, false, B)
	else
		patch = v.cachePatch("MISSING") -- what srb2 defaults to if XTRAB is missing
	end
	local scale = (FU/4)*3

	local x = ease.outquad(
		FixedDiv(chartween, CHAR_TWEEN),
		START_CHAR_X, END_CHAR_X
	)

	v.drawScaled(x+5*FU, 105*FU - patch.height*scale/2, scale, patch, V_SNAPTORIGHT|f,
		v.getColormap(TC_BLINK, skin.prefcolor))
	v.drawScaled(x, 100*FU - patch.height*scale/2, scale, patch, V_SNAPTORIGHT|f)

	-- text

	local scale = FU
	local START_TEXT_X = -customhud.CustomFontStringWidth(v, skin.realname:upper(), "CSFNT", scale)
	local x = ease.outquad(
		FixedDiv(texttween, TEXT_TWEEN),
		START_TEXT_X, TEXT_END_X
	)

	customhud.CustomFontString(v,
		x,
		100*FU-(radius/2)+(20*scale/2),
		skin.realname:upper(),
		"CSFNT",
		V_SNAPTOLEFT|f,
		"left",
		scale,
		skin.prefcolor
	)
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

	local teamleng = max(0, FangsHeist.CVars.team_limit.value-1)

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

	if FangsHeist.isTeamLeader(p)
	and FangsHeist.getTeamLength(p) < teamleng then
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

	if FangsHeist.isTeamLeader(p)
	and FangsHeist.getTeamLength(p) < teamleng then
		v.drawString(320-86, 24-8, "JOIN REQUESTS", V_SNAPTORIGHT|f, "thin")
		draw_menu(v, 320-86, 24, 80, 16, requests, cur_sel, hud_sel, V_SNAPTORIGHT|f)
	end

	// ready button
	local ready = v.cachePatch("FH_READY")
	local scale = FU
	local color = v.getColormap(TC_RAINBOW, SKINCOLOR_GREY)
	if p.heist.cur_menu == 0 then
		scale = tofixed("1.25")
		color = nil
	end
	v.drawScaled(
		160*FU - ready.width*scale/2,
		200*FU - 4*FU - ready.height*scale,
		scale,
		ready,
		V_SNAPTOBOTTOM|f,
		color)


	local i = 1
	local team = FangsHeist.getTeam(p)

	if team then
		v.drawString(160, 4+10, "Team:", V_SNAPTOTOP|V_ALLOWLOWERCASE|f, "center")
		for _,sp in ipairs(team) do
			if not (sp and sp.valid and sp.heist) then
				continue
			end
			
			local name = sp.name
			local f = f|V_SNAPTOTOP
	
			if FangsHeist.isTeamLeader(sp) then
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

	local skin = displayplayer
	and displayplayer.heist
	and displayplayer.heist.locked_skin or 0

	-- background
	local patch = v.cachePatch(
		FangsHeist.Characters[skins[skin].name].pregameBackground
	)
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

	local num = FangsHeist.Net.pregame_time/TICRATE
	local str = tostring(num)
	local x = 4*FU

	for i = 1,#str do
		local num = tonumber(string.sub(str, i, i))
		local patch = v.cachePatch("STTNUM"..num)

		v.drawScaled(x, 4*FU, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|f)
		x = $+patch.width*FU
	end

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

	if not p.heist.confirmed_skin then
		draw_cs(v,p)
		return
	end

	if not p.heist.locked_team then
		draw_team(v,p)
		return
	end

	v.drawString(160, 100, "Waiting for players...", V_ALLOWLOWERCASE|f, "center")
end

return module, "gameandscores"