local module = {}

local vwarp = FangsHeist.require"Modules/Libraries/vwarp"
local text = FangsHeist.require"Modules/Libraries/text"

local alpha
local statealpha
local current
local x

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
	FangsHeist.require"Modules/Handlers/Intermission/personalstats",
	FangsHeist.require"Modules/Handlers/Intermission/winners",
	FangsHeist.require"Modules/Handlers/Intermission/highscores",
	FangsHeist.require"Modules/Handlers/Intermission/vote"
}

FangsHeist.INTER_START_DELAY = 15

function module.init()
	shakeFactor = 12*FU
	alpha = 0
	statealpha = 10
	current = 2
	buttons = 0
	lastbuttons = 0
	sidemove = 0
	lastside = 0
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

	local bg = v.cachePatch"FH_INTER_BG"

	local xs = FU
	local ys = FU

	local sw = v.width()*FU/v.dupx()
	local sh = v.height()*FU/v.dupy()

	local sws = FixedDiv(sw, 320*FU)
	local shs = FixedDiv(sh, 200*FU)

	if sw > bg.width*FU then
		xs = sws
		ys = sws
	else
		xs = shs
		ys = shs
	end

	v.drawStretched(sw/2 - bg.width*xs/2,
		sh/2 - bg.height*ys/2,
		xs,
		ys,
		bg,
		V_SNAPTOLEFT|V_SNAPTOTOP)
end

// sucks to suck but how else am i gonna do this
addHook("PostThinkFrame", do
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.game_over then return end
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

	v.drawString(0, tab_patch.height*FU, "Weapon Prev & Next", V_SNAPTOLEFT|V_SNAPTOTOP|alpha, "thin-fixed")

	local tabOrder = calc_tab_order(current, #states)
	local xorigin = 160*FU - (dist*(#states-1))/2
	for _,i in ipairs(tabOrder) do
		local state = states[i]
		local x = xorigin+dist*(i-1)
		v.drawScaled(x, 0, FU, tab_patch, V_SNAPTOLEFT|V_SNAPTOTOP|alpha)
		v.drawString(x,
			4*FU,
			state.name,
			V_ALLOWLOWERCASE|V_SNAPTOLEFT|V_SNAPTOTOP|alpha|(current == i and V_YELLOWMAP or 0),
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

	current = max(1, min($+select, #states))
end

function module.draw(v)
	if not (FangsHeist.Net.game_over) then return end

	text.draw(v,
		160*FU + v.RandomRange(-shakeFactor, shakeFactor),
		100*FU - 21*FU + v.RandomRange(-shakeFactor, shakeFactor),
		FU*2,
		"GAME!",
		"FHFNT",
		"center",
		0,
		v.getColormap(nil, SKINCOLOR_RED)
	)
	shakeFactor = max(0, $-FU*3/2)

	if FangsHeist.Net.end_anim then return end
	alpha = min($+1, 10)
	if FangsHeist.Net.game_over_ticker >= FangsHeist.INTER_START_DELAY then
		statealpha = max(0, $-1)
	end

	manage_fade_screen(v)
	manage_intermission(v)
	draw_intermission(v)
	draw_tabs(v)
end

return module,"gameandscores"