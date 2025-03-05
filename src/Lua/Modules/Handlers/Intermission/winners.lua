local module = {}

local text = FangsHeist.require"Modules/Libraries/text"

module.name = "Winners"

local POSITION_DATA = {
	{x = 160*FU, y = 110*FU, patch = "FH_PODIUM_FIRST"},
	{x = 160*FU-100*FU, y = 120*FU, patch = "FH_PODIUM_SECOND"},
	{x = 160*FU+100*FU, y = 130*FU, patch = "FH_PODIUM_THIRD"}
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
		customhud.CustomFontString(v,
			width/2,
			height/2 - 16*FU/2,
			"No winners!",
			"FHFNT",
			V_SNAPTOLEFT|V_SNAPTOTOP,
			"center",
			FU,
			SKINCOLOR_CYAN
		)
		return
	end

	for i = 1,3 do
		if not (plyrs[i]) then continue end

		local team = plyrs[i]
		local p = team[1]
		local pos = POSITION_DATA[i]

		local podium = v.cachePatch(pos.patch)

		local mult = FixedDiv(width, 320*FU)
		local x = FixedMul(pos.x, mult)

		local name = trim(p.name)

		local width = (20*FU) * (#team-1)

		local length = #team-1
		local div = length and width/length or width/2

		local podium_scale = FU
		local podium_wscale = podium_scale + FU*(length-1)/8
		v.drawScaled(x-podium.width*podium_wscale/2, 200*FU-podium.height*podium_scale, podium_wscale, podium, V_SNAPTOBOTTOM|V_SNAPTOLEFT)

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

		if length > 1 then
			customhud.CustomFontString(v,
				x, y,
				"Team",
				"FHFNT",
				V_SNAPTOLEFT|V_SNAPTOTOP,
				"center",
				FU*6/9,
				p.skincolor
			)
			y = $+18*(FU*6/9)
		end

		customhud.CustomFontString(v,
			x, y,
			name,
			"FHFNT",
			f,
			"center",
			FU*6/9,
			p.skincolor
		)
		y = $+18*(FU*6/9)

		local scale = (FU/3)*2
		local patch = v.cachePatch("FH_PROFIT")

		v.drawScaled(x-patch.width*scale/2, y, scale, patch, f)
		local width = customhud.CustomNumWidth(v,
			team.profit,
			"PROFNT",
			0,
			scale)
		local sign = v.cachePatch("PROFNTSIGN")
	
		v.drawScaled(
			x - sign.width*scale - width/2,
			y + 15*scale,
			scale,
			sign,
			f
		)
		customhud.CustomNum(v,
			x,
			y + 16*scale,
			team.profit,
			"PROFNT",
			0,
			f,
			"center",
			scale)
	
			--v.drawString(x, y, "$"..tostring(FangsHeist.returnProfit(p)), V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_GREENMAP, "thin-fixed-center")
	end
end

return module