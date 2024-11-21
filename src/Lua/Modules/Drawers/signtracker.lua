local module = {}

local sglib = FangsHeist.require "Modules/Libraries/sglib"
local alpha = 10

function module.init()
	alpha = 10
end

local function draw_sign(v, sign, mo, x, y)
	if alpha == 10 then return end

	local alpha = V_10TRANS*alpha
	local sign_spr = v.getSpritePatch(SPR_SIGN, G, 0)
	local arrow = v.cachePatch("FH_ARROW"..(leveltime/2 % 6))
	local arrow_scale = FU/2
	local dist = R_PointToDist2(mo.x, mo.y, sign.x, sign.y)

	local holder = sign.holder

	if holder then
		local plyr_spr = v.getSprite2Patch(sign.holder.skin, SPR2_SIGN, false, A, 0)
		local color = v.getColormap(sign.holder.skin, sign.holder.color)

		v.drawScaled(x, y, FU/4, plyr_spr, V_SNAPTOLEFT|V_SNAPTOTOP|alpha, color)
		v.drawScaled(x, y - 3*FU, FU/4, sign_spr, V_SNAPTOLEFT|V_SNAPTOTOP|alpha)
		v.drawString(x, y - 3*FU - 8*FU*2, tostring(dist/FU).." FU", V_SNAPTOLEFT|V_SNAPTOTOP|alpha, "thin-fixed-center")
		v.drawScaled(x - arrow.width*arrow_scale/2,
			y - 3*FU - 8*FU*2 - arrow.height*arrow_scale,
			arrow_scale,
			arrow,
			V_SNAPTOLEFT|V_SNAPTOTOP,
			v.getColormap(nil, sign.holder.color))
		return
	end

	v.drawScaled(x, y, FU/4, sign_spr, V_SNAPTOLEFT|V_SNAPTOTOP|alpha)
	v.drawString(x, y - 8*FU*2, tostring(dist/FU).." FU", V_SNAPTOLEFT|V_SNAPTOTOP|alpha, "thin-fixed-center")
	v.drawScaled(x - arrow.width*arrow_scale/2,
		y - 8*FU*2 - arrow.height*arrow_scale,
		arrow_scale,
		arrow,
		V_SNAPTOLEFT|V_SNAPTOTOP)
end

function module.draw(v,p,c)
	local sign = FangsHeist.Net.sign

	local mo = p.realmo
	local sign = FangsHeist.Net.sign

	if not (mo and mo.valid and sign and sign.valid) then
		alpha = 10
		return
	end

	if P_CheckSight(mo, sign) then
		alpha = min($+1, 10)
	else
		alpha = max(0, $-1)
	end

	local track = sglib.ObjectTracking(v,p,c, sign)
	if track.onScreen then
		draw_sign(v, sign, mo, track.x, track.y)
	end
end

return module