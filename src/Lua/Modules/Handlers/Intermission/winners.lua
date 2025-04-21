local module = {}

local text = FangsHeist.require"Modules/Libraries/text"

module.name = "Winners"

local PODIUM_Y = 200*FU - 125*FU + 10*FU
local POSITION_DATA = {
	{x = 160*FU, y = PODIUM_Y, patch = "FH_PODIUM_FIRST"},
	{x = 160*FU-100*FU, y = PODIUM_Y + 14*FU, patch = "FH_PODIUM_SECOND"},
	{x = 160*FU+100*FU, y = PODIUM_Y + (14*FU*2), patch = "FH_PODIUM_THIRD"}
}

function module.think(p) // runs when selected
end

local TRIM_LENGTH = 12
local function trim(str)
	if #str > TRIM_LENGTH then
		local trim = string.sub(str, 1, TRIM_LENGTH-3)

		trim = $.."..."

		return trim
	end

	return str
end

function module.draw(v)
	local plyrs = FangsHeist.Net.placements

	local width = v.width()*FU/v.dupx()
	local height = v.height()*FU/v.dupy()

	if not (#plyrs) then
		FangsHeist.DrawString(v,
			width/2,
			(height/2) - 8*FU,
			FU,
			"NO WINNERS!!",
			"CRFNT",
			"center",
			f,
			v.getColormap(TC_RAINBOW, p.skincolor))
		return
	end

	for i = 1,3 do
		if not (plyrs[i]) then continue end

		local team = plyrs[i]
		local p = team[1]

		if not (p and p.valid) then continue end

		local pos = POSITION_DATA[i]

		local mult = FixedDiv(width, 320*FU)
		local x = FixedMul(pos.x, mult)

		local name = trim(p.name)

		local width = (20*FU) * (#team-1)

		local length = #team-1
		local div = length and width/length or width/2

		local podium = v.cachePatch(pos.patch)
		local xscale = FU + FixedDiv(#team-1, 2)

		v.drawStretched(x - podium.width*xscale/2,
			height - podium.height*FU,
			xscale,
			FU,
			podium,
			V_SNAPTOTOP|V_SNAPTOLEFT)

		for i,sp in ipairs(team) do
			if not FangsHeist.isPlayerAlive(sp) then continue end

			local color = v.getColormap(sp.skin, sp.skincolor, ((sp.mo and sp.mo.valid) and sp.mo.translation or nil))
			local scale = skins[sp.skin].highresscale
			local stnd = v.getSprite2Patch(sp.skin, SPR2_STND, false, A, 1)
			local dx = x - width/2 + div*(i-1)
			if not length then
				dx = x
			end

			--[[if length % 2 == 1 then
				dx = x - width + sep*i
			end]]

			v.drawScaled(dx, pos.y, scale*6/8, stnd, V_SNAPTOBOTTOM|V_SNAPTOLEFT, color)
		end

		local y = pos.y+12*FU
		local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT
		// 21*FU

		if #team > 1 then
			FangsHeist.DrawString(v,
				x,
				y,
				FU/2,
				"TEAM",
				"CRFNT",
				"center",
				f,
				v.getColormap(TC_RAINBOW, p.skincolor))
			y = $+16*FU/2
		end

		FangsHeist.DrawString(v,
			x,
			y,
			FU/2,
			name:upper(),
			"CRFNT",
			"center",
			f,
			v.getColormap(TC_RAINBOW, p.skincolor))
		y = $+18*(FU/2)

		local width = FangsHeist.getProfitWidth(v, team.profit, FU, 60*FU)

		FangsHeist.drawProfit(v, x-width/2, y, FU, team.profit, f, 60*FU)
	end
end

return module