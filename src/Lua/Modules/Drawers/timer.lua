local module = {}

local orig_net = FangsHeist.require "Modules/Variables/net"
local text = FangsHeist.require "Modules/Libraries/text"

local x
local y
local alpha

function module.init()
	y = 200*FU
	x = 160*FU
	alpha = 0
end

function module.draw(v)
	local bar = v.cachePatch"FH_BAR"
	local bar2 = v.cachePatch"FH_FULL_BAR"
	local time_scale = FixedDiv(orig_net.time_left-FangsHeist.Net.time_left, orig_net.time_left)
	local scale = FU*4/6

	local draw_x = x-(bar.width*scale/2)
	if FangsHeist.Net.escape then
		y = ease.linear(FU/3, $, 180*FU)
	end

	v.drawScaled(draw_x, y, scale, bar, V_SNAPTOBOTTOM)
	v.drawCropped(draw_x, y, scale, scale,
		bar2,
		V_SNAPTOBOTTOM,
		nil,
		0, 0, bar2.width*time_scale, bar2.height*FU)

	local time = FangsHeist.Net.time_left
	local str = string.format("%02d:%02d", G_TicsToMinutes(time), G_TicsToSeconds(time))

	text.draw(v, x, y, FixedMul(FixedDiv(21, 14), scale), str, "TMRFT", "center", V_SNAPTOBOTTOM)
end

return module