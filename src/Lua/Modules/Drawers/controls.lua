local module = {}

function module.init() end
function module.draw(v,p)
	if not FangsHeist.isPlayerAlive(p) then return end

	local x = 4
	local y = 200-4
	local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE

	local strData = {
		{str = "[FIRE] - Attack", f = 0},
		{str = "[FIRE NORMAL] - Block", f = 0}
	}

	if p.heist.attack_cooldown then
		strData[1].str = "[FIRE] - Cooling down..."
		strData[1].f = $|V_GRAYMAP
	end
	if p.heist.attack_cooldown
	or p.heist.block_cooldown then
		strData[2].str = "[FIRE NORMAL] - Cooling down..."
		strData[2].f = $|V_GRAYMAP
	end

	if p.heist.blocking then
		table.remove(strData, 1)
	end

	y = $ - (8*#strData)

	for k,data in pairs(strData) do
		v.drawString(x, y, data.str, data.f|f, "thin")
		y = $+8
	end
end

return module