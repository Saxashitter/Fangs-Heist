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
	local skin = skins[p.heist.locked_skin]

	local sw = v.width()*FU/v.dupx()
	local sh = v.height()*FU/v.dupy()
	local f = alpha*V_10TRANS

	-- icon underlay
	local x = 16*FU
	local y = 60*FU
	for i = 0,#skins-1 do
		local patch = v.getSprite2Patch(i, SPR2_LIFE, false, A)

		local scale = FU
		if i == p.heist.locked_skin then
			scale = FU*3/2
		end
		v.drawScaled(x + patch.leftoffset*scale,
			y,
			scale,
			patch,
			V_SNAPTOLEFT|f,
			v.getColormap(nil, skins[i].prefcolor))

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
	local patch = v.getSprite2Patch(p.heist.locked_skin, SPR2_XTRA, false, B)
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
		100*FU-radius/2,
		skin.realname:upper(),
		"CSFNT",
		V_SNAPTOLEFT|f,
		"left",
		FU,
		skin.prefcolor
	)
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

	-- background
	local patch = v.cachePatch("FH_PINK_SCROLL")
	local y = -16*FU + (leveltime*FU/2) % (patch.height*FU)
	local x = -16*FU + (leveltime*FU/2) % (patch.width*FU)

	while y < sh do
		local x = x

		while x < sw do
			v.drawScaled(x, y, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|f)
			x = $+patch.width*FU
		end
	
		y = $+patch.height*FU
	end

	v.drawString(160, 4, "PREGAME", V_SNAPTOTOP|f, "center")

	local num = FangsHeist.Net.pregame_time/TICRATE
	local str = tostring(num)
	local x = 4*FU

	for i = 1,#str do
		local num = tonumber(string.sub(str, i, i))
		local patch = v.cachePatch("STTNUM"..num)

		v.drawScaled(x, 4*FU, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|f)
		x = $+patch.width*FU
	end

	v.drawString(4, 20, "To request to join a team, use \"fh_jointeam nameornode\" in the console!", V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE|f, "thin")
	v.drawString(4, 20+8, "Names are case-sensitive.", V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE|f, "thin")

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

	v.drawString(160, 100, "Waiting for players...", V_ALLOWLOWERCASE|f, "center")
end

return module, "gameandscores"