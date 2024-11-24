local module = {}

local pos

function module.init()
	pos = FU
end

function module.draw(v,p)
	if p.spectator then return end

	local meter = v.cachePatch"FH_CONSCIOUS_METER"
	local fill = v.cachePatch"FH_CONSCIOUS_FILL"

	local fill_pos = p.heist.conscious_meter

	local x = 16*FU
	local y = 200*FU - 16*FU*3
	local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT

	v.drawScaled(x, y, FU, meter, f)
	v.drawCropped(x, y, FU, FU, fill, f, nil,
		0, 0, fill.width*fill_pos, fill.height*FU)

	if not (p.heist.conscious_meter) then
		v.drawString(160, 100-30, "SPAM JUMP!", 0, "center")
		v.drawString(160, 100-20, "GET UP!", 0, "center")
		v.drawString(160-2, 100-10, p.heist.conscious_meter_heal/TICRATE, V_YELLOWMAP, "center")
	end
end

return module