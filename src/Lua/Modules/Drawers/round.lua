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

local function drawRoundFlag(v, x, y, scale, flags)
	local round = v.cachePatch("FH_ROUND2")
	local fill = v.cachePatch("FH_ROUNDFILL")

	local offset = FixedMul(8*scale, FixedDiv(leveltime % (2*TICRATE), 2*TICRATE))

	FangsHeist.DrawParallax(v,
		x+scale,
		y+scale,
		round.width*scale - (scale*2),
		round.height*scale - (scale*2),
		scale,
		fill,
		flags,
		offset,
		offset)
	v.drawScaled(x, y, scale, round, flags)
end

function module.draw(v)
	local p = consoleplayer

	if not (p and p.valid and p.heist) then
		return
	end

	local round = v.cachePatch("FH_ROUND2")
	local scale = FU

	if secondRound ~= p.heist.reached_second then
		secondRound = p.heist.reached_second
		visible = 3*TICRATE
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

	if visible then
		y = ease.linear(FU/7, $, 4*FU + round.height*scale)
	else
		y = ease.linear(FU/7, $, -FU)
	end

	if y <= 0 then return end

	local x = 160*FU - round.width*scale/2
	local y = y-round.height*scale

	drawRoundFlag(v, x, y, scale, V_SNAPTOTOP)
end

return module