local module = {}

local orig_net = FangsHeist.require "Modules/Variables/net"
local text = FangsHeist.require "Modules/Libraries/text"

local APPEARANCE_TIME = 3*TICRATE

local x
local y
local sl_y
local timesuptics
local alpha
local ticker
local took
local warning_active

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

local function drawBar(v)
	local bar = v.cachePatch"FH_BAR"
	local bg = v.cachePatch"FH_BARBG"

	local scale = tofixed("0.75")

	local time = FangsHeist.Net.max_time_left
	local current = time-FangsHeist.Net.time_left

	local hscale = scale + (FU/50)
	local x = 160*FU - bar.width*scale/2

	local fill = v.cachePatch"FH_BLUEFILL"
	local outfill = v.cachePatch"FH_REDFILL"
	local fillend = v.cachePatch("FH_FILLEND"..(leveltime % 3))

	local speed = 35
	local fillscale = tofixed("0.5")

	v.drawStretched(x+6*scale, y+10*FU+4*scale, hscale, scale, bg, V_SNAPTOBOTTOM)
	drawParallax(v,
		x + 6*scale,
		(y+10*FU) + 5*scale + 8*scale,
		FixedMul(bar.width*scale - 6*scale, FixedDiv(current, time)),
		fill.height*fillscale,
		fillscale,
		fill,
		V_SNAPTOBOTTOM,
		FixedMul(fill.width*fillscale, FixedDiv(leveltime % speed, speed)))
	v.drawScaled(x, y+10*FU, scale, bar, V_SNAPTOBOTTOM)
end

local function drawSecLeft(v, y)
	local tics = FangsHeist.Net.time_left
	local seconds = (tics/TICRATE) % 60
	local minutes = (tics/TICRATE) / 60

	local minStr = string.format("%02d", minutes)
	local secStr = string.format("%02d", seconds)

	local scale = FU

	local secondsLeft = v.cachePatch"FH_SECONDSLEFT"
	local split = v.cachePatch"FH_SECONDSLEFTSPLIT"

	v.drawScaled(
		160*FU - secondsLeft.width*scale/2,
		y+9*scale+4*scale,
		scale,
		secondsLeft,
		V_SNAPTOBOTTOM)

	local width = ((9*scale)*4) + (4*scale)

	for i = 1,#minStr do
		local str = string.sub(minStr, i, i)
		local patch = v.cachePatch("FH_SECONDSLEFT"..str)
		local x = 160*FU - width/2 + (9*scale)*(i-1)

		v.drawScaled(x, y, scale, patch, V_SNAPTOBOTTOM)
	end

	v.drawScaled(160*FU - split.width*scale/2, y, scale, split, V_SNAPTOBOTTOM)

	for i = 1,#secStr do
		local str = string.sub(secStr, i, i)
		local patch = v.cachePatch("FH_SECONDSLEFT"..str)
		local x = 160*FU + (split.width*scale/2) + scale + (9*scale)*(i-1)

		v.drawScaled(x, y, scale, patch, V_SNAPTOBOTTOM)
	end
end

function FangsHeist.doSignpostWarning(_took)
	took = (_took)
	ticker = 0
	alpha = 10
	warning_active = true
end

function module.init()
	y = 400*FU
	x = 160*FU
	alpha = 0
	ticker = 0
	took = false
	sl_y = 200*FU
	timesuptics = TICRATE*2
	warning_active = false
end

function module.draw(v,p)
	local data = FangsHeist.getTypeData()

	if warning_active then
		ticker = $+1

		if ticker < APPEARANCE_TIME then
			alpha = max(0, $-1)
		else
			alpha = min($+1, 10)
			if alpha == 10 then
				warning_active = false
			end
		end

		local warning
		if not took then
			warning = v.cachePatch("FH_SIGNPOST_TAKEN")
		else
			warning = v.cachePatch("FH_TOOK_SIGNPOST")
		end

		local scale = FU/2

		if alpha ~= 10 then
			v.drawScaled(x-(warning.width*scale/2),
				y-2*FU-warning.height*scale,
				scale,
				warning,
				V_SNAPTOBOTTOM|(V_10TRANS*alpha))
		end
	end

	if (FangsHeist.Net.escape
	and not FangsHeist.isHurryUp()) then
		if FangsHeist.Net.time_left > 10*TICRATE then
			sl_y = v.height()*FU/v.dupy()
			y = ease.linear(FU/6, $, 170*FU)
		else
			if timesuptics then
				sl_y = ease.linear(FU/6, $, ((v.height()*FU/v.dupy())/2) - (24*FU + 9*FU)/2)

				if not FangsHeist.Net.time_left then
					timesuptics = $-1
				end
			else
				sl_y = ease.linear(FU/6, $, v.height()*FU/v.dupy()+FU)
			end
			y = ease.linear(FU/6, $, 205*FU)
		end
	else
		sl_y = v.height()*FU/v.dupy()
	end

	drawBar(v)
	drawSecLeft(v, sl_y)
end

return module