local module = {}

local x = 8*FU
local y = 60*FU
local f = V_SNAPTOLEFT|V_SNAPTOTOP

local fillx = 3*FU
local filly = 3*FU

function module.init() end
function module.draw(v,p)
	local gamemode = FangsHeist.getGamemode()

	if gamemode.index ~= FangsHeist.TagTeam then return end

	local bar = v.cachePatch("FH_HEALTHBAR")
	local underlay = v.cachePatch("FH_HEALTHBAR_UNDERLAY")
	local overlay = v.cachePatch("FH_HEALTHBAR_OVERLAY")

	v.drawScaled(x, y, FU, bar, f)
	v.drawScaled(x+fillx, y+filly, FU, underlay, f)

	local frac = FixedDiv(p.heist.health, p.heist.maxhealth)

	v.drawCropped(x+fillx,
		y+filly,
		FU,
		FU,
		overlay,
		f,
		nil,
		0,
		0,
		overlay.width*frac,
		overlay.height*FU)

	local str = ("%d / %d"):format(p.heist.health, p.heist.maxhealth)

	v.drawString(
		x+(bar.width*FU/2),
		y+(bar.height*FU/2)-(7*FU/2),
		str,
		f,
		"thin-fixed-center")
end

return module