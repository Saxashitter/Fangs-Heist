local module = {}

module.weapon_info = {
	"Red Ring",
	"Rail Ring"
}

// TODO: Polish this up and allow for modding.

function module.init() end
function module.draw(v,p)
	if not FangsHeist.isPlayerAlive(p)
	or not p.heist.weapon_hud then
		return
	end

	v.fadeScreen(0xFF00, 24)
	v.drawString(160, 32, "WEAPONRY", V_SNAPTOTOP, "center")

	local scale = FU*2

	local left_x = 160*FU - 16*scale/2 - 36*scale/2
	local right_x = 160*FU - 16*scale/2 + 36*scale/2

	v.drawScaled(left_x, 100*FU - 16*scale, scale, v.cachePatch("RINGIND"))
	v.drawScaled(right_x, 100*FU - 16*scale, scale, v.cachePatch("RAILIND"))

	local sel_x = left_x
	if p.heist.weapon_selected == 2 then
		sel_x = right_x
	end

	v.drawScaled(sel_x-2*scale, 100*FU - 16*scale - 2*scale, scale, v.cachePatch("CURWEAP"))
	v.drawString(160, 200-16, module.weapon_info[p.heist.weapon_selected], V_SNAPTOBOTTOM, "center")
end

return module