local module = {}

local alpha

function module.init(v)
	alpha = 10
end

function module.draw(v, p)
	if FangsHeist.isPlayerAlive(p)
	and FangsHeist.isPlayerAtGate(p)
	and FangsHeist.Net.escape
	and not p.heist.exiting then 
		alpha = max(0, $-1)
	else
		alpha = min($+1, 10)
	end

	if alpha == 10 then return end

	local flags = V_SNAPTOBOTTOM|(V_10TRANS*alpha)

	v.drawString(160, 180, "PRESS FIRE TO EXIT", flags, "center")
end

return module