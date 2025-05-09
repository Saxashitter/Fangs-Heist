local module = {}

local sglib = FangsHeist.require "Modules/Libraries/sglib"
local fracformat = FangsHeist.require "Modules/Libraries/fracformat"

local function draw_player(v, p, tp, mo, x, y)
	local arrow = v.cachePatch("FH_ARROW"..(leveltime/2 % 6))
	local arrow_scale = FU/2
	local dist = R_PointToDist2(mo.x, mo.y, p.mo.x, p.mo.y)

	local plyr_spr, plyr_scale
	if skins[p.mo.skin].sprites[SPR2_SIGN].numframes then
		plyr_spr = v.getSprite2Patch(p.mo.skin, SPR2_SIGN, false, A, 0)
		plyr_scale = skins[p.mo.skin].highresscale
	else
		plyr_spr = v.getSpritePatch(SPR_SIGN, S, 0)
		plyr_scale = FU
	end
	local color = v.getColormap(p.mo.skin, p.mo.color)

	v.drawScaled(x, y, plyr_scale/4, plyr_spr, 0, color)
	y = $-8*FU*2

	if #p.heist.treasures then
		v.drawString(x, y, "TREASURE", 0, "thin-fixed-center")
		y = $-8*FU
	end
	if FangsHeist.playerHasSign(p) then
		v.drawString(x, y, "SIGN", 0, "thin-fixed-center")
		y = $-8*FU
	end
	if FangsHeist.isPartOfTeam(tp, p) then
		v.drawString(x, y, "TEAM", 0, "thin-fixed-center")
		y = $-8*FU
	end

	v.drawString(x, y, fracformat(dist), V_ALLOWLOWERCASE, "thin-fixed-center")
	y = $-arrow.height*arrow_scale

	v.drawScaled(x - arrow.width*arrow_scale/2,
		y,
		arrow_scale,
		arrow,
		0,
		v.getColormap(nil, p.mo.color))
end

local function isSpecial(p, sp)
	return #sp.heist.treasures
	or FangsHeist.playerHasSign(sp)
	or (p and p.heist and FangsHeist.isPartOfTeam(p, sp))
end

function module.init() end
function module.draw(v,p,c)
	if FangsHeist.Net.pregame then return end
	if not (p and p.mo and p.mo.valid) then return end

	for sp in players.iterate do
		if not FangsHeist.isPlayerAlive(sp) then continue end
		if not isSpecial(p, sp) then continue end

		if p == sp then continue end
		if P_CheckSight(p.mo, sp.mo) then continue end
		if sp.heist.exiting then continue end

		local result = sglib.ObjectTracking(v,p,c,sp.mo)
		if not result.onScreen then continue end

		draw_player(v, sp, p, p.mo, result.x, result.y)
	end
end

return module