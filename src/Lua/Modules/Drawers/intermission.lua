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

local states = {
	FangsHeist.require"Modules/Handlers/Intermission/personalstats",
	FangsHeist.require"Modules/Handlers/Intermission/winners",
	FangsHeist.require"Modules/Handlers/Intermission/vote"
}

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
	local scroll = (leveltime % bg.width*16)*FU/16
	local scale = FU*2
	local transp = V_10TRANS*statealpha

	local x = FixedMul(-scroll, scale)
	local y = FixedMul(-scroll, scale)

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

	for i,state in ipairs(states) do
		local warp = vwarp(v, {
			transp = statealpha,
			xoffset = -x + (v.width()*FU/v.dupx())*(i-1)
		})

		if (i-1) == current then
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

local function manage_intermission(v)
	local target_x = (v.width()*FU/v.dupx())*(current-1)

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
	target_x = (v.width()*FU/v.dupx())*(current-1)

	x = ease.linear(FU/5, $, target_x)
end

function module.draw(renderer, v)
	if not FangsHeist.Net.game_over then return end

	alpha = min($+1, 10)
	if alpha == 10 then
		statealpha = max(0, $-1)
	end

	manage_fade_screen(v)
	manage_intermission(v)
	draw_bg(v)
	draw_intermission(v)
end

return module,"gameandscores"