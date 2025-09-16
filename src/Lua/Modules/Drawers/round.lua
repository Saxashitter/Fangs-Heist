local module = {}

local y
local visible
local secondRound
local staticTicker
local flash
local enabled

function FangsHeist.doRound2HUD()
	secondRound = p.heist.reached_second
	visible = 3*TICRATE
	flash = FU
end

function module.init()
	enabled = false
	y = -FU
	visible = 0
	secondRound = false
	staticTicker = 0
	flash = 0
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

function module.draw(v)
	if not enabled then return end

	local round = v.cachePatch("FH_ROUND2")
	local scale = FU

	if flash then
		local f = V_10TRANS*ease.linear(flash, 10, 0)
		draw_rect(v,
			0,
			0,
			v.width()*FU/v.dupx(),
			v.height()*FU/v.dupy(),
			V_SNAPTOLEFT|V_SNAPTOTOP|f,
			SKINCOLOR_WHITE)
	end

	flash = max(0, $-(FU/20))
	visible = max(0, $-1)

	if visible then
		y = ease.linear(FU/7, $, 12*FU + round.height*scale)
	else
		y = ease.linear(FU/7, $, -FU)
		if y <= 0 then
			enabled = false
			return
		end
	end

	if y <= 0 then
		return
	end

	local x = 160*FU - round.width*scale/2
	local y = y-round.height*scale

	v.drawScaled(x, y, FU, round, V_SNAPTOTOP)
end

return module