local module = {}

local vwarp = FangsHeist.require"Modules/Libraries/vwarp"
local text = FangsHeist.require"Modules/Libraries/text"

local alpha
local retakealpha
local statealpha
local flashalpha
local current
local x

local retake_ticup
local retake_texty
local retake_laugh

local buttons
local lastbuttons

local sidemove
local lastside

local forwardmove
local lastforward

local scroll
local scale

local shakeFactor

local states = {
	FangsHeist.require"Modules/Handlers/Intermission/winners",
	FangsHeist.require"Modules/Handlers/Intermission/highscores",
	FangsHeist.require"Modules/Handlers/Intermission/vote"
}

FangsHeist.INTER_START_DELAY = 15

function module.init()
	shakeFactor = 0
	alpha = 0
	statealpha = 10
	retakealpha = 10
	flashalpha = 0
	current = 1
	buttons = 0
	lastbuttons = 0
	sidemove = 0
	lastside = 0
	retake_ticup = 2*TICRATE
	retake_laugh = retake_ticup+20
	retake_texty = 0
	forwardmove = 0
	lastforward = 0
	scroll = 0
	scale = FU*2

	for _,state in pairs(states) do
		if state.init then
			state.init()
		end
	end
end

freeslot("SKINCOLOR_REALLYREALLYBLACK")
skincolors[SKINCOLOR_REALLYREALLYBLACK] = {
    name = "GUHHH",
    ramp = {31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31},
    invcolor = SKINCOLOR_BLACK,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}
--The Color is the thing: This Color Matches the Player's Color and Fades Out to Black
freeslot("SKINCOLOR_INTERMISSIONCOLOR")
addHook("ThinkFrame",do
	local index = color.rgbToPalette(255,255,255) --All White, That's all
	if FangsHeist.Net.game_over
		if consoleplayer--Match the Player's Skincolor!
			local skincolor = skincolors[consoleplayer.skincolor].ramp[4]
			local r,g,b = color.paletteToRgb(skincolor)
			index = color.rgbToPalette(r,g,b)
		end
		if FangsHeist.Net.end_anim <= 75
			local r,g,b = color.paletteToRgb(index)
			local ticsperrgb = ease.linear(FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-60,15),FU)),255*FU,0)/FU
			local t = FU-max(0,min(FixedDiv(ticsperrgb,255),FU))

			local r1 = ease.linear(t, r, 0)
			local r2 = ease.linear(t, g, 0)
			local r3 = ease.linear(t, b, 0)
			local rgb = color.packRgb(r1, r2, r3)
			index = color.rgbToPalette(rgb)
		end
	end
	local hex = index
	skincolors[SKINCOLOR_INTERMISSIONCOLOR] = {
		ramp = {0,0,0,hex,0,0,0,0,0,0,0,0,0,0,0,0}, --All White except the 4th Ramp
		accessible = false
	}
end)
// UNEXPECTED HOOK GRAAAAHHH
addHook("PlayerCmd", function(_, _cmd)
	if not FangsHeist.Net.game_over then return end

	lastbuttons = buttons
	lastside = sidemove
	lastforward = forwardmove

	buttons = _cmd.buttons
	forwardmove = _cmd.forwardmove
	sidemove = _cmd.sidemove
end)

local function manage_fade_screen(v)
	if alpha < 10 then
		local div = FixedDiv(alpha, 10)/(FU/31)

		v.fadeScreen(0xFF00, div)
		return
	end

	v.drawFill()
end

local function draw_bg(v)
	if statealpha == 10 then return end
	local patch = v.cachePatch("FH_PINK_SCROLL")

	FangsHeist.DrawParallax(v,
		0,
		0,
		v.width()*FU/v.dupx(),
		v.height()*FU/v.dupy(), -- to make sure theres no clipping
		FU,
		patch,
		V_SNAPTOLEFT|V_SNAPTOTOP,
		patch.width*FixedDiv(leveltime % 60, 60),
		patch.height*FixedDiv(leveltime % 60, 60)
	)
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

local function draw_retake_factor(v)
	if not FangsHeist.Net.retaking then return end

	retakealpha = max(0, $-1)
	local f = V_10TRANS*retakealpha

	draw_rect(v, 0, 0, v.width()*FU/v.dupx(), v.height()*FU/v.dupy(), V_SNAPTOLEFT|V_SNAPTOTOP|f, SKINCOLOR_REALLYREALLYBLACK)

	if retake_ticup then
		retake_ticup = max(0, $-1)

		if retake_ticup == 0 then
			retake_texty = -4*FU
			S_StartSound(nil, sfx_menu1)
		end
	end
	if retake_laugh then
		retake_laugh = max(0, $-1)

		if retake_laugh == 0 then
			S_StartSound(nil, sfx_bewar1)
		end
	end

	local num = FangsHeist.Save.retakes
	if retake_ticup == 0 then
		num = $+1
	end

	FangsHeist.DrawString(v,
		160*FU,
		100*FU - 8*FU - 16*FU + retake_texty,
		scale,
		"RETAKES",
		"CRFNT",
		"center",
		0,
		v.getColormap(TC_RAINBOW, SKINCOLOR_RED))
	FangsHeist.DrawString(v,
		160*FU,
		100*FU - 8*FU + retake_texty,
		scale,
		tostring(num),
		"LTFNT",
		"center",
		0,
		v.getColormap(TC_RAINBOW, SKINCOLOR_RED))

	retake_texty = ease.linear(FU/4, $, 0)
end

// sucks to suck but how else am i gonna do this
addHook("PostThinkFrame", do
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.game_over then return end
	if FangsHeist.Net.retaking then return end
	if statealpha == 10 then return end

	local state = states[current]
	if not state then return end

	state.think({
		buttons = buttons;
		sidemove = sidemove;
		forwardmove = forwardmove;
		lastbuttons = lastbuttons;
		lastside = lastside;
		lastforward = lastforward
	})
end)

local function draw_intermission(v)
	if statealpha == 10 then return end

	scale = ease.linear(FU/15, $, FU)

	local warp = vwarp(v, {
		transp = statealpha,
		xorigin = (v.width()*FU/v.dupx())/2,
		yorigin = (v.height()*FU/v.dupy())/2,
		xscale = scale,
		yscale = scale
	})
	draw_bg(warp)

	local state = states[current]

	if state then
		state.draw(warp, consoleplayer)
	end
end

local function calc_tab_order(selected, count)
	local l = {}
	if selected > 1 then
		for i=1,(selected-1) do
			table.insert(l, i)
		end
	end
	if selected < count then
		for i=count,(selected+1),-1 do
			table.insert(l, i)
		end
	end
	table.insert(l, selected)
	return l
end

local function draw_tabs(v)
	if statealpha == 10 then return end

	local alpha = statealpha*V_10TRANS

	local tab_patch = v.cachePatch"FH_INTER_TAB"
	local dist = (tab_patch.width-16)*FU

	v.drawString(160*FU, tab_patch.height*FU, "Weapon Prev & Next", V_SNAPTOTOP|alpha, "thin-fixed-center")

	local tabOrder = calc_tab_order(current, #states)
	local xorigin = 160*FU - (dist*(#states-1))/2
	for _,i in ipairs(tabOrder) do
		local state = states[i]
		local x = xorigin+dist*(i-1)
		v.drawScaled(x, 0, FU, tab_patch, V_SNAPTOTOP|alpha)
		v.drawString(x,
			4*FU,
			state.name,
			V_ALLOWLOWERCASE|V_SNAPTOTOP|alpha|(current == i and V_YELLOWMAP or 0),
			"thin-fixed-center")
	end
end

local function manage_intermission(v)
	if statealpha == 10 then
		return
	end

	local select = 0

	if buttons & BT_WEAPONNEXT
	and not (lastbuttons & BT_WEAPONNEXT) then
		select = $+1
	end
	if buttons & BT_WEAPONPREV
	and not (lastbuttons & BT_WEAPONPREV) then
		select = $-1
	end

	local lastCurrent = current
	current = max(1, min($+select, #states))

	if lastCurrent ~= current then
		S_StartSound(nil, sfx_menu1)
	end
end
--Bouncing Ease i made, If you wanted to Use this code, Let me know
ease.inbounce = function(tic,s,m,e)
	local ts = max(0,min(FixedDiv(tic-(FU/2),FU/2),FU))
	local t = ease.linear(ts,0,180*FU)
	local tc = max(0,min(FixedDiv(tic,FU/2),FU))
	return ease.incubic(tc,s,e)+FixedMul(m,sin(FixedAngle(t))) --actual Bounce
end
/*
New GAME! Animation

Draws Game Sliding to Center with Boarder
And raise a little

then Shakes and Widen to Screen Height

and after Shaking Fades an Color to Black
*/
/*local draw_game = function(v)
	local sw = v.width()*FU/v.dupx()
	local m = 40*FU
	local e = sw
	local radius = ease.outback(
		FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-(5*TICRATE+15),20),FU)),
		0, m
	)
	local alphatext = 0
	local intiming = (3*TICRATE+32)
	if FangsHeist.Net.end_anim <= intiming
		if FangsHeist.Net.end_anim == intiming
		and not paused
			shakeFactor = 24*FU
		end
		radius = ease.linear(
			FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-(3*TICRATE+22),10),FU)),
			m, e
		)
	end
	if FangsHeist.Net.end_anim <= 75
		alphatext = ease.linear(
			FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-60,15),FU)),
			0, 10
		)
	end
	local sx = ease.outquad(
			FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-(5*TICRATE+15),20),FU)),
			-50*FU, 160*FU) 
	local tic = FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-(4*TICRATE-2),35),FU))
	local sy = ease.inquint(tic,175*FU,100*FU)
	draw_rect(v,
		0, sy-radius/2,
		sw,
		radius,
		V_SNAPTOLEFT,
		SKINCOLOR_INTERMISSIONCOLOR
	)
	if alphatext != 10
		local Gameset = v.cachePatch("FH_GAMESET")
		local x = sx + v.RandomRange(-shakeFactor, shakeFactor)
		local y = sy + v.RandomRange(-shakeFactor, shakeFactor)
		local t = FU-max(0,min(FixedDiv(FangsHeist.Net.end_anim-(intiming-10),10),FU))
		local scale = ease.outcubic(t,FU/2,FU)
		v.drawScaled(x,y,scale,Gameset,alphatext*V_10TRANS)
		shakeFactor = max(0, $-FU*3/2)
	end
end*/
function module.draw(v)
	if not (FangsHeist.Net.game_over) then
		shakeFactor = 12*FU
		flashalpha = 0
		return
	end

	-- GAME
	local scale = FU*2
	local x = 160*FU + v.RandomRange(-shakeFactor, shakeFactor)
	local y = 100*FU - (16*scale/2) + v.RandomRange(-shakeFactor, shakeFactor)

	FangsHeist.DrawParallax(v,
		0, 0,
		v.width()*FU/v.dupx(),
		v.height()*FU/v.dupy(),
		FU,
		v.cachePatch("SPECTILE"),
		V_SNAPTOTOP|V_SNAPTOLEFT
	)

	FangsHeist.DrawString(v,
		x,
		y,
		scale,
		"GAME!!",
		"CRFNT",
		"center",
		0,
		v.getColormap(TC_RAINBOW, SKINCOLOR_RED))
	shakeFactor = max(0, $-FU*3/2)

	-- flash
	if flashalpha < 10 then
		draw_rect(v,
			0, 0,
			v.width()*FU/v.dupx(),
			v.height()*FU/v.dupy(),
			V_SNAPTOLEFT|V_SNAPTOTOP|(V_10TRANS*flashalpha),
			SKINCOLOR_WHITE)
	end
	flashalpha = min($+1, 10)

	if FangsHeist.Net.end_anim then return end

	alpha = min($+1, 10)
	if FangsHeist.Net.game_over_ticker >= FangsHeist.INTER_START_DELAY then
		statealpha = max(0, $-1)
	end

	manage_fade_screen(v)
	if not FangsHeist.Net.retaking then
		manage_intermission(v)
	end
	draw_intermission(v)
	draw_tabs(v)
	draw_retake_factor(v)
end

return module,"gameandscores"