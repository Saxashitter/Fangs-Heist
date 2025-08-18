local module = {}

local elapsed = 0
local maxtime = TICRATE+13
local offsettime = TICRATE
local endtime = 24
local delay = 10
local offset = 12

local function DrawFlash(v, percent)
	local patch = v.cachePatch("FH_PINK_SCROLL")
	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	local alpha = V_10TRANS*ease.linear(percent, 10, 0)
	if alpha > V_90TRANS then return end

	v.drawStretched(
		0, 0,
		FixedDiv(sw, patch.width*FU),
		FixedDiv(sh, patch.height*FU),
		patch,
		alpha|V_SNAPTOTOP|V_SNAPTOLEFT,
		v.getColormap(TC_BLINK, SKINCOLOR_WHITE)
	)
end

local function gravityTypeEase(t, start, finish, param)
	local tweenStuff = FU/3
	if t < tweenStuff then
		return ease.outcubic(FixedDiv(t, tweenStuff), start, start-param)
	end

	local t = FixedDiv(t-tweenStuff, FU-tweenStuff)

	return ease.incubic(t, start-param, finish)
end

function module.init()
	elapsed = 0
end

function module.draw(v)
	if not FangsHeist.Net.escape then
		return
	end

	elapsed = min(maxtime+offsettime+endtime+delay, $+1)

	if elapsed >= maxtime+offsettime+endtime+delay then
		return
	end

	DrawFlash(v, FU - FixedDiv(min(elapsed, 10), 10))

	local go = v.cachePatch("FH_GOGOGO")
	local scale = FU

	local start = -go.height*scale
	local mid = ((v.height()*FU/v.dupy())/2) - go.height*scale/2
	local endpos = v.height()*FU/v.dupy()
	local offsetwidth = 4*scale
	local width = go.width*scale+offsetwidth

	for i = 1,3 do
		local time = max(0, elapsed-delay-(offset*(i-1)))

		local x = 160*FU - go.width*scale/2 - width*2 + width*i
		local y = start

		if elapsed > maxtime+offsettime+delay then
			local t = FixedDiv(elapsed - (maxtime+offsettime+delay), endtime)
			local tx = 30*FU

			x = ease.linear(t, $, $+tx*(i-2))
			y = gravityTypeEase(t, mid, endpos, FU*12)
		else
			local div = min(FixedDiv(time, maxtime), FU)
	
			y = ease.outback(div, $, mid, FU*2)
		end

		for i = 1,2 do
			local x = x+v.RandomRange(-5*scale, 5*scale)
			local y = y+v.RandomRange(-5*scale, 5*scale)

			v.drawScaled(x, y, scale, go, V_SNAPTOTOP|V_70TRANS)
		end
		v.drawScaled(x, y, scale, go, V_SNAPTOTOP)
	end
end

return module