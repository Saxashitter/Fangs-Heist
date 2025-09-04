local module = {}

local sglib = FangsHeist.require "Modules/Libraries/sglib"
local fracformat = FangsHeist.require "Modules/Libraries/fracformat"

function module.init()
end

local function draw_sign(v, sign, mo, x, y)
	local alpha = 0
	local sign_spr = v.getSpritePatch(SPR_SIGN, G, 0)
	local arrow = v.cachePatch("FH_ARROW"..(leveltime/2 % 6))
	local arrow_scale = FU/2
	local dist = R_PointToDist2(mo.x, mo.y, sign.x, sign.y)

	v.drawScaled(x, y, FU/4, sign_spr, alpha)
	v.drawScaled(x - arrow.width*arrow_scale/2,
		y - 8*FU*2 - arrow.height*arrow_scale,
		arrow_scale,
		arrow,
		alpha)
	v.drawString(x, y - 8*FU*2, fracformat(dist), V_ALLOWLOWERCASE|alpha, "thin-fixed-center")
end

function module.draw(v,p,c)
	if FangsHeist.Net.pregame then return end
	local sign = FangsHeist.Net.sign

	local mo = p.realmo
	local sign = FangsHeist.Net.sign

	if not (mo and mo.valid and sign and sign.valid and not (sign.holder and sign.holder.valid)) then
		return
	end

	local track = sglib.ObjectTracking(v,p,c, sign)
	if track.onScreen
	and not P_CheckSight(mo, sign) then
		draw_sign(v, sign, mo, track.x, track.y)
	end
end

return module