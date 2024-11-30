local module = {}

local ringsling = FangsHeist.require"Modules/Handlers/ringsling"

function module.init() end
function module.draw(v,p)
	if not (p.heist.weapon) then return end
	local data = ringsling.rings[p.heist.weapon]

	local y = 200*FU-32*FU

	local ty = y-ease.linear(FixedDiv(p.heist.weapon_cooldown, data.cooldown), 0, 8*FU)

	v.drawScaled(16*FU, y, FU, v.cachePatch(data.graphic), V_SNAPTOBOTTOM|V_SNAPTOLEFT)
	v.drawScaled(16*FU-2*FU, ty-2*FU, FU, v.cachePatch("CURWEAP"), V_SNAPTOBOTTOM|V_SNAPTOLEFT)
end

return module