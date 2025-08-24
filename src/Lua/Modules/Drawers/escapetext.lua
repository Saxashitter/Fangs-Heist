local module = {}

local duration = 90
local elapsed = 0
local enabled = false

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

local function DrawText(v, x, y, string, flags, align, color, rich)
	FangsHeist.DrawString(v,
		x,
		y,
		FU,
		string,
		"FHTXT",
		align,
		flags,
		color,
		rich)
end

function FangsHeist.doGoHUD(newDuration)
	enabled = true
	elapsed = 0
	duration = newDuration or $
end

function module.init()
	enabled = false
	elapsed = 0
	duration = 90
end

function module.draw(v)
	if not enabled then
		return
	end

	if elapsed > duration then return end

	if (elapsed/3) % 2 then
		local height = 16*FU
		local y = 100*FU - height/2
		local c = v.getStringColormap(V_REDMAP)

		DrawText(v, 160*FU, y, "ESCAPE START", 0, "center", c)
		DrawText(v, 160*FU, y+9*FU, "GO! GO! GO!", 0, "center", c)
	end

	elapsed = $+1
end

return module