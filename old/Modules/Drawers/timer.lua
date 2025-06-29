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
	local bg = v.cachePatch("FH_TMR_BG")
	local fill = v.cachePatch("FH_TMR_FILL")
	local gem = v.cachePatch("FH_TMR_GEM")

	local div = FU-getScaleDiv()

	local color

	if displayplayer
	and displayplayer.valid then
		color = v.getColormap(nil, displayplayer.skincolor)
	end

	-- background fill
	v.drawScaled(x, y, scale, bg, f)

	-- main fill
	local barx = x + 3*scale
	local bary = y + 3*scale
	local barw = tmr.width*scale - 6*scale
	local barh = tmr.height*scale - 6*scale
	local width = FixedMul(barw, div)

	FangsHeist.DrawParallax(v,
		barx+width,
		bary,
		barw-width,
		barh,
		scale,
		fill,
		f
	)

	-- actual timer sprite
	v.drawScaled(x, y, scale, tmr, f)

	-- gem
	local start = x
	local finish = x + tmr.width*scale - gem.width*scale
	local twn = ease.linear(div, start, finish)
	v.drawScaled(twn, y + tmr.height*scale/2 - gem.height*scale/2, scale, gem, f, color)

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
		local patch = v.cachePatch("FH_TMR"..num)

		table.insert(patches, patch)
		width = $ + patch.width*scale + pad
	end

	local colon = v.cachePatch("FH_TMR_COLON")

	table.insert(patches, colon)
	width = $ + colon.width*scale + pad

	for i = 1,#secstr do
		local num = secstr:sub(i,i)
		local patch = v.cachePatch("FH_TMR"..num)

		table.insert(patches, patch)
		width = $ + patch.width*scale

		if i < #secstr then
			width = $+pad
		end
	end

	x = twn + gem.width*scale/2 - width/2
	local dx = 0

	for i,patch in ipairs(patches) do
		v.drawScaled(x+dx, y + tmr.height*scale/2 - patch.height*scale/2, scale, patch, f)

		if i < #patches then
			dx = $ + patch.width*scale + pad
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

	local x = 320*FU - 12*FU - tmr.width*FU
	local y = ease.outback(slideT, 200*FU, 200*FU - 12*FU - tmr.height*FU)
	local f = V_SNAPTOBOTTOM|V_SNAPTORIGHT

	drawTimer(v, x, y, FU, f)
end

return module