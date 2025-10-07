local module = {}
local text = FangsHeist.require"Modules/Libraries/text"

local pos
local seconds

local alpha1
local alpha2
local alpha3

local function approach(v, v2, by)
	if v < v2 then
		return min(v+by, v2)
	end

	return max(v2, v-by)
end

function module.init()
	pos = FU
	seconds = 1

	alpha1 = 10
	alpha2 = 10
	alpha3 = 0
end

function module.draw(v,p)
	/*if p.spectator then return end

	local meter = v.cachePatch"FH_CONSCIOUS_METER"
	local fill1 = v.cachePatch"FH_CONSCIOUS_FILL1"
	local fill2 = v.cachePatch"FH_CONSCIOUS_FILL2"
	local fill3 = v.cachePatch"FH_CONSCIOUS_FILL3"

	pos = approach($, p.heist.conscious_meter, FU/35)

	local percent = pos/(FU/100)

	// there is a better way to do this but idc to think rn
	if percent >= 75 then
		alpha1 = approach($, 10, 1)
		alpha2 = approach($, 10, 1)
		alpha3 = approach($, 0, 1)
	elseif percent >= 50 then
		alpha1 = approach($, 10, 1)
		alpha2 = approach($, 0, 1)
		alpha3 = approach($, 10, 1)
	else
		alpha1 = approach($, 0, 1)
		alpha2 = approach($, 10, 1)
		alpha3 = approach($, 10, 1)
	end

	local x = 16*FU
	local y = 200*FU - 16*FU*3
	local s = FU*6/8
	local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT

	text.draw(v, x+10*FU,
		y-12*FU,
		FU*6/8,
		"CONSCIOUS",
		"FHFNT",
		"left",
		f,
		v.getColormap(nil, SKINCOLOR_RED))

	v.drawScaled(x, y, s, meter, f)
	if alpha1 < 10 then
		v.drawCropped(x, y, s, s, fill1, f|(alpha1*V_10TRANS), nil,
			0, 0, fill1.width*pos, fill1.height*FU)
	end
	if alpha2 < 10 then
		v.drawCropped(x, y, s, s, fill2, f|(alpha2*V_10TRANS), nil,
			0, 0, fill2.width*pos, fill2.height*FU)
	end
	if alpha3 < 10 then
		v.drawCropped(x, y, s, s, fill3, f|(alpha3*V_10TRANS), nil,
			0, 0, fill3.width*pos, fill3.height*FU)
	end

	if not (p.heist.conscious_meter) then
		v.drawString(160, 100-30, "SPAM JUMP!", 0, "center")
		v.drawString(160, 100-20, "GET UP!", 0, "center")
		v.drawString(160-2, 100-10, p.heist.conscious_meter_heal/TICRATE, V_YELLOWMAP, "center")
	end*/
end

return module