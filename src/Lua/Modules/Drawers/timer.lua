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

local CROPSETS = {
	[0] = 5,
	[1] = 6,
	[2] = 7,
	[3] = 8,
	[4] = 9
}

local function drawTimer(v, x, y, scale, f)
	local tmr = v.cachePatch("FH_TMR")
	local backfill = v.cachePatch("FH_TMR_FILL")
	local fill = v.cachePatch("FH_TMR_ENDFILL")

	local div = getScaleDiv()
	local rdiv = FU-div

	local barx = x + 5*scale
	local bary = y + 17*scale
	local barw = tmr.width*scale - 6*scale - 5*scale

	-- background fill
	FangsHeist.DrawParallax(v,
		barx,
		bary,
		barw,
		backfill.height*scale + (scale*2), -- to make sure theres no clipping
		scale,
		backfill,
		f
	)
	-- main fill
	FangsHeist.DrawParallax(v,
		barx,
		bary,
		FixedMul(barw, div),
		fill.height*scale + (scale*2), -- to make sure theres no clipping
		scale,
		fill,
		f
	)
	-- actual timer sprite
	v.drawScaled(x, y, scale, tmr, f)

	-- text
	local minstr = string.format("%02d",
		time/(TICRATE*60))
	local secstr = string.format("%02d",
		(time/TICRATE) % 60)

	local patches = {}
	local width = 0
	local pad = 0

	for i = 1,#minstr do
		local num = minstr:sub(i,i)
		local patch = v.cachePatch("STTNUM"..num)

		table.insert(patches, patch)
		width = $ + patch.width*scale + pad
	end

	local colon = v.cachePatch("STTCOLON")

	table.insert(patches, colon)
	width = $ + colon.width*scale + pad

	for i = 1,#secstr do
		local num = secstr:sub(i,i)
		local patch = v.cachePatch("STTNUM"..num)

		table.insert(patches, patch)
		width = $ + patch.width*scale

		if i < #secstr then
			width = $+pad
		end
	end

	x = $ + (tmr.width*scale/2) - width/2
	local dx = 0

	for i,patch in ipairs(patches) do
		v.drawScaled(x+dx, y+17*scale, scale, patch, f)

		if i < #patches then
			dx = $ + patch.width*scale + pad
		end
	end
end

local function drawTmrText(v, x, y, scale, flags)
	local tbg = v.cachePatch("FH_TMR_TEXTBG")

	v.drawScaled(x, y, scale, tbg, flags)

	local secstr = string.format("%02d",
		(time/TICRATE) % 60)
	local minstr = string.format("%02d",
		time/(TICRATE*60))

	local padding = scale*2
	local patches = {}

	x = $+14*scale
	y = $-4*scale

	for i = 1,#minstr do
		local num = minstr:sub(i,i)
		table.insert(patches, v.cachePatch("FH_TMR_NUM"..num))
	end

	table.insert(patches, v.cachePatch("FH_TMR_SC"))

	for i = 1,#secstr do
		local num = secstr:sub(i,i)
		table.insert(patches, v.cachePatch("FH_TMR_NUM"..num))
	end

	x = $+tbg.width*scale/2

	local width = 0
	local maxHeight = 0
	for i,patch in ipairs(patches) do
		width = $+patch.width*scale
		maxHeight = max($, patch.height*scale)
		if i < #patches then
			width = $+padding
		end
	end

	local dx = -width/2
	for i,patch in ipairs(patches) do
		v.drawScaled(x+dx,
			y+(maxHeight-patch.height*scale)/2,
			scale,
			patch,
			flags)

		dx = $+patch.width*scale
		if i < #patches then
			dx = $+padding
		end
	end
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

	local tmr = v.cachePatch("FH_TMR")

	local x = 160*FU - tmr.width*FU/2
	local y = ease.outback(slideT, 200*FU, 200*FU - 8*FU - tmr.height*FU)
	local f = V_SNAPTOBOTTOM

	drawTimer(v, x, y, FU, f)
end

return module