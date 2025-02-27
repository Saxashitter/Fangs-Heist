local module = {}

local y
local visible
local secondRound
local staticTicker
local flash

function module.init()
	y = -FU
	visible = 0
	secondRound = false
	staticTicker = 0
	flash = 0
end

local function drawParallax(v, x, y, w, h, scale, patch, flags, ox, oy)
	local width = fixdiv(w, scale)
	local height = fixdiv(h, scale)

	local offsetX = fixdiv(ox or 0, scale)
	local offsetY = fixdiv(oy or 0, scale)

	local currentX = -offsetX
	local currentY = -offsetY

	while currentY < height do
		local sh = patch.height*FU

		if currentY+sh > height then
			sh = height - currentY
		end

		while currentX < width do
			local sw = patch.width*FU

			if currentX+sw > width then
				sw = width - currentX
			end

			v.drawCropped(
				x+FixedMul(max(0, currentX), scale),
				y+FixedMul(max(0, currentY), scale),
				scale,
				scale,
				patch,
				V_SNAPTOTOP,
				nil,
				-min(currentX, 0),
				-min(currentY, 0),
				sw + min(currentX, 0),
				sh + min(currentY, 0)
			)

			currentX = $+sw
		end

		currentY = $+sh
		currentX = -offsetX
	end
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

function module.draw(v, p)
	local monitor = v.cachePatch("FH_ROUND_MONITOR")
	local round = v.cachePatch("FH_ROUND_ROUND")
	local number = v.cachePatch("FH_ROUND2") // TODO: Add support for multiple rounds.
	local static = v.cachePatch("FH_ROUND_STATIC"..(leveltime % 3))
	local bg = v.cachePatch("FH_ROUND_BG")

	local scale = tofixed("0.7")

	if secondRound ~= p.heist.reached_second then
		secondRound = p.heist.reached_second
		visible = 3*TICRATE
		staticTicker = 15
		flash = FU
	end

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
	staticTicker = max(0, $-1)

	if visible then
		y = ease.linear(FU/7, $, 4*FU + monitor.height*scale)
	else
		y = ease.linear(FU/7, $, -FU)
	end

	if y <= 0 then return end

	local x = 160*FU - monitor.width*scale/2
	local y = y-monitor.height*scale

	// Handle Background
	local frac = FixedDiv(leveltime % 60, 60)
	drawParallax(v,
		x+5*scale,
		y+5*scale,
		monitor.width*scale-10*scale,
		monitor.height*scale-10*scale,
		scale,
		bg,
		V_SNAPTOTOP,
		FixedMul(bg.width*scale, frac),
		FixedMul(bg.height*scale, frac)
	)

	// Round ?
	v.drawScaled(
		x + monitor.width*scale/2 - round.width*scale/2,
		y + 8*scale,
		scale,
		round,
		V_SNAPTOTOP)
	v.drawScaled(
		x + monitor.width*scale/2 - number.width*scale/2,
		y + 32*scale,
		scale,
		number,
		V_SNAPTOTOP)

	// Handle Static
	if visible == 0
	or staticTicker then
		drawParallax(v,
			x+5*scale,
			y+5*scale,
			monitor.width*scale-10*scale,
			monitor.height*scale-10*scale,
			scale,
			static,
			V_SNAPTOTOP,
			0,
			0
		)
	end

	v.drawScaled(x, y, scale, monitor, V_SNAPTOTOP)
end

return module