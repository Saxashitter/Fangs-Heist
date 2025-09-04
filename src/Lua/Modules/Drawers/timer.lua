local module = {}

local scale = FU
local overlap = 7*FU

local enabled = false
local slideT = 0
local time = 0
local max_time = 0

function FangsHeist.disableTimer()
	enabled = false
end

function FangsHeist.isTimerEnabled()
	return enabled
end

function FangsHeist.setTimerTime(newTime, newMaxTime)
	if not enabled then
		enabled = true
	end

	time = newTime
	max_time = newMaxTime
end

local function getScaleDiv()
	if not max_time then
		return FU
	end

	return FU - FixedDiv(time, max_time)
end

local function drawTimer(v, x, y, scale, f)
	local pi = FangsHeist.getGamemode().preferredhud
	if not pi.Timer then return end
	local t = FangsHeist.Net.time_left
	local rt = FangsHeist.Net.max_time_left - FangsHeist.Net.time_left
	local tics = (t/35)/60
	local ringframe = ((((t/35) % 60) / 2)+1)

	if not FangsHeist.Net.time_left then
		ringframe = 0
	end

	local bg = v.cachePatch("FH_TMR_BG")

	v.drawScaled(x, y, FU, bg, f, v.getColormap(nil, SKINCOLOR_RED))
	if tics % 10 > 0 then
		local bar = v.cachePatch("FH_TMR_BAR" .. (tics % 10))
		v.drawScaled(x, y, FU, bar, f, v.getColormap(nil, SKINCOLOR_RED))
	end

	if ringframe then
		local ring = v.cachePatch("FH_TMR_RING" .. ringframe)
		v.drawScaled(x, y + 5*FU, FU, ring, f, v.getColormap(nil, SKINCOLOR_YELLOW))
	end

	FangsHeist.DrawString(v,
		x + bg.width*FU/2,
		y - 8 * FU,
		FU,
		"TIME",
		"FHTXT",
		"center",
		f)

	FangsHeist.DrawString(v,
		x + bg.width*FU/2,
		y + 43 * FU - 4 * FU,
		FU,
		("%d:%02d"):format(tics, (FangsHeist.Net.time_left / 35) % 60),
		"FHTXT",
		"center",
		f)
end

function module.init()
	enabled = false
	slideT = 0
	time = 0
	max_time = 0
end

function module.draw(v)
	if enabled then
		slideT = min($ + FU/35, FU)
	else
		slideT = max($ - FU/35, 0)
	end

	if slideT <= 0 then
		return
	end

	local tmr = v.cachePatch("FH_TMR_BG")

	local x = ease.outquad(slideT, -tmr.width*FU, 8*FU)
	local y = 8*FU
	local f = V_SNAPTOTOP|V_SNAPTOLEFT

	drawTimer(v, x, y + 8 * FU, FU, f)
end

return module