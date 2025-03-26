local module = {}

function FangsHeist.drawRings(v, x, y, scale, profit, flags)
	local patch = v.cachePatch("STTRINGS")

	v.drawScaled(x, y, scale, patch, flags)

	FangsHeist.DrawNumber(v, x+80*scale, y, scale, profit, "STTNUM", flags)
end

function module.draw(v, p)
	FangsHeist.drawRings(v, 12*FU, 12*FU+(14*FU), FU, p.rings, V_SNAPTOLEFT|V_SNAPTOTOP)
end

return module