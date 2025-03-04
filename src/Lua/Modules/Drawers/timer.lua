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

	local bar = v.cachePatch"FH_BAR"
	local bar2 = v.cachePatch"FH_FULL_BAR"
	local time_scale = FixedDiv(FangsHeist.Net.max_time_left-FangsHeist.Net.time_left, FangsHeist.Net.max_time_left)
	local scale = FU*4/6

	local draw_x = x-(bar.width*scale/2)

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

	v.drawScaled(draw_x, y+10*FU, scale, bar, V_SNAPTOBOTTOM)
	v.drawCropped(draw_x, y+10*FU, scale, scale,
		bar2,
		V_SNAPTOBOTTOM,
		nil,
		0, 0, bar2.width*time_scale, bar2.height*FU)

	local time = FangsHeist.Net.time_left
	local str = string.format("%02d:%02d", G_TicsToMinutes(time), G_TicsToSeconds(time))

	text.draw(v, x, y+10*FU, FixedMul(FixedDiv(21, 14), scale), str, "TMRFT", "center", V_SNAPTOBOTTOM)
	drawSecLeft(v, sl_y)
end

return module