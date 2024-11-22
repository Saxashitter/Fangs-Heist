local module = {}

local vwarp = FangsHeist.require"Modules/Libraries/vwarp"

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

local states = {
	FangsHeist.require"Modules/Handlers/Intermission/personalstats",
	FangsHeist.require"Modules/Handlers/Intermission/winners",
	FangsHeist.require"Modules/Handlers/Intermission/vote"
}

FangsHeist.INTER_START_DELAY = 15

function module.init()
	alpha = 0
	statealpha = 10
	current = 2
	x = 0
	buttons = 0
	lastbuttons = 0
	sidemove = 0
	lastside = 0
	forwardmove = 0
	lastforward = 0
	scroll = 0
	scale = FU*2
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

	local bg = v.cachePatch"FH_PINK_SCROLL"
	local scale = FU*2
	scroll = $-(FU/2) % (bg.width*scale)
	local transp = V_10TRANS*statealpha

	local x = scroll
	local y = scroll

	local original_x = x

	while y < v.height()*FU/v.dupy() do
		while x < v.width()*FU/v.dupx() do
			v.drawScaled(x, y, scale, bg, V_SNAPTOTOP|V_SNAPTOLEFT|transp)
			x = $+bg.width*scale
		end
		x = original_x
		y = $+bg.height*scale
	end
end

local function draw_intermission(v)
	if statealpha == 10 then return end

	local x = FixedMul(x, FixedDiv(v.width()*FU/v.dupx(), 320*FU))

	scale = ease.linear(FU/15, $, FU)

	local warp = vwarp(v, {
		transp = statealpha,
		xorigin = (v.width()*FU/v.dupx())/2,
		yorigin = (v.height()*FU/v.dupy())/2,
		xscale = scale,
		yscale = scale
	})
	draw_bg(warp)

	for i,state in ipairs(states) do
		local warp = vwarp(v, {
			transp = statealpha,
			xoffset = -x + (v.width()*FU/v.dupx())*(i-1),
			xorigin = (v.width()*FU/v.dupx())/2,
			yorigin = (v.height()*FU/v.dupy())/2,
			xscale = scale,
			yscale = scale
		})

		if i == current then
			state.think({
				buttons = buttons;
				sidemove = sidemove;
				forwardmove = forwardmove;
				lastbuttons = lastbuttons;
				lastside = lastside;
				lastforward = lastforward
			}, v.width()*FU/v.dupx(), v.height()*FU/v.dupy())
		end
		state.draw(warp, v.width()*FU/v.dupx(), v.height()*FU/v.dupy())
	end
end

local function draw_tabs(v)
	if statealpha == 10 then return end

	local alpha = statealpha*V_10TRANS

	local tab_patch = v.cachePatch"FH_INTER_TAB"
	local dist = (tab_patch.width-16)*FU

	v.drawString(0, tab_patch.height*FU, "Weapon Prev & Next", V_SNAPTOLEFT|V_SNAPTOTOP|alpha, "thin-fixed")

	for i,state in ipairs(states) do
		local x = (-16*FU)+dist*(i-1)
		v.drawScaled(x, 0, FU, tab_patch, V_SNAPTOLEFT|V_SNAPTOTOP|alpha)
		v.drawString(x+16*FU,
			4*FU,
			state.name,
			V_SNAPTOLEFT|V_SNAPTOTOP|alpha|(current == i and V_YELLOWMAP or 0),
			"thin-fixed")
	end
end

local function manage_intermission(v)
	local target_x = (320*FU)*(current-1)

	if statealpha == 10 then
		x = target_x
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
	target_x = (320*FU)*(current-1)

	x = ease.linear(FU/5, $, target_x)
end

function module.draw(renderer, v)
	if not FangsHeist.Net.game_over then return end

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