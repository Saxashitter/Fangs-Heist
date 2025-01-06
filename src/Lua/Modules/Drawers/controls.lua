local module = {}

function module.init() end
function module.draw(v,p)
	if not FangsHeist.isPlayerAlive(p) then return end

	local x = 4
	local y = 200-12
	local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE

	local str = "[FIRE] - Attack"

	if p.heist.attack_cooldown then
		str = "[FIRE] - Cooling down..."
		f = $|V_GRAYMAP
	end

	v.drawString(x, y, str, f, "thin")
end

return module